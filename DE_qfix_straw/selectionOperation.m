function [updatedPopulation, updatedObjectives] = selectionOperation(population, trialPopulation, objectives, trialObjectives)
    % 选择操作函数，结合非支配排序与拥挤度
    % 输入：
    % - population: 当前种群
    % - trialPopulation: 试验种群
    % - objectives: 当前种群的目标值
    % - trialObjectives: 试验种群的目标值
    % 输出：
    % - updatedPopulation: 更新后的种群
    % - updatedObjectives: 更新后的目标值

    % 合并当前种群和试验种群
    combinedPopulation = [population; trialPopulation];
    combinedObjectives = [objectives; trialObjectives];

    % 计算非支配排序和拥挤距离
    [ranks, crowdingDistances] = Copy_of_fastNonDominatedSort(combinedObjectives);

    % 根据非支配等级和拥挤距离选择前 popSize 个个体
    popSize = length(population);
    selectedIndices = selectBasedOnRankAndDiversity(ranks, crowdingDistances, popSize);

    % 更新种群和目标值
    updatedPopulation = combinedPopulation(selectedIndices);
    updatedObjectives = combinedObjectives(selectedIndices, :);
end
function selectedIndices = selectBasedOnRankAndDiversity(ranks, crowdingDistances, popSize)
    % 根据非支配排序和拥挤距离选择个体
    selectedIndices = [];
    currentRank = 1;

    while length(selectedIndices) + sum(ranks == currentRank) <= popSize
        selectedIndices = [selectedIndices; find(ranks == currentRank)];
        currentRank = currentRank + 1;
    end

    remainingIndices = find(ranks == currentRank);
    [~, sortedIdx] = sort(crowdingDistances(remainingIndices), 'descend');
    selectedIndices = [selectedIndices; remainingIndices(sortedIdx(1:popSize - length(selectedIndices)))];
end



