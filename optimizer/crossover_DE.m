function trialPopulation = crossover_DE(population, mutants, params, CR)
% Binomial crossover.

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