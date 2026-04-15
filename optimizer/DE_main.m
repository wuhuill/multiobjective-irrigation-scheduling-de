function [population, objectives] = DE_main(population, objectives, params, weather)
% One DE generation:
% mutation -> crossover -> evaluation -> Pareto selection

F = params.F;
CR = params.CR;

% Mutation
mutants = mutation_DE(population, params, F);

% Crossover
trialPopulation = crossover_DE(population, mutants, params, CR);

% Evaluation
trialObjectives = objective_wrapper(trialPopulation, params, weather);

% Selection
[population, objectives] = selection_DE(population, trialPopulation, objectives, trialObjectives);
end