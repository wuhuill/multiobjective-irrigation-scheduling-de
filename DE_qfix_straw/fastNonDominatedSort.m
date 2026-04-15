function [nonDominationRanks, crowdingDistances] = fastNonDominatedSort(objectives)
    % 获取种群大小和目标数
    [numIndividuals, numObjectives] = size(objectives);
    
    % 初始化
    nonDominationRanks = zeros(numIndividuals, 1); % 非支配等级
    crowdingDistances = zeros(numIndividuals, 1); % 拥挤距离
    
    % --- 非支配排序 ---
    dominatedCount = zeros(numIndividuals, 1); % 被支配个体数目
    dominatesList = cell(numIndividuals, 1);  % 支配其他个体的列表
    fronts = cell(1); % 存储每一层的帕累托前沿

    % 遍历所有个体，计算支配关系
    for i = 1:numIndividuals
        for j = 1:numIndividuals
            if i ~= j
                if dominates(objectives(i, :), objectives(j, :))
                    dominatesList{i} = [dominatesList{i}, j];
                elseif dominates(objectives(j, :), objectives(i, :))
                    dominatedCount(i) = dominatedCount(i) + 1;
                end
            end
        end
        % 如果该个体没有被任何个体支配，属于 Rank 1
        if dominatedCount(i) == 0
            nonDominationRanks(i) = 1;
            fronts{1} = [fronts{1}, i];
        end
    end

    % 计算其他非支配等级
    rank = 1;
    while ~isempty(fronts{rank})
        nextFront = [];
        for i = fronts{rank}
            for j = dominatesList{i}
                dominatedCount(j) = dominatedCount(j) - 1;
                if dominatedCount(j) == 0
                    nonDominationRanks(j) = rank + 1;
                    nextFront = [nextFront, j];
                end
            end
        end
        rank = rank + 1;
        fronts{rank} = nextFront;
    end

    % --- 拥挤距离计算 ---
    for f = 1:length(fronts)
        front = fronts{f};
        if isempty(front)
            break;
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

% 辅助函数：判断支配关系
function isDominating = dominates(indA, indB)
    isDominating = all(indA <= indB) && any(indA < indB);
end
