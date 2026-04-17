function mutants = mutation_DE(population, params, F)
% MUTATION_DE
% Perform DE/rand/1 mutation on the population.
%
% INPUT
%   population : parent population (struct array)
%   params     : parameter structure
%   F          : differential weight (unitless)
%
% OUTPUT
%   mutants    : mutated population (struct array)
%
% NOTES
%   - Decision variables are daily irrigation depth values (mm/day).
%   - Bound handling is applied after mutation.

N = numel(population);
mutants = population;

for i = 1:N
    idx = randperm(N, 3);

    a = population(idx(1)).x;
    b = population(idx(2)).x;
    c = population(idx(3)).x;

    v = a + F * (b - c);

    % Bound handling
    v = max(v, params.irrigationLower);
    v = min(v, params.irrigationUpper);

    mutants(i).x = v;
end
end