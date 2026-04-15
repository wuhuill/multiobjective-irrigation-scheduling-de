function [nonDominationRanks, crowdingDistances] = Copy_of_fastNonDominatedSort(objectives, constraints)
    % 获取种群大小和目标数
    [numIndividuals, numObjectives] = size(objectives);
    
    % 初始化
    nonDominationRanks = zeros(numIndividuals, 1); % 非支配等级
    crowdingDistances = zeros(numIndividuals, 1); % 拥挤距离
    
    % --- 如果有约束，进行约束处理 ---
    if nargin > 1
        infeasible = any(constraints > 0, 2);
        objectives(infeasible, :) = repmat(max(objectives, [], 1), sum(infeasible), 1) + ...
                                   repmat(sum(max(0, constraints(infeasible, :)), 2), 1, numObjectives);
    end

    % --- 使用 NDSort 进行非支配排序 ---
    [nonDominationRanks, ~] = NDSort(objectives, inf);


 % --- 拥挤距离计算 ---
    fronts = unique(nonDominationRanks);
    for f = fronts'
        front = find(nonDominationRanks == f);
        if isempty(front)
            continue;
        end
        numFront = length(front);
        distances = zeros(numFront, 1);

        for obj = 1:numObjectives
            % 按当前目标值排序
            [~, sortedIdx] = sort(objectives(front, obj));
            distances(sortedIdx(1)) = inf; % 边界点距离设为无穷
            distances(sortedIdx(end)) = inf;
            for i = 2:(numFront - 1)
                distances(sortedIdx(i)) = distances(sortedIdx(i)) + ...
                    (objectives(front(sortedIdx(i + 1)), obj) - objectives(front(sortedIdx(i - 1)), obj)) / ...
                    (max(objectives(:, obj)) - min(objectives(:, obj)));
            end
        end
        crowdingDistances(front) = distances;
    end
end
