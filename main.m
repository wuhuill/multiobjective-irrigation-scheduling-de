% MAIN
% Entry point for the multi-objective DE irrigation optimization demo.
%
% UNITS AND OUTPUTS
% - Decision variable x: daily irrigation depth (mm/day)
% - Objective 1: negative crop yield (-kg/ha)
% - Objective 2: straw biomass (kg/ha)
% - Objective 3: total seasonal irrigation (mm)
%
% WORKFLOW
% 1. Load demo weather data
% 2. Initialize the population
% 3. Evaluate the initial population
% 4. Run DE iterations
% 5. Extract the Pareto front using non-dominated sorting

clc; clear; close all;
addpath(genpath(pwd));

params = params_demo();
load('demo_weather.mat', 'weather');

% Initialize population
population = initialization(params.popSize, params);

% Evaluate initial population
objectives = objective_wrapper(population, params, weather);

% Main optimization loop
for gen = 1:params.maxGen
    [population, objectives] = DE_main(population, objectives, params, weather);

    [FrontNo, ~] = NDSort(objectives, inf);
    paretoSize = sum(FrontNo == 1);

    fprintf('Generation %d completed. Pareto size = %d\n', gen, paretoSize);
end

% Extract Pareto front
[FrontNo, ~] = NDSort(objectives, inf);
paretoIdx = (FrontNo == 1);
paretoSolutions = population(paretoIdx);
paretoObjectives = objectives(paretoIdx, :);

save('pareto_results.mat', 'population', 'objectives', 'paretoSolutions', 'paretoObjectives');

disp('Optimization finished. Results saved to pareto_results.mat');