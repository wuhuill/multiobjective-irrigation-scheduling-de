function [parentPopulation, mutatedPopulation] = differentialEvolutionMutation(population, F, params)
    % 主函数：对整个种群进行变异并修复约束，并记录约束满足率

    % 按轮期划分种群
    [subPopulation3, subPopulation4] = splitSubPopulations(population);
    parentPopulation = [subPopulation3, subPopulation4];

    % 对子种群分别进行变异并修复约束
    [mutatedSubPopulation3, stats3] = processSubPopulation(subPopulation3, F, params);
    [mutatedSubPopulation4, stats4] = processSubPopulation(subPopulation4, F, params);

    % 合并变异后的种群
    mutatedPopulation = [mutatedSubPopulation3, mutatedSubPopulation4];

    % 记录约束满足率统计信息
    displayConstraintStats(stats3, stats4);
end

% --- 工具函数定义 ---
function [subPopulation3, subPopulation4] = splitSubPopulations(population)
    % 按轮期划分种群
    subPopulation3 = population([population.numStages] == 3);
    subPopulation4 = population([population.numStages] == 4);
end
function [mutatedSubPopulation, stats] = processSubPopulation(subPopulation, F, params)
    % 对指定轮期的子种群进行变异和约束修复，同时记录修复统计信息
    populationSize = length(subPopulation);
    mutatedSubPopulation = subPopulation;

    stats = struct('total', 0, 'violations', 0);

    for i = 1:populationSize
        % 生成变异个体
        mutatedIndividual = mutateIndividual(subPopulation, i, F, params);

        % 修复约束条件并统计修复情况
        [mutatedSubPopulation(i), violated] = fixConstraints(mutatedIndividual, params);

        % 修复玉米的灌水比例
        for j = 1:mutatedIndividual.numStages
            for k = 1:params.I
                for day = mutatedSubPopulation(i).irrigationStart(k, j):mutatedSubPopulation(i).irrigationEnd(k, j)
                    if day < params.start_time_maize
                        mutatedSubPopulation(i).maizeRatio(k, j, day - mutatedSubPopulation(i).stageStart(j) + 1) = 0;
                    elseif day <= params.end_time_wheat
                        mutatedSubPopulation(i).maizeRatio(k, j, day - mutatedSubPopulation(i).stageStart(j) + 1) = 1 - mutatedSubPopulation(i).wheatRatio(k, j, day - mutatedSubPopulation(i).stageStart(j) + 1);
                    else
                        mutatedSubPopulation(i).maizeRatio(k, j, day - mutatedSubPopulation(i).stageStart(j) + 1) = 1;
                    end
                end
            end
        end

        % 更新统计信息
        stats.total = stats.total + 1;
        if violated
            stats.violations = stats.violations + 1;
        end
    end
end
function mutatedIndividual = mutateIndividual(subPopulation, targetIndex, F, params)
    % 变异操作：DE的核心变异逻辑
    % 输入参数：
    % - subPopulation：种群数据，包含各个个体的相关参数信息
    % - targetIndex：要进行变异的目标个体在种群中的索引
    % - F：动态调整因子，用于控制变异的程度
    % 输出参数：
    % - mutatedIndividual：变异后的个体，包含了经过各种变异操作后的相关参数值
    % 函数内部主要完成以下操作：
    % 1. 生成随机索引并获取目标个体及差分向量
    % 2. 根据动态调整因子对轮期长度、间隔、每日灌水量等参数进行变异
    % 3. 对变异后的轮期长度和间隔进行约束修复，每个区域的灌溉开始时间和持续时间进行变异和修复
    % 4. 对第一个轮期的起始时间进行变异
    populationSize = length(subPopulation);

    % 事先生成所有随机索引并去重
    indices = setdiff(randperm(populationSize), targetIndex, 'stable');
    r1 = indices(1); r2 = indices(2); r3 = indices(3);

    % 获取当前目标个体和随机选定的两个差分向量
    target = subPopulation(targetIndex);
    donor1 = subPopulation(r2);
    donor2 = subPopulation(r3);

    % 引入动态调整因子 F（可随代数动态调整）
    dynamicF = F * (1 + 0.1 * randn);

    % 构造变异个体，整数问题，第二是dailywater的size要跟irrigationstarttime和endtime对上，wheatRatio也是
    mutatedIndividual = target;
   
    mutatedIndividual.stageLengths = target.stageLengths + round(dynamicF * (donor1.stageLengths - donor2.stageLengths)); % 轮期长度变异
    mutatedIndividual.stageIntervals = target.stageIntervals + round(dynamicF * (donor1.stageIntervals - donor2.stageIntervals)); % 轮期间隔长度变异 
    % 检查并修复轮期长度和间隔总天数约束
    mutatedIndividual = fixStageLengthsAndIntervals(mutatedIndividual, params);
    
    mutatedIndividual = mutateStageStart(mutatedIndividual, params); % 对第一个轮期的起始时间进行变异
    
    mutatedIndividual = mutateIrrigationPeriod(mutatedIndividual, target, donor1, donor2, dynamicF, params);  % 对灌溉时间段进行变异，并满足约束
    mutatedIndividual = mutateDailyWaterandWheatRatio(mutatedIndividual, target, donor1, donor2, dynamicF, params); % 对每日小麦和玉米的总灌水量/小麦的灌水比例进行变异，并使其在灌溉开始时间和结束时期之间

    
end
function [individual, violated] = fixConstraints(individual, params)
    % 修复所有约束条件，并返回是否存在违反约束的情况

    violated = false;
    % 1. 修复轮期长度和间隔总天数在变异的时候已经做过了
    % 2. 修复灌溉时间段约束（启发式优化），
    % 3. 修复每日用水量约束（启发式规则+比例缩放)和小麦每日灌水比例   
    % 4. 修复轮期总灌溉水量约束
    individual = fixStageWaterConstraints(individual, params);
end       
function individual = fixStageLengthsAndIntervals(individual, params)
    % 修复轮期长度和间隔的约束
    totalLength = sum(individual.stageLengths) + sum(individual.stageIntervals);
    if totalLength > params.GPL
        % 超出总天数时，按比例缩放轮期长度和间隔
        scaleFactor = params.GPL / totalLength;
        individual.stageLengths = max(floor(individual.stageLengths * scaleFactor), 10); % 确保最小长度为1
        individual.stageIntervals = max(floor(individual.stageIntervals * scaleFactor), 5); % 确保最小间隔为1
        
        % 重新计算总长度
        totalLength = sum(individual.stageLengths) + sum(individual.stageIntervals);

        % 如果缩放后仍超出，直接在最后一个轮期间隔减2
        while totalLength > params.GPL
            individual.stageIntervals(end) = individual.stageIntervals(end) - 1;
            % 再次更新总长度
            totalLength = sum(individual.stageLengths) + sum(individual.stageIntervals);
        end
    end
end
function mutatedIndividual = mutateStageStart(mutatedIndividual, params)
    % 对第一个轮期的起始时间进行变异
    % 输入参数：
    % - mutatedIndividual: 需要变异的个体
    % - params: 参数结构体，包含 GPL 等约束信息

    % 获取总轮期长度和间隔
    totalStageLength = sum(mutatedIndividual.stageLengths);
    totalStageInterval = sum(mutatedIndividual.stageIntervals);

    % 第一个轮期的起始时间范围
    minStartDay = 1;
    maxStartDay = params.GPL - totalStageLength - totalStageInterval + 1;

    % 添加随机扰动进行变异
    maxPerturbation = 5; % 定义最大扰动幅度
    perturbation = randi([-maxPerturbation, maxPerturbation]); % 随机扰动
    mutatedIndividual.stageStart(1) = mutatedIndividual.stageStart(1) + perturbation;

    % 修正第一个轮期的起始时间到合法范围
    mutatedIndividual.stageStart(1) = max(min(mutatedIndividual.stageStart(1), maxStartDay), minStartDay);

    % 更新后续轮期的起始时间
    for i = 2:length(mutatedIndividual.stageLengths)
        mutatedIndividual.stageStart(i) = mutatedIndividual.stageStart(i - 1) + mutatedIndividual.stageLengths(i - 1) + mutatedIndividual.stageIntervals(i - 1);
    end
    for i = 1:length(mutatedIndividual.stageLengths)
        mutatedIndividual.stageEnd(i) = mutatedIndividual.stageStart(i) + mutatedIndividual.stageLengths(i) - 1;
    end
end
function mutatedIndividual = mutateIrrigationPeriod(mutatedIndividual, target, donor1, donor2, F, params)
    for j = 1:mutatedIndividual.numStages
        stageStartJ = mutatedIndividual.stageStart(j);
        stageEndJ = mutatedIndividual.stageEnd(j);

        % 计算当前灌溉长度
        currentIrrigationLength = target.irrigationEnd(:, j) - target.irrigationStart(:, j) + 1;

        % 根据差分向量变异灌溉长度
        diff1 = donor1.irrigationEnd(:, j) - donor1.irrigationStart(:, j);
        diff2 = donor2.irrigationEnd(:, j) - donor2.irrigationStart(:, j);
        irrigationLengthDiff = round(F * (diff1 - diff2));
        mutatedIrrigationLength = currentIrrigationLength + irrigationLengthDiff;

        % 限制灌溉长度的最小值和最大值
        minIrrigationLength = ceil(mutatedIndividual.stageLengths(j) / 5);
        maxIrrigationLength = mutatedIndividual.stageLengths(j);
        mutatedIrrigationLength = max(minIrrigationLength, min(maxIrrigationLength, mutatedIrrigationLength));

        % 设置灌溉开始时间与轮期开始时间相同，并给予一定浮动
        maxStartFloat = stageEndJ - stageStartJ - mutatedIrrigationLength + 1; % 设定最大浮动天数
        for  k = 1:params.I
            mutatedIndividual.irrigationStart(k, j) = stageStartJ + randi([0, maxStartFloat(k)]);
        end
        % 根据变异后的灌溉长度确定灌溉结束时间
        mutatedIndividual.irrigationEnd(:, j) = mutatedIndividual.irrigationStart(:, j) + mutatedIrrigationLength - 1;

        % 确保灌溉结束时间在轮期结束前
        for  k = 1:params.I
            mutatedIndividual.irrigationEnd(k, j) = min(mutatedIndividual.irrigationEnd(k, j), stageEndJ);
        end

    end
end
function mutatedIndividual = mutateDailyWaterandWheatRatio(mutatedIndividual, target, donor1, donor2, F, params)
    % 提取结构体中的数据
    targetWater = target.dailyWater;  % 目标个体的每日灌溉量 (3D 矩阵)
    donor1Water = donor1.dailyWater;  % 差分个体1的每日灌溉量
    donor2Water = donor2.dailyWater;  % 差分个体2的每日灌溉量
    
    targetWheat = target.wheatRatio;  % 目标个体的每日灌溉量 (3D 矩阵)
    donor1Wheat = donor1.wheatRatio;  % 差分个体1的每日灌溉量
    donor2Wheat = donor2.wheatRatio;  % 差分个体2的每日灌溉量

    % 初始化变异结果
    mutatedWater = zeros(params.I, mutatedIndividual.numStages, max(mutatedIndividual.stageLengths));
    mutatedWheat = zeros(params.I, mutatedIndividual.numStages, max(mutatedIndividual.stageLengths));

    % 遍历每个区域和轮期
    for regionIdx = 1:params.I
        for periodIdx = 1:mutatedIndividual.numStages
            % 1. 计算轮期内的相对时间范围
            targetRelStart = target.irrigationStart(regionIdx, periodIdx) - target.stageStart(periodIdx) + 1;
            targetRelEnd = target.irrigationEnd(regionIdx, periodIdx) - target.stageStart(periodIdx) + 1;

            donor1RelStart = donor1.irrigationStart(regionIdx, periodIdx) - donor1.stageStart(periodIdx) + 1;
            donor1RelEnd = donor1.irrigationEnd(regionIdx, periodIdx) - donor1.stageStart(periodIdx) + 1;

            donor2RelStart = donor2.irrigationStart(regionIdx, periodIdx) - donor2.stageStart(periodIdx) + 1;
            donor2RelEnd = donor2.irrigationEnd(regionIdx, periodIdx) - donor2.stageStart(periodIdx) + 1;
            
            % 2. 提取目标区域和轮期的 DailyWater 和 wheatRatio 数据
            targetSegment = squeeze(targetWater(regionIdx, periodIdx, targetRelStart:targetRelEnd));
            donor1Segment = squeeze(donor1Water(regionIdx, periodIdx, donor1RelStart:donor1RelEnd));
            donor2Segment = squeeze(donor2Water(regionIdx, periodIdx, donor2RelStart:donor2RelEnd));
            
            targetWheatSegment = squeeze(targetWheat(regionIdx, periodIdx, targetRelStart:targetRelEnd));
            donor1WheatSegment = squeeze(donor1Wheat(regionIdx, periodIdx, donor1RelStart:donor1RelEnd));
            donor2WheatSegment = squeeze(donor2Wheat(regionIdx, periodIdx, donor2RelStart:donor2RelEnd));
            
            
            % 3. 调用 alignRelativePeriods 对 DailyWater 和 wheatRatio 数据变异
            mutatedSegment = alignRelativePeriods(targetSegment, donor1Segment, donor2Segment, F);
            mutatedWheatSegment = alignRelativePeriods(targetWheatSegment, donor1WheatSegment, donor2WheatSegment, F);

            % 4. 填充变异后的数据
           
            % 如果变异后的长度超过目标范围，截断
            irrigationLength = mutatedIndividual.irrigationEnd(regionIdx, periodIdx) - mutatedIndividual.irrigationStart(regionIdx, periodIdx) + 1;
            if length(mutatedSegment) > irrigationLength
                mutatedSegment = mutatedSegment(1:irrigationLength);
                mutatedSegment = mutatedSegment';

                mutatedWheatSegment = mutatedWheatSegment(1:irrigationLength);
                mutatedWheatSegment = mutatedWheatSegment';
            elseif length(mutatedSegment) < irrigationLength
                % 如果不足，补均值
                mutatedSegment = mutatedSegment';
                meanValue = mean(mutatedSegment, 'omitnan');
                addingSegment = repmat(meanValue, 1, irrigationLength - length(mutatedSegment));
                mutatedSegment = [mutatedSegment, addingSegment];
           
                mutatedWheatSegment = mutatedWheatSegment';
                meanWheatValue = mean(mutatedWheatSegment, 'omitnan');
                addingWheatSegment = repmat(meanWheatValue, 1, irrigationLength - length(mutatedWheatSegment));
                mutatedWheatSegment = [mutatedWheatSegment, addingWheatSegment];
            end

            % 将变异后的结果更新到目标区域和轮期
            mutatedWater(regionIdx, periodIdx, 1:(mutatedIndividual.irrigationEnd(regionIdx, periodIdx) - mutatedIndividual.irrigationStart(regionIdx, periodIdx) + 1)) = mutatedSegment;
            mutatedWheat(regionIdx, periodIdx, 1:(mutatedIndividual.irrigationEnd(regionIdx, periodIdx) - mutatedIndividual.irrigationStart(regionIdx, periodIdx) + 1)) = mutatedWheatSegment;
        end
    end
    % 修复dailyWater，在0.4到1最大灌水量
    maxDailyWater= zeros(params.I, mutatedIndividual.numStages, max(mutatedIndividual.stageLengths));
    for j = 1:mutatedIndividual.numStages
        for k = 1:params.I
            % 提取当前轮期数据
            round_data = params.maxWaterPerDayRegion(k, mutatedIndividual.irrigationStart(k, j):mutatedIndividual.irrigationEnd(k, j));
            % 填充到结果矩阵中
            maxDailyWater(k, j, 1:length(round_data)) = round_data;
        end
    end
    mutatedWater = max(min(mutatedWater, maxDailyWater), 0.4 * maxDailyWater); 
    % 修复wheatRatio，在 0 ~ 1 之间
    mutatedWheat = max(min(mutatedWater, 1), 0); 
    % 更新结果
    mutatedIndividual.dailyWater = mutatedWater;
    mutatedIndividual.wheatRatio = mutatedWheat;
end
function mutatedSegment = alignRelativePeriods(targetSegment, donor1Segment, donor2Segment, F)
    % 对齐 DailyWater 的长度
    maxLength = max([length(targetSegment), length(donor1Segment), length(donor2Segment)]);

    % 如果不足，补齐为均值
    targetSegment = padWithMean(targetSegment, maxLength);
    donor1Segment = padWithMean(donor1Segment, maxLength);
    donor2Segment = padWithMean(donor2Segment, maxLength);

    % 进行差分变异
    mutatedSegment = targetSegment + F * (donor1Segment - donor2Segment);
end
function paddedSegment = padWithMean(segment, targetLength)
    % 如果当前段的长度不足，则用均值填充
    currentLength = length(segment);
    if currentLength < targetLength
        meanValue = mean(segment, 'omitnan');
        paddedSegment = [segment; repmat(meanValue, targetLength - currentLength, 1)];
    else
        paddedSegment = segment;
    end
end
function individual = fixStageWaterConstraints(individual, params)
    % 修复轮期的总用水量约束
    maxWaterPerStage = params.maxWaterPerStage_all(:, individual.numStages - 2); % 因为3个轮期是第一列，4个轮期是第二列
    for j = 1:individual.numStages
        totalWater = sum(individual.dailyWater(:, j, :), 'all');
        if totalWater > maxWaterPerStage(j)
            scaleFactor = maxWaterPerStage(j) / totalWater;
            individual.dailyWater(:, j, :) = individual.dailyWater(:, j, :) * scaleFactor;
        end
    end
end
function displayConstraintStats(stats3, stats4)
    % 显示约束满足率统计信息
    fprintf('--- Constraint Statistics ---\n');
    fprintf('3-stage population: %d total, %d violations (%.2f%%)\n', ...
            stats3.total, stats3.violations, 100 * stats3.violations / stats3.total);
    fprintf('4-stage population: %d total, %d violations (%.2f%%)\n', ...
            stats4.total, stats4.violations, 100 * stats4.violations / stats4.total);
end