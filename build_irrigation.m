function irrigation = build_irrigation(x, params)
% In this public demo, the decision vector itself is the daily irrigation schedule.

irrigation = x(:);

% Safety clamp
irrigation = max(irrigation, params.irrigationLower(:));
irrigation = min(irrigation, params.irrigationUpper(:));
end