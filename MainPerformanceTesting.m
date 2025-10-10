clear; clear piPrime; close all; clc;
%% User Input
generator = @Pe_almostStronglyCorrelated;                %what generator the instances come from - can be empty if instanceArray is given
instanceArray = 'Pe_almostStronglyCorrelated-1000instances-200items.mat'; %if you wish to test on presampled instances for replicability (will ignore the generator then)
nSamples  = 1000;                         %how many instances you wish to test
nItems    = 200;                          %how many items each instance has
policiesToRun = ["greedy",...             %list of policies to test
                 'piTildePrime-12_12_3-Pe_almostStronglyCorrelated-200items.mat'];
compareToGurobi = 1;                      %if you wish to compare to the exact solution

%% Program
[valueFunctionEstimations, valueFunctionTildeEstimations] = performanceEstimation(policiesToRun, generator, nSamples, nItems, compareToGurobi, instanceArray);
if compareToGurobi
    fprintf('Results for exact solver:\n')
    fprintf('The average objective is: %f \n',sum(valueFunctionEstimations('exact').objective)/nSamples)
    fprintf('The average runtime is: %f \n\n',1000*sum(valueFunctionEstimations('exact').time)/nSamples)

    for p = policiesToRun
        fprintf('Results for '+ p +' :\n')
        fprintf('The average objective is: %f \n',sum(valueFunctionEstimations(p).objective)/nSamples)
        fprintf('The average runtime is: %f \n',1000*sum(valueFunctionEstimations(p).time)/nSamples)
        fprintf('The average approximation ratio is: %f \n\n',sum(valueFunctionEstimations(p).objective ./ valueFunctionEstimations('exact').objective)/nSamples)

    end
else
    for p = policiesToRun
        fprintf('Results for '+ p +' :\n')
        fprintf('The average objective is: %f \n',sum(valueFunctionEstimations(p).objective)/nSamples)
        fprintf('The average runtime is: %f \n\n',1000*sum(valueFunctionEstimations(p).time)/nSamples)
    end
end
%%
%this line only makes sense if the first policy in policiesToRun is the initial
%policy, and the second is the improved policy
fprintf('Percentage of the gap close: %f \n', (1 - (1-sum(valueFunctionEstimations(policiesToRun(2)).objective ./ valueFunctionEstimations('exact').objective)/nSamples)/(1-sum(valueFunctionEstimations(policiesToRun(1)).objective ./ valueFunctionEstimations('exact').objective)/nSamples))*100)