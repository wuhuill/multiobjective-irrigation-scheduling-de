function paretoFront = extractParetoFront(population, objectives)
    % 提取帕累托前沿解
    % 输入：
    % - population: 当前种群的解矩阵 (popSize × numVariables)
    % - objectives: 当前种群对应的目标值矩阵 (popSize × numObjectives)
    % 输出：
    % - paretoFront: 帕累托前沿解的结构体，包含解和对应的目标值

    % 获取种群规模
    popSize = length(population);

    % 初始化一个布尔向量，标记是否在帕累托前沿上
    isPareto = true(popSize, 1);

    % 遍历所有个体，检查是否被其他个体支配
    for i = 1:popSize
        for j = 1:popSize
            if i ~= j && dominates(objectives(j, :), objectives(i, :))
                isPareto(i) = false; % 如果被支配，则标记为 false
                break;
            end
        end
    end

    % 提取帕累托前沿上的解和目标值
    paretoFront.Solutions = population(isPareto); % 帕累托前沿的解
    paretoFront.Objectives = objectives(isPareto, :); % 帕累托前沿的目标值
end
function isDominating = dominates(solutionA, solutionB)
    % 判断 solutionA 是否支配 solutionB
    % 输入：
    % - solutionA: 一个解的目标值向量 [1 x M]
    % - solutionB: 另一个解的目标值向量 [1 x M]
    % 输出：
    % - isDominating: 布尔值，true 表示 solutionA 支配 solutionB
    
    % 检查 solutionA 是否在所有目标上都不差于 solutionB
    allNotWorse = all(solutionA <= solutionB);
    
    % 检查 solutionA 是否在至少一个目标上更优
    atLeastOneBetter = any(solutionA < solutionB);
    
    % 满足上述两个条件则认为 solutionA 支配 solutionB
    isDominating = allNotWorse && atLeastOneBetter;
end
