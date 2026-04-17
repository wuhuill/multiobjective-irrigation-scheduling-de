function [population, objectives] = DE_main(population, objectives, params, weather)
% DE_MAIN
% Execute one generation of the multi-objective DE optimizer.
%
% INPUT
%   population : current population (struct array)
%   objectives : objective matrix of current population
%                size = [N x 3], all objectives are minimized
%   params     : parameter structure
%   weather    : weather data structure
%
% OUTPUT
%   population : updated population after selection
%   objectives : updated objective matrix
%
% NOTES
%   - This routine preserves the DE workflow:
%     mutation -> crossover -> evaluation -> selection
%   - Pareto ranking is handled inside the selection stage.

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