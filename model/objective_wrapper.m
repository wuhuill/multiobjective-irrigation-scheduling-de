function objectives = objective_wrapper(population, params, weather)
% OBJECTIVE_WRAPPER
% Evaluate the whole population using the crop growth model.
%
% UNITS AND OBJECTIVES
% - x: daily irrigation depth (mm/day)
% - Yield returned by run_crop_model: kg/ha
% - Straw returned by run_crop_model: kg/ha
% - Seasonal irrigation: mm
%
% OBJECTIVES (all minimized)
% - f1 = -Yield (kg/ha)
% - f2 = Straw (kg/ha)
% - f3 = total irrigation (mm)
%
% CONSTRAINT HANDLING
% A penalty vector is added to all objectives when constraints are violated.

N = numel(population);
objectives = zeros(N, 3);

for i = 1:N
    x = population(i).x;

    % Decision vector is already the daily irrigation schedule
    irrigation = build_irrigation(x, params);

    % Preserve the original crop model
    results = run_crop_model(weather, irrigation, params.crop);

    % Simplified objective expressions
    f1 = -results.Yield;
    f2 = results.Straw;
    f3 = sum(max(irrigation, 0));

    penalty = constraint_penalty(irrigation, params, results);

    objectives(i, :) = [f1, f2, f3] + penalty;
end
end