function [FrontNo, CrowdDis] = NDSort(PopObj, ~)
% NDSORT
% Perform non-dominated sorting and crowding distance calculation.
%
% INPUT
%   PopObj : objective matrix, size = [N x M]
%            all objectives are assumed to be minimized
%
% OUTPUT
%   FrontNo  : non-dominated rank of each individual
%   CrowdDis : crowding distance of each individual
%
% NOTES
%   - FrontNo = 1 corresponds to the first Pareto front.
%   - CrowdDis is used to keep diversity within the same front.

[N, M] = size(PopObj);

FrontNo = inf(N, 1);
S = cell(N, 1);       % set of solutions dominated by p
nDom = zeros(N, 1);    % number of solutions dominating p
fronts = cell(N, 1);

% Dominance relations
for p = 1:N
    S{p} = [];
    nDom(p) = 0;
    for q = 1:N
        if p == q
            continue;
        end
        if dominates(PopObj(p, :), PopObj(q, :))
            S{p} = [S{p}, q]; %#ok<AGROW>
        elseif dominates(PopObj(q, :), PopObj(p, :))
            nDom(p) = nDom(p) + 1;
        end
    end
    if nDom(p) == 0
        FrontNo(p) = 1;
        fronts{1} = [fronts{1}, p]; %#ok<AGROW>
    end
end

% Generate subsequent fronts
f = 1;
while true
    Q = [];
    for p = fronts{f}
        for q = S{p}
            nDom(q) = nDom(q) - 1;
            if nDom(q) == 0
                FrontNo(q) = f + 1;
                Q = [Q, q]; %#ok<AGROW>
            end
        end
    end
    if isempty(Q)
        break;
    end
    f = f + 1;
    fronts{f} = Q;
end

% Crowding distance
CrowdDis = zeros(N, 1);
validFronts = unique(FrontNo(~isinf(FrontNo)));

for fr = validFronts(:)'
    idx = find(FrontNo == fr);
    if numel(idx) <= 2
        CrowdDis(idx) = inf;
        continue;
    end

    D = zeros(numel(idx), 1);
    for m = 1:M
        vals = PopObj(idx, m);
        [sortedVals, order] = sort(vals);

        D(order(1)) = inf;
        D(order(end)) = inf;

        denom = sortedVals(end) - sortedVals(1);
        if denom == 0
            continue;
        end

        for k = 2:numel(idx)-1
            D(order(k)) = D(order(k)) + ...
                (sortedVals(k+1) - sortedVals(k-1)) / denom;
        end
    end
    CrowdDis(idx) = D;
end
end