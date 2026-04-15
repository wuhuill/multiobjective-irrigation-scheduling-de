% 选择操作：贪婪选择
function nextGeneration = differentialEvolutionSelection(trialPopulation, parentPopulation, fitnessTrial, fitnessParent)
    % 选择操作，比较当前种群和变异后的种群，保留适应度更好的个体
    % 输入参数：
    % - currentPopulation: 当前种群的个体矩阵
    % - mutatedPopulation: 变异后的种群的个体矩阵
    % - fitnessCurrent: 当前种群个体的适应度值向量
    % - fitnessMutated: 变异后种群个体的适应度值向量
    %
    % 输出参数：
    % - nextGeneration: 选择后的下一代种群

    % 初始化下一代种群
    numIndividuals = size(parentPopulation, 1);
    nextGeneration = parentPopulation; % 预分配空间

    % 对每个个体进行选择
    for i = 1:numIndividuals
        % 比较当前个体和变异后个体的适应度值
        if fitnessTrial(i) < fitnessParent(i)
            % 如果变异个体更优，替换当前个体
            nextGeneration(i, :) = trialPopulation(i, :);
        end
        % 如果当前个体更优，则保留原个体（无需额外操作）
    end
end
