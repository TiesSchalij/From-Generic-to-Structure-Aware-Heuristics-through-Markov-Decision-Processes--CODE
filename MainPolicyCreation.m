clear; clc;%this is a file to create improved policies
%% User Input
T = 60;                                         %number of timeperiods
k = 3;                                          %number of actions to choose from
nItems = 200;                                   %number of items
nRows = 12; nCols = 12;                         %parameters for the Grid approximation
%if generating new instances                                         
generator = @Pf_subsetSum;             %any generator or []
%if using presampled instances
instanceFolder = [];                            %where to find the instances or []

policyName = 'greedy';                          %initial policy
nSamples = 1E6;                                 %how many instances to use in the Monte Carlo Simulation
estimationCutoff = 5;                           %undersampling parameter for the Monte Carlo Simulation
saveResults = 1;                                %if you want to save the results
if saveResults
    saveName = strcat('piTildePrime-',num2str(nRows),'_',num2str(nCols),'_',num2str(k),'-',func2str(generator),'-',num2str(nItems),'items.mat'); %under what name to save the results
end

%% Program 
grids = cellfun(@(x) {0:(1/nRows):((nRows - 1)/nRows),0:(1/nCols):((nCols-1)/nCols)},cell(1,T),'UniformOutput',false); %uniformly spaces the columns and rows
abstractStates = abstractStatesClass(T, grids, k*ones(1,T));
[Pt, rsa, stateMappingTilde, totalVisits, expectePiValueFunction, goesToTerminal, valueFunctionPiTilde] = sampleTransitions(abstractStates,policyName, nSamples, instanceFolder, generator, nItems);

[piTildePrime, expectedPiTildePrimeValueFunction,valueFunctionPiTildePrime, stateMapping] = policyIteration(Pt, rsa, abstractStates, totalVisits, stateMappingTilde, estimationCutoff,policyName);
fprintf('Pi prime is %2.3f%% better than Pi.\n', (expectedPiTildePrimeValueFunction - expectePiValueFunction)/expectePiValueFunction * 100)
if saveResults
    save(saveName, 'piTildePrime', 'stateMapping', 'stateMappingTilde', 'abstractStates', 'totalVisits', 'estimationCutoff', 'valueFunctionPiTildePrime','expectedPiTildePrimeValueFunction', 'Pt','rsa' , 'valueFunctionPiTilde','-v7.3')
end

