# From-Generic-to-Structure-Aware-Heuristics-through-Markov-Decision-Processes--CODE
This repository contains the code used for my paper title 'From Generic to Structure-Aware Heuristics through Markov Decision Processes'.\
All files are Matlab files. There is a dependency on the Gurobi solver, this can be avoided, which will be explained later.

There are 3 Main files:
  -MainPolicyCreation.m to create improved polices
  -MainPerformanceTesting.m to evaluate the performance of the policies created by MainPolicyCreation.m
  -MainColumnGeneration.m to run Column Generation for the Bin Packing Problem with different solvers for the subproblem

The rest of the files are supportive.
All policies of which we report results in the paper are given in the folder 'policies'. The names start with 'piTildePrime' followed by the number of columns and rows for the Grid-Approximation, the number of allowed actions, the instance generator used as D_0, and the number of items for the instances. You can easily create your own policies and compare results using the Main functions below. 
The instance generators and data used for evaluation are also given. The BPP instances for section 5.4.3 are given under the name 'BPP instancesArray'. The instances for section 5.4.1 are given by their Pisinger name followed by '-1000instances-200items'.
The KP instances that arise during the BPP proces, that were used to estimate the approximate TMDP in section 5.4.3 are given in the folder 'KPfromBPP_200items_200lb700ub1000C'.
In case you do not have access to Gurobi, you can replace any line of the form 'instance.GurobiSolve()' to 'instance.BPsolve()' to use Matlab's built-in intlinprog. 

All 3 main files should be self-explanatory, but here follows a brief instruction

HOW TO CREATE A POLICY:
In MainPolicyCreation.m the first section is for user input. 
First specify T, N, and k that define the TMDP encompassing the Knapsack Problem (Section 5.2)
Then specify the number columns and rows for the (m,m)-Grid-Approximation. (Section 5.3)
Then specify what generator to use as D_0 (this can be any of the Pisinger generators) or give a folder location with presampled instances.
Choose an initial policy. This can be 'greedy', 'k-uniform', or a previously trained policy.
Choose the number of samples for the Monte Carlo simulation. In case of presampled instances are given, the simulation ends when the specified number of sampled is reached, or when the samples run out, whichever happens first.
Choose when a state should be classified as undersampled (Section 5.4)
Finally, specify if and how the obtained policy should be saved.

The Monte Carlo simulation prints progress updates. After Policy Iteration is complete the relative improvement is Printed

HOW TO EVALUATE A POLICY:  
In MainPerformanceTesting.m the first section is for user input.
Either specify a generator to use or give an array with presampled Knapsack instances.
Specify how many instances to test.
Specify how many items each instance has at most.
Specify which policies you wish to test.
Specify wether you want to compare with the exact solution (can be slow)

The file prints summarizing statistics at the end. 

HOW TO SOLVE A BIN PACKING PROBLEM COLUMN GENERATION RELAXATION:
In MainPolicyCreation.m the first section is for user input. 
Specify how many BPP instance you wish to solve.
Specify how many items each BPP instance should have
If you wish to solve presampled BPP instances, specify that. If left empty, new BPP instances will be generated.
Specify the list of solvers for the subproblem you wish to evaluate.

At the end of the file average statistics are printed
