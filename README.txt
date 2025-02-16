%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% README for supplemental code associated with the following manuscript:
%
% "Advantages of Bilinear Koopman Realizations for the Modeling and Control of
% Systems with Unknown Dynamics", by Daniel Bruder, Xun Fu, and Ram Vasudevan
%
% Preprint: https://arxiv.org/pdf/2010.09961.pdf
%
% All code written using Matlab 2019a
%
% Author: Daniel Bruder (bruderd@umich.edu, dbruder@seas.harvard.edu)
% Last updated: 2020-11-20
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%%%%%%%%%%%%%%%%%%%%%%%%%%% Overview of Project %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

This code can be used to generate models and controllers from data.
It was used to construct linear, bilinear, and nonlinear Koopman model
realizations for a simulated planar 3-link arm system.
The data used to train these models is included, and example scripts are
provided for recreating these models and controllers on your machine.

This code can also be used to generate models and controllers for other systems
based on your own data.

Below are the names and descriptions of some of the included contents:

Classes:
-Arm
  Properties:     - Parameters associated with simulated planar arm system, e.g.
                    number of links, mass of links, joint stiffness, etc.
  Methods:        - Functions for defining equations of motion of system,
                    functions for simulating system, functions for sensing state
                    of the system, and functions for animating the system.
-Ksysid
  Properties:     - Parameters associated with data used for training a model,
                    e.g. dimension of input, dimension of output, timestep, etc.
  Methods:        - Contains all functions associated with constructing Koopman
                    realizations from data.
-Kmpc             (constructed from user inputs and instance of Ksysid class)
  Properties:     - Parameters associated with MPC controller such as length of
                    planning horizon, input bounds, state bounds, etc.
  Methods:        - Contains functions for constructing MPC problem matrices
                    and solving MPC optimization problem.
-Ksim             (constructed from instances of Kmpc and Arm classes)
  Properties:     - Inherited parameters from the Kmpc and Arm class
                    instances it is constructed from.
  Methods:        - Function that runs a simulated MPC controller trial.
-Data
  Properties:     - None
  Methods:        - Various functions for manipulating data, e.g. chopping
                    single time-series into multiple trials, merging
                    multiple time-series into single trial, or converting raw
                    data into format suitable for the Ksysid class.

Folders:
-dataFiles        - Contains data used for training models.
-trajectories     - Contains the reference trajectories used in the experiments
                    from the paper, as well as scripts for generating new
                    reference trajectories.
-systems          - Where instances of system classes (e.g. Arm classes)
                    can be stored, along with Koopman model realizations
                    (i.e. instances of Ksysid classes) associated with those
                    system class instances.

Examples:
-example_sysid.m  - Trains linear, bilinear, and nonlinear Koopman model from
                    data.
-example_control.m- Constructs a linear , bilinear, and nonlinear MPC controller
                    based on Koopman realizations and simulates controller
                    performance in a trajectory following task.

Additional Files:
-Ksysid_setup.m   - Builds a linear/bilinear/nonlinear Koopman model from data
                    by constructing an instance of the Ksysid class.
-Kmpc_setup.m     - Builds a linear/bilinear/nonlinear MPC controller from a
                    Koopman model by constructing an instacne of the Kmpc class.
-quadprog_gurobi.m- Needed to solve optimization problems using the Gurobi
                    Gurobi software (optional).
-partitions.m     - Support function for creating sets of polynomial basis
                    functions.
-auto_remane.m    - Helps avoid overwriting old files when saving by appending
                    numbers to file names.




%%%%%%%%%%%%%%% How to construct a Koopman model from data %%%%%%%%%%%%%%%%%%%%%

Step 0:-------------------------------------------------------------------------
Before running 'Ksysid_setup.m' you can customize the model by changing the
Name-Value pair input arguments into Ksysid, found on lines 16-24:

Name:                       Value:
'model_type'                'linear' , 'bilinear' , 'nonlinear'
'time_type'                 'discrete' , 'continuous'
'obs_type'                  'poly' , 'fourier' , 'gaussian' , 'hermite' ,
                            'fourier-sparser'
'obs_degree'                1,2,3,4,...
'snapshots'                 1,2,3,4,..., Inf
'lasso'                     [0 , Inf]
'delays'                    0,1,2,3,4,...
'loaded'                    true , false
'dim_red'                   true , false

Note that 'lasso' is an L1 regularization term. As implemented, the least-square
solution is given for 'lasso' = Inf, not 0.

You can train several models at once for different values of 'lasso' by
setting its value to a vector. For example if I set it to [1 2 3]. It will train
3 separate models with 'lasso' equal to 1, 2, and 3 respectively.

Step 1:-------------------------------------------------------------------------
Run 'Ksysid_setup.m'. You will be prompted to choose a datafile from the
'dataFiles' folder. A file containing the planar arm data from the paper is
included, called 'arm-3link-markers-noload-50trials_train-10_val-5.mat'.
Then a model will be generated.

Step 2:-------------------------------------------------------------------------
Comparison plots between the generated model and validation data will be
generated, and a dialog box will appear asking if you would like to save the
model. Answering yes will save the Ksysid class as a file in 'systems/fromData',
otherwise it will just exist in the Matlab Workspace.

You can always save you model later by running the following from the command
line:
>> ksysid.save_class()

The model matrices/functions are containted in Ksysid.model, for a single model,
or Ksysid.candidates if you generated multiple models by setting 'lasso' equal
to a vector in Step 0.




%%%%%%%%%%%%%%%%%%%%%%%%%%%% Running Examples %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Two example files are included:
-example_sysid.m
-example_control.m

example_sysid.m will train a linear, bilinear, and nonlinear Koopman model from
the included 'arm-3link-markers-noload-50trials_train-10_val-5.mat' data file,
then generate a plot showing the predictions generated by each model compared to
a single validation trial. You can change the parameters of the model(s)
generated by modifying the Name/Value arguments into Ksysid each time it is
called.

example_control.m will construct a linear, bilinear, and nonlinear MPC
controller based on included model realizations. It will simulate the a
trajectory following task using each controller and plot the results. You can
change the parameters of the MPC controllers by modifying the Name/Value
arguments into Kmpc each time it is called.


%%%%%%%%%%%%%%%%%%%%%%%%%%%% Known Issues %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Issue #1 (2021-05-26): u is actually joint reference angle not joint torques
    Input 'u' into Arm system is not joint torques, as described in the
accompanying paper. It is actually joint reference angles with the joint 
torques defined as follows: joint_torques = ku * ( u - alpha ),
where ku is a stiffness constant and alpha is the actual joint angles.


















