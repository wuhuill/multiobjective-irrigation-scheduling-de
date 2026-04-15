% 变异函数：轮期内不出现间断，并更新轮期开始时间结束时间轮期长度和轮期间隔
function mutatedPopulation = DEMutation_fixTurn_version2(population, F, params)
    % 主函数：对整个种群进行变异并修复约束
    populationSize = length(population);
    mutatedPopulation = population;

    for i = 1:populationSize
        % 生成变异个体
        mutatedIndividual = mutateIndividual(population, i, F, params);

        % 修复约束条件并统计修复情况
        mutatedPopulation(i) = fixConstraints(mutatedIndividual, params);
        
        % 修复玉米的灌水比例
        mutatedPopulation(i).maizeRatio = zeros(params.I, params.numStages, max(mutatedPopulation(i).stageLengths));
        
        for j = 1:params.numStages
            for day = mutatedPopulation(i).stageStart(j):mutatedPopulation(i).stageEnd(j)
                if day < params.start_time_maize
                    mutatedPopulation(i).maizeRatio(:, j, day - mutatedPopulation(i).stageStart(j) + 1) = 0;
                elseif day <= params.end_time_wheat
                    mutatedPopulation(i).maizeRatio(:, j, day - mutatedPopulation(i).stageStart(j) + 1) = 1 - mutatedPopulation(i).wheatRatio(:, j, day - mutatedPopulation(i).stageStart(j) + 1);
                else
                    mutatedPopulation(i).maizeRatio(:, j, day - mutatedPopulation(i).stageStart(j) + 1) = 1;
                end
            end
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
    target = subPopulation(r1);
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
    individual.stageLengths = min(max(individual.stageLengths, 10), 45); % 确保最小长度为10
    individual.stageIntervals = min(max(individual.stageIntervals, 10), 30); % 确保最小间隔为10
    totalLength = sum(individual.stageLengths) + sum(individual.stageIntervals);
    if totalLength > params.GPL
        % 超出总天数时，按比例缩放轮期长度和间隔
        scaleFactor = params.GPL / totalLength;
        individual.stageLengths = min(max(floor(individual.stageLengths * scaleFactor), 10), 45); % 确保最小长度为10
        individual.stageIntervals = min(max(floor(individual.stageIntervals * scaleFactor), 10), 30); % 确保最小间隔为10
        % 重新计算总长度
        totalLength = sum(individual.stageLengths) + sum(individual.stageIntervals);

        % 如果缩放后仍超出 GPL，进一步修正
        while totalLength > params.GPL
            % 优先减少轮期间隔，确保不低于最小间隔
            if individual.stageIntervals(end) > 10
                individual.stageIntervals(end) = individual.stageIntervals(end) - 1;
                % 如果间隔已经到达最小值，则减少轮期长度，确保不低于最小长度
            elseif individual.stageLengths(end) > 10
                individual.stageLengths(end) = individual.stageLengths(end) - 1;
            end       
            % 再次计算总长度
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
   for j = 1:params.numStages
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

        % 设置灌溉开始时间，并确保范围内浮动
        maxStartFloat = max(0, stageEndJ - stageStartJ - mutatedIrrigationLength + 1);
        offset = round(normrnd(0, maxStartFloat / 3));
        irrigationStartFixed = randi(params.I);
        for k = 1:params.I
            mutatedIndividual.irrigationStart(k, j) = max(stageStartJ, min(stageEndJ, stageStartJ + offset(k)));
            if k == irrigationStartFixed
                mutatedIndividual.irrigationStart(k, j) = stageStartJ;
            end
        end
        
        % 根据变异后的灌溉长度确定灌溉结束时间
        mutatedIndividual.irrigationEnd(:, j) = mutatedIndividual.irrigationStart(:, j) + mutatedIrrigationLength - 1;

        % 确保时间范围调整在轮期内
        mutatedIndividual.irrigationStart(:, j) = max(mutatedIndividual.irrigationStart(:, j), stageStartJ);
        mutatedIndividual.irrigationEnd(:, j) = min(mutatedIndividual.irrigationEnd(:, j), stageEndJ);

        % 调整时间段以确保所有区域的灌溉时间有交集
        % 遍历所有区域，检查两两之间是否有重叠
        for k = 1:params.I
            % 当前区域的时间段
            currStart = mutatedIndividual.irrigationStart(k, j);
            currEnd = mutatedIndividual.irrigationEnd(k, j);
            
            % 检查是否与其他区域有交叠
            overlapFound = false;
            for m = 1:params.I
                if m ~= k
                    % 其他区域的时间段
                    otherStart = mutatedIndividual.irrigationStart(m, j);
                    otherEnd = mutatedIndividual.irrigationEnd(m, j);
                    
                    % 判断是否有交叠
                    if currStart <= otherEnd && currEnd >= otherStart
                        overlapFound = true;
                        break; % 已找到交叠，退出循环
                    end
                end
            end
            
            % 如果没有交叠，调整当前区域的时间段
            if ~overlapFound
                % 将当前区域的开始时间调整到其他区域中第一个时间段的范围
                for m = 1:params.I
                    if m ~= k
                        otherStart = mutatedIndividual.irrigationStart(m, j);
                        otherEnd = mutatedIndividual.irrigationEnd(m, j);
                        
                        % 尝试调整当前区域
                        if currStart > otherEnd
                            % 如果当前时间段在其他区域之后，向前移动
                            mutatedIndividual.irrigationStart(k, j) = otherEnd - mutatedIrrigationLength(k) + 1;
                            mutatedIndividual.irrigationEnd(k, j) = otherEnd;
                        elseif currEnd < otherStart
                            % 如果当前时间段在其他区域之前，向后移动
                            mutatedIndividual.irrigationStart(k, j) = otherStart;
                            mutatedIndividual.irrigationEnd(k, j) = otherStart + mutatedIrrigationLength(k) - 1;
                        end
                        
                        % 检查调整后的合法性
                        mutatedIndividual.irrigationStart(k, j) = max(mutatedIndividual.irrigationStart(k, j), stageStartJ);
                        mutatedIndividual.irrigationEnd(k, j) = min(mutatedIndividual.irrigationEnd(k, j), stageEndJ);
                        
                        % 调整后退出循环
                        break;
                    end
                end
            end
        end
        
        % 再次检查范围
        mutatedIndividual.irrigationStart(:, j) = max(mutatedIndividual.irrigationStart(:, j), stageStartJ);
        mutatedIndividual.irrigationEnd(:, j) = min(mutatedIndividual.irrigationEnd(:, j), stageEndJ);
        
        % 报错代码
        if any(mutatedIndividual.irrigationStart(:, j) < mutatedIndividual.stageStart(j), "all")
            disp('mutatedIndividual.irrigationStart is negative, please check');
            keyboard; % 进入调试模式
        end

        % 更新轮期结束时间为所有灌区中最晚的灌溉结束时间
        newStageEnd = max(mutatedIndividual.irrigationEnd(:, j));
        mutatedIndividual.stageEnd(j) = newStageEnd;

        % 更新轮期长度
        mutatedIndividual.stageLengths(j) = newStageEnd - stageStartJ + 1;

        % 如果需要更新轮期间隔，确保至少存在下一轮期
        if j < params.numStages
            nextStageStart = mutatedIndividual.stageStart(j + 1);
            mutatedIndividual.stageIntervals(j) = nextStageStart - newStageEnd;
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
    mutatedWater = zeros(params.I, params.numStages, max(mutatedIndividual.stageLengths));
    mutatedWheat = zeros(params.I, params.numStages, max(mutatedIndividual.stageLengths));

    % 遍历每个区域和轮期
    mutatedIndividualRelStart = zeros(params.I, params.numStages);
    mutatedIndividualRelEnd = zeros(params.I, params.numStages);
    for regionIdx = 1:params.I
        for periodIdx = 1:params.numStages
            % 1. 计算轮期内的相对时间范围
            targetRelStart = target.irrigationStart(regionIdx, periodIdx) - target.stageStart(periodIdx) + 1;
            targetRelEnd = target.irrigationEnd(regionIdx, periodIdx) - target.stageStart(periodIdx) + 1;

            donor1RelStart = donor1.irrigationStart(regionIdx, periodIdx) - donor1.stageStart(periodIdx) + 1;
            donor1RelEnd = donor1.irrigationEnd(regionIdx, periodIdx) - donor1.stageStart(periodIdx) + 1;

            donor2RelStart = donor2.irrigationStart(regionIdx, periodIdx) - donor2.stageStart(periodIdx) + 1;
            donor2RelEnd = donor2.irrigationEnd(regionIdx, periodIdx) - donor2.stageStart(periodIdx) + 1;
            
            mutatedIndividualRelStart (regionIdx, periodIdx) = mutatedIndividual.irrigationStart(regionIdx, periodIdx) - mutatedIndividual.stageStart(periodIdx) + 1;
            mutatedIndividualRelEnd (regionIdx, periodIdx) = mutatedIndividual.irrigationEnd(regionIdx, periodIdx) - mutatedIndividual.stageStart(periodIdx) + 1;
            
            % 报错代码
            if any(mutatedIndividualRelStart < 0, "all")
                disp('mutatedIndividualRelStart is negative, please check');
                keyboard; % 进入调试模式
            end
            
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
            
            mutatedSegment = reshape(mutatedSegment, 1, []);
            mutatedWheatSegment = reshape(mutatedWheatSegment, 1, []);
            % 4. 填充变异后的数据
           
            % 如果变异后的长度超过目标范围，截断
            irrigationLength = mutatedIndividual.irrigationEnd(regionIdx, periodIdx) - mutatedIndividual.irrigationStart(regionIdx, periodIdx) + 1;
            if length(mutatedSegment) > irrigationLength
                mutatedSegment = mutatedSegment(1:irrigationLength);
                mutatedWheatSegment = mutatedWheatSegment(1:irrigationLength);
            elseif length(mutatedSegment) < irrigationLength
                % 如果不足，补均值
                meanValue = mean(mutatedSegment, 'omitnan');
                addingSegment = repmat(meanValue, 1, irrigationLength - length(mutatedSegment));
                mutatedSegment = [mutatedSegment, addingSegment];
           
                meanWheatValue = mean(mutatedWheatSegment, 'omitnan');
                addingWheatSegment = repmat(meanWheatValue, 1, irrigationLength - length(mutatedWheatSegment));
                mutatedWheatSegment = [mutatedWheatSegment, addingWheatSegment];
            end

            % 将变异后的结果更新到目标区域和轮期
            mutatedWater(regionIdx, periodIdx, mutatedIndividualRelStart(regionIdx, periodIdx):mutatedIndividualRelEnd(regionIdx, periodIdx)) = mutatedSegment;
            mutatedWheat(regionIdx, periodIdx, mutatedIndividualRelStart(regionIdx, periodIdx):mutatedIndividualRelEnd(regionIdx, periodIdx)) = mutatedWheatSegment;
        end
    end
    
    % 修复dailyWater，在0.4到1最大灌水量
    maxDailyWater= zeros(params.I, params.numStages, max(mutatedIndividual.stageLengths)); % 提取最大灌水量
    for j = 1:params.numStages
        for k = 1:params.I
            % 提取当前轮期数据
            round_data = params.maxWaterPerDayRegion(k, mutatedIndividual.irrigationStart(k, j):mutatedIndividual.irrigationEnd(k, j));
 
            % 填充到结果矩阵中
            maxDailyWater(k, j, mutatedIndividualRelStart(k, j):mutatedIndividualRelEnd(k, j)) = round_data;
        end
    end
    mutatedWater = max(min(mutatedWater, maxDailyWater), 0.4 * maxDailyWater); 
    
    indices_between_0_and_100 = find(mutatedWater(:) < 100 & mutatedWater(:) > 0);
    if ~isempty(indices_between_0_and_100)
        disp('mutatedIndividual.dailyWater contains values between 0 and 100. Entering debug mode...');
        disp('Indices of values between 0 and 100:');
        disp(indices_between_0_and_100); % 输出异常值的位置
        keyboard; % 进入调试模式
    end
        % 检查 dailyWater 中是否存在大于 1e10 的值
    indices_greater_than_1e10 = find(mutatedWater(:) > 1e9);
    if ~isempty(indices_greater_than_1e10)
        disp('mutatedIndividual.dailyWater contains values greater than 1e10. Entering debug mode...');
        disp('Indices of values greater than 1e10:');
        disp(indices_greater_than_1e10); % 输出异常值的位置
        keyboard; % 进入调试模式
    end
    % 修复wheatRatio，在 0 ~ 1 之间
    mutatedWheat = max(min(mutatedWheat, 1), 0);
    % 修复wheatRatio，在小麦的生育期内
    for j = 1:params.numStages
        for day = mutatedIndividual.stageStart(j):mutatedIndividual.stageEnd(j)
            % 检查 day 是否在小麦生育期内
            if day > params.end_time_wheat
                % 生育期外，保持为 0
                mutatedWheat(:, j, day - mutatedIndividual.stageStart(j) + 1) = 0;
            end
        end
    end
    
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
    % 修复每天所有区域的总用水量约束    
    totalWaterPerDay = zeros(params.I, params.GPL);
    for j = 1:params.numStages
        for day = individual.stageStart(j):individual.stageEnd(j)
            totalWaterPerDay(j, day) = sum(individual.dailyWater(:, j, day - individual.stageStart(j) + 1));
            if totalWaterPerDay(j, day) > 1.2 * params.maxWaterPerDay  %|| totalWaterPerDay (j, day) < 0.6 * maxWaterPerDay
                scaleFactor_perday = totalWaterPerDay(j, day) / (1.2 * params.maxWaterPerDay);
                % 添加限制，避免缩放因子过大
                if scaleFactor_perday > 10  % 你可以根据实际情况调整这个阈值
                    warning('缩放因子过大: scaleFactor_perday = %.2f. 用水量异常.', scaleFactor_perday);
                    scaleFactor_perday = 10; % 限制最大缩放因子
                end
                individual.dailyWater(:, j, day - individual.stageStart(j) + 1) = ...
                individual.dailyWater(:, j, day - individual.stageStart(j) + 1) / scaleFactor_perday;
            end
        end
    end
    

% 修复轮期的总用水量约束
    maxWaterPerStage = params.maxWaterPerStage_all(:, params.numStages - 2); % 因为3个轮期是第一列，4个轮期是第二列
    for j = 1:params.numStages
        totalWater = sum(individual.dailyWater(:, j, :), 'all');
        if totalWater > maxWaterPerStage(j)
            scaleFactor = maxWaterPerStage(j) / totalWater;
            individual.dailyWater(:, j, :) = individual.dailyWater(:, j, :) * scaleFactor;
        end
    end
    
end
