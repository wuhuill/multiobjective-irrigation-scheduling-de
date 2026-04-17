function trialPopulation = crossover_DE(population, mutants, params, CR)
% CROSSOVER_DE
% Perform binomial crossover between target and mutant vectors.
%
% INPUT
%   population : parent population (struct array)
%   mutants    : mutated population (struct array)
%   params     : parameter structure
%   CR         : crossover rate (unitless, between 0 and 1)
%
% OUTPUT
%   trialPopulation : trial population after crossover
%
% NOTES
%   - Decision variables are daily irrigation depth values (mm/day).
%   - At least one variable is guaranteed to come from the mutant vector.

N = numel(population);
trialPopulation = population;

for i = 1:N
    target = population(i).x;
    mutant = mutants(i).x;

    dim = numel(target);
    jrand = randi(dim);

    trial = target;
    for j = 1:dim
        if rand < CR || j == jrand
            trial(j) = mutant(j);
        end
    end

    % Bound handling
    trial = max(trial, params.irrigationLower);
    trial = min(trial, params.irrigationUpper);

    trialPopulation(i).x = trial;
end
end