% 选择操作：贪婪选择
function nextGeneration = DESelection_version3(trialPopulation, parentPopulation, fitnessTrial, fitnessParent, eliteFraction, maxPenalty)
    % 输入：
    % - trialPopulation: 子代候选解（结构体数组，包含变量和适应度值）
    % - parentPopulation: 父代种群解（结构体数组，包含变量和适应度值）
    % - eliteFraction: 精英保留比例 (0~1)，如 0.1 表示保留 10% 的精英
    % - maxPenalty: 惩罚值的最大阈值（例如 1e10）
    
    % 输出：
    % - nextGeneration: 下一代种群（结构体数组）
    
    % 参数检查
    if nargin < 5
        eliteFraction = 0.05; % 默认保留 10% 的精英
    end
    if nargin < 6
        maxPenalty = 1e10; % 默认惩罚阈值为 1e10
    end
    
    % 获取种群规模
    numIndividuals = numel(parentPopulation);
    
    % 初始化下一代种群
    nextGeneration = parentPopulation; % 预分配空间，保留父代结构体格式
    
    % 步骤 1：精英保留机制
    % 计算适应度值排序，保留前 eliteFraction 的个体
    [~, sortedIdx] = sort(fitnessParent); % 按父代适应度值从小到大排序
    eliteCount = max(1, ceil(numIndividuals * eliteFraction)); % 至少保留一个精英个体
    eliteIdx = sortedIdx(1:eliteCount); % 精英个体索引
    nextGeneration(1:eliteCount) = parentPopulation(eliteIdx); % 保留精英个体
    
    % 步骤 2：比较子代和父代适应度值
    isTrialBetter = fitnessTrial < fitnessParent; % 子代优于父代的布尔索引
    for i = 1:numIndividuals
        % 替换非精英中更优的个体
        if ~ismember(i, eliteIdx) && isTrialBetter(i)
            nextGeneration(i) = trialPopulation(i);
        end
    end
    
    % 步骤 3：无效解处理
    % 找出被惩罚的解（适应度值超过 maxPenalty）
    invalidTrial = fitnessTrial >= maxPenalty;
    invalidParent = fitnessParent >= maxPenalty;
    
    % 统计无效解的数量
    if all(invalidTrial & invalidParent)
        warning('All solutions are invalid. Consider injecting random valid solutions.');
        % 注入随机解以维持种群多样性
        numInject = ceil(numIndividuals * 0.1); % 默认随机替换 10% 的个体
        replaceIdx = randperm(numIndividuals, numInject);
        for j = 1:numInject
            % 生成随机结构体解并替换到对应位置
            nextGeneration(replaceIdx(j)) = generateRandomSolution(parentPopulation(1));
        end
    else
        % 子代和父代中无效解保留父代有效解
        validParent = ~invalidParent; % 父代有效解索引
        nextGeneration(validParent) = parentPopulation(validParent);
    end
    
    % 步骤 4：返回下一代种群
end

function randomSolution = generateRandomSolution(template)
    % 根据模板生成随机结构体解
    randomSolution = template; % 复制结构体模板
    fieldNames = fieldnames(template); % 获取变量的字段名
    
    % 为每个字段生成随机值（具体值范围需要根据实际问题调整）
    for i = 1:numel(fieldNames)
        fieldName = fieldNames{i};
        % 假设所有变量范围为 [0, 1]，根据实际情况修改
        randomSolution.variables.(fieldName) = rand(size(template.(fieldName)));
    end
end