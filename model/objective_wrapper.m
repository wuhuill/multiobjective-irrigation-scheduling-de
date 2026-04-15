function objectives = objective_wrapper(population, params, weather)
% 3 objectives, all minimized:
%   f1 = -Yield
%   f2 = Straw
%   f3 = total irrigation
%
% Penalty is added uniformly to all objectives.

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