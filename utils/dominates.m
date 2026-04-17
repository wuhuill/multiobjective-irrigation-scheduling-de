function flag = dominates(a, b)
% DOMINATES
% Check whether solution a dominates solution b in a minimization problem.
%
% INPUT
%   a : objective vector of solution a
%   b : objective vector of solution b
%
% OUTPUT
%   flag : true if a dominates b, otherwise false

flag = all(a <= b) && any(a < b);
end