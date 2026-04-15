function penalty = constraint_penalty(irrigation, params, results)
% Penalty-based constraint handling.
% Returns a 1x3 vector added to all objectives.

penalty = zeros(1, 3);

% Constraint 1: daily irrigation upper bound
if any(irrigation > params.maxDailyIrrigation)
    penalty = penalty + 1e6;
end

% Constraint 2: seasonal irrigation upper bound
if sum(irrigation) > params.maxTotalIrrigation
    penalty = penalty + 1e6;
end

% Constraint 3: minimum yield
if isfield(params, 'minYield') && ~isempty(params.minYield)
    if results.Yield < params.minYield
        penalty = penalty + 1e6;
    end
end
end