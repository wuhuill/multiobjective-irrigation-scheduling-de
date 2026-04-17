function population = initialization(popSize, params)
% INITIALIZATION
% Create the initial population for the DE optimizer.
%
% INPUT
%   params.popSize         : population size (unitless)
%   params.dim             : number of decision variables (unitless)
%   params.irrigationLower : lower bound of daily irrigation depth (mm/day)
%   params.irrigationUpper : upper bound of daily irrigation depth (mm/day)
%
% OUTPUT
%   population : struct array with field x
%                x = decision vector representing daily irrigation depth
%                    (mm/day)

population = repmat(struct('x', []), popSize, 1);

for i = 1:popSize
    population(i).x = params.irrigationLower + ...
        rand(1, params.dim) .* (params.irrigationUpper - params.irrigationLower);
end
end