function population = initialization(popSize, params)
% Initialize a population of continuous irrigation schedules.
% Each individual is a struct with field x (1 x dim).

population = repmat(struct('x', []), popSize, 1);

for i = 1:popSize
    population(i).x = params.irrigationLower + ...
        rand(1, params.dim) .* (params.irrigationUpper - params.irrigationLower);
end
end