function flag = dominates(a, b)
% True if a dominates b in minimization.

flag = all(a <= b) && any(a < b);
end