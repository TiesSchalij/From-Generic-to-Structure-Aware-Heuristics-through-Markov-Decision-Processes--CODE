function [BPCounter, BPTime, subTime, nPatternsGenerated, time] = columnGenerationSolver(n, C, w, solver, piPrimeData, verbose, nonExact, mipGap)
% columnGenerationSolver takes a BPP instance and solves the relaxation of the Gilmore and Gomory formulation (1961)
% The column generation method is implemented according to Bertsimas and Tsitsiklis page 97.
% Input:
    % n             - the number of items
    % C             - the capacity of each bin
    % w             - the weight of each item (n x 1)
    % solver        - what solver to use for the subproblem: 'greedy, exact, piPrime'
    % piPrimeData   - where to find piPrime
    % verbose       - print output
    % nonExact      - if the exact solver can terminate early
    % mipGap        - at what optimality gap the exact solver can terminate early
% 
% Output:
    % BPCounter             - how often a column is generated via Binary Programming
    % BPTime                - how much time is spent in Binary Programming
    % subTime               - how much time is spent in the heuristic
    % nPatternsGenerated    - how many columns are generated total
    % time                  - total time spent solving the relaxation

arguments
    n                   %number of items
    C                   %max capacity
    w                   %weights of items
    solver              %what solver to use for subproblem: 'greedy, exact, piPrime'
    piPrimeData = []    %where to find piPrime
    verbose     = 0     %if you want the print output
    nonExact    = 0     %if the exact solver should terminate early
    mipGap      = []
end
tic
gurobiEpsiolon = 0.001; %to deal with roundoff errors in the heuristic
B = eye(n);
Binv = eye(n);
x = ones(n,1);
subCounter          = 0;
subTime             = 0;
BPCounter           = 0;
BPTime              = 0;
nPatternsGenerated  = 0;
thetaSum            = 0;
%% 2: Find new basic variable
newBasicVariableFound = 1;
while newBasicVariableFound
    p = ones(1,n)*Binv;
    scaleFactor = max(p); %instances are rescaled such that max value is 1
    s = instance('v',p,'w',w./C);
    newBasicVariableFound = 0;
    subStartTime = toc;
    if strcmp(solver,'greedy')
        [~, heuristicSol] = s.greedySolve;
    elseif strcmp(solver, 'piPrime')
        sCopy = s;
        heuristicSol = [];
        t = 1;
        while sCopy.nItems > 0
            a = piPrime(sCopy,t,piPrimeData);
            if a > sCopy.nItems
                break
            else
                heuristicSol = [heuristicSol, sCopy.originalIndex(a)];
                sCopy = sCopy.selectItem(a);
                t = t + 1;
            end
        end
    elseif strcmp(solver, 'exactHeur')
        [~, heuristicSol, GurobimipGap, prevSol] = s.GurobiSolve(1, 1/scaleFactor + gurobiEpsiolon); %terminate when column with reduced cost is found
        if GurobimipGap > mipGap % solution returned too soon --> keep going
            [~, heuristicSol] = s.GurobiSolve(1, inf, mipGap, prevSol); %terminate when gap is reduced sufficiently. starts with previous solution
        end
    elseif strcmp(solver, 'exact')
        heuristicSol = false(1,n); %empty solution, let the exact solver do the work
    end
    subTime = subTime + toc - subStartTime;
    subCounter = subCounter + 1;
    heuristicPattern = zeros(n,1);
    heuristicPattern(heuristicSol) = 1;
    if (round(1-p*heuristicPattern, 12)) < 0 %reduced cost! (p*gP =! gV) sometimes values get rescaled%-100000 is just a little check to compare with no greedy
        newBasicVariableFound = 1;
        newPattern = heuristicPattern;
    else %check optimal KP solution with Gurobi
        BPstartTime = toc;
        if nonExact
            [BPval, BPsol, GurobimipGap, prevSol] = s.GurobiSolve(1, 1/scaleFactor + gurobiEpsiolon); %terminate when column with reduced cost is found
            if GurobimipGap > mipGap % solution returned too soon --> keep going
                [BPval, BPsol] = s.GurobiSolve(1, inf, mipGap, prevSol); %terminate when gap is reduced sufficiently. starts with previous solution
            end
        else
            [BPval, BPsol] = s.GurobiSolve;
        end
        
        BPTime = BPTime + toc - BPstartTime;
        BPCounter = BPCounter + 1;
        BPPattern = zeros(n,1);
        BPPattern(BPsol) = 1;
        if (round(1-p*BPPattern,12)) < 0 %reduced cost
            newBasicVariableFound = 1;
            newPattern = BPPattern;
        end
    end
    %% 3: compute u
    if newBasicVariableFound
        %find(newPattern)';
        nPatternsGenerated = nPatternsGenerated + 1;
        u = round(Binv*newPattern,12); % round to avoid floating point errors
        positiveU = find(u>0);
        if isempty(positiveU) %means the problem is unbounded
            uhoh = 1
        end
        % 4: find pivot
        [theta, l] = min(x(positiveU)./u(positiveU));
        l = positiveU(l);
        x = x -theta*u;
        x(l) = theta;
        oldPattern = B(:,l);
        B(:,l) = newPattern;
        if mod(nPatternsGenerated,1)==0
            Binv = inv(B);
        else
            fastTermW = newPattern-oldPattern;
            denumeratorStorage = Binv*fastTermW;
            denumerator = 1 + denumeratorStorage(l);
            numerator = Binv*fastTermW*Binv(l,:);
            Binv = (Binv - (numerator/denumerator));
        end
        thetaSum = thetaSum + theta;
    end
end
%%
BPCounter = BPCounter - 1; %the last call did not generate a column
time = toc;
if verbose
fprintf('The total runtime was: %.2f seconds, the exact solver took: %.2f seconds, and the subproblem solver took: %.2f seconds\n', toc, BPTime, subTime)
fprintf('Optimal solution found: %.6f bins needed\nThere were %d columns generated.\nThe subproblem was solved to optimality %d times.\n', sum(x), nPatternsGenerated, BPCounter)
end
if strcmp(solver, 'piPrime')
    clear piPrime %clear the persistent variable just to be sure
end