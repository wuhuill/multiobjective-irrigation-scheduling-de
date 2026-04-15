% 变异函数：轮期内不出现间断，并更新轮期开始时间结束时间轮期长度和轮期间隔
function mutatedPopulation = DEMutation_fixTurn_version3(population, F, params)
    % 主函数：对整个种群进行变异并修复约束
    populationSize = length(population);
    mutatedPopulation = population;

    for i = 1:populationSize
        % 生成变异个体
        mutatedPopulation(i) = mutateIndividual(population, i, F, params);
        
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
    mutatedIndividual = mutateDailyWater(mutatedIndividual, target, donor1, donor2, dynamicF, params);
    mutatedIndividual = mutateWheatRatio(mutatedIndividual, target, donor1, donor2, dynamicF, params); % 对每日小麦和玉米的总灌水量/小麦的灌水比例进行变异，并使其在灌溉开始时间和结束时期之间
   
end
     
function individual = fixStageLengthsAndIntervals(individual, params)
    % 修复轮期长度和间隔的约束
    if params.numStages == 3
        individual.stageLengths = min(max(individual.stageLengths, 15), 40); % 确保最小长度为15，最大长度是40
        individual.stageIntervals = min(max(individual.stageIntervals, 10), 30); % 确保最小间隔为10， 最大长度是30
    elseif params.numStages == 4
        individual.stageLengths = min(max(individual.stageLengths, 10), 25); % 确保最小长度为10，最大长度是25
        individual.stageIntervals = min(max(individual.stageIntervals, 6), 18); % 确保最小间隔为6， 最大长度是18
    else
        individual.stageLengths = min(max(individual.stageLengths, 5), 18); % 确保最小长度为15，最大长度是20
        individual.stageIntervals = min(max(individual.stageIntervals, 5), 13); % 确保最小间隔为5， 最大长度是13
    end
    totalLength = sum(individual.stageLengths) + sum(individual.stageIntervals);
    if totalLength > params.GPL
        % 超出总天数时，按比例缩放轮期长度和间隔
        scaleFactor = params.GPL / totalLength;
        individual.stageLengths = min(max(floor(individual.stageLengths * scaleFactor), 10), 40); % 确保最小长度为10
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
        stageStartJ = mutatedIndividual.stageStart(j); % 轮期开始时间
        stageEndJ = mutatedIndividual.stageEnd(j);     % 轮期结束时间
        stageLength = stageEndJ - stageStartJ + 1;     % 轮期长度

        for k = 1:params.I
            % 差分变异调整
            originalLength = target.irrigationEnd(k, j) - target.irrigationStart(k, j) + 1;
            diff1 = donor1.irrigationEnd(k, j) - donor1.irrigationStart(k, j);
            diff2 = donor2.irrigationEnd(k, j) - donor2.irrigationStart(k, j);
            lengthDiff = round(F * (diff1 - diff2)); % 差分变异步长
            mutatedLength = originalLength + lengthDiff; % 新的灌溉持续时间

            % 限制持续时间在允许范围内
            mutatedLength = max(min(mutatedLength, stageLength), round(stageLength / 5));

            % 保持中心点不变调整时间范围
            centerPoint = round((target.irrigationStart(k, j) + target.irrigationEnd(k, j)) / 2);
            mutatedIndividual.irrigationStart(k, j) = max(stageStartJ, centerPoint - floor(mutatedLength / 2));
            mutatedIndividual.irrigationEnd(k, j) = mutatedIndividual.irrigationStart(k, j) + mutatedLength - 1;

            % 确保不超出轮期范围
            if mutatedIndividual.irrigationEnd(k, j) > stageEndJ
                mutatedIndividual.irrigationEnd(k, j) = stageEndJ;
                mutatedIndividual.irrigationStart(k, j) = stageEndJ - mutatedLength + 1;
            end
        end

        % 确保一个区域的灌溉开始时间与轮期开始时间对齐
        fixedStartRegion = randi(params.I);
        durationStart = mutatedIndividual.irrigationEnd(fixedStartRegion, j) - mutatedIndividual.irrigationStart(fixedStartRegion, j) + 1;
        mutatedIndividual.irrigationStart(fixedStartRegion, j) = stageStartJ;
        mutatedIndividual.irrigationEnd(fixedStartRegion, j) = stageStartJ + durationStart - 1;

        % 确保一个区域的灌溉结束时间与轮期结束时间对齐
        fixedEndRegion = randi(params.I);
        while fixedEndRegion == fixedStartRegion
            fixedEndRegion = randi(params.I); % 避免重复选择同一区域
        end
        durationEnd = mutatedIndividual.irrigationEnd(fixedEndRegion, j) - mutatedIndividual.irrigationStart(fixedEndRegion, j) + 1;
        mutatedIndividual.irrigationEnd(fixedEndRegion, j) = stageEndJ;
        mutatedIndividual.irrigationStart(fixedEndRegion, j) = stageEndJ - durationEnd + 1;

        % 确保轮期内灌溉不间断
        timePoints = stageStartJ:stageEndJ; % 轮期内所有时间点
        for t = timePoints
            % 检查时间点 t 是否被覆盖
            if ~any(mutatedIndividual.irrigationStart(:, j) <= t & mutatedIndividual.irrigationEnd(:, j) >= t)
                % 找到最近的区域调整其时间范围覆盖 t，但保持持续时间不变
                [~, closestRegion] = min(abs(mutatedIndividual.irrigationStart(:, j) - t) + ...
                                         abs(mutatedIndividual.irrigationEnd(:, j) - t));
                duration = mutatedIndividual.irrigationEnd(closestRegion, j) - mutatedIndividual.irrigationStart(closestRegion, j) + 1;

                if t < mutatedIndividual.irrigationStart(closestRegion, j)
                    % 提前开始时间
                    newStart = t;
                    newEnd = t + duration - 1;
                elseif t > mutatedIndividual.irrigationEnd(closestRegion, j)
                    % 延后结束时间
                    newEnd = t;
                    newStart = t - duration + 1;
                else
                    continue; % t 已被覆盖，无需调整
                end

                % 更新该区域的时间范围
                mutatedIndividual.irrigationStart(closestRegion, j) = newStart;
                mutatedIndividual.irrigationEnd(closestRegion, j) = newEnd;
            end
        end
    end
end
function mutatedIndividual = mutateDailyWater(mutatedIndividual, target, donor1, donor2, F, params)
    mutatedIndividual.dailyWater = target.dailyWater + round(F * (donor1.dailyWater - donor2.dailyWater)); % 支渠流量变异
    % 修复dailyWater，在0.4到1最大灌水量  
    mutatedIndividual.dailyWater = max(min(mutatedIndividual.dailyWater, params.maxWaterPerDayRegion), 0.4 * params.maxWaterPerDayRegion);   
end
function mutatedIndividual = mutateWheatRatio(mutatedIndividual, target, donor1, donor2, F, params)
    % 提取结构体中的数据   
    targetWheat = target.wheatRatio;  % 目标个体的每日灌溉量 (3D 矩阵)
    donor1Wheat = donor1.wheatRatio;  % 差分个体1的每日灌溉量
    donor2Wheat = donor2.wheatRatio;  % 差分个体2的每日灌溉量

    % 初始化变异结果
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
            
            % 2. 提取目标区域和轮期的 wheatRatio 数据
            targetWheatSegment = squeeze(targetWheat(regionIdx, periodIdx, targetRelStart:targetRelEnd));
            donor1WheatSegment = squeeze(donor1Wheat(regionIdx, periodIdx, donor1RelStart:donor1RelEnd));
            donor2WheatSegment = squeeze(donor2Wheat(regionIdx, periodIdx, donor2RelStart:donor2RelEnd));
            
            
            % 3. 调用 alignRelativePeriods 对 DailyWater 和 wheatRatio 数据变异
            mutatedWheatSegment = alignRelativePeriods(targetWheatSegment, donor1WheatSegment, donor2WheatSegment, F);
            mutatedWheatSegment = reshape(mutatedWheatSegment, 1, []);
            % 4. 填充变异后的数据
           
            % 如果变异后的长度超过目标范围，截断
            irrigationLength = mutatedIndividual.irrigationEnd(regionIdx, periodIdx) - mutatedIndividual.irrigationStart(regionIdx, periodIdx) + 1;
            if length(mutatedWheatSegment) > irrigationLength
                mutatedWheatSegment = mutatedWheatSegment(1:irrigationLength);
            elseif length(mutatedWheatSegment) < irrigationLength
                % 如果不足，补均值
                meanWheatValue = mean(mutatedWheatSegment, 'omitnan');
                addingWheatSegment = repmat(meanWheatValue, 1, irrigationLength - length(mutatedWheatSegment));
                mutatedWheatSegment = [mutatedWheatSegment, addingWheatSegment];
            end

            % 将变异后的结果更新到目标区域和轮期
            mutatedWheat(regionIdx, periodIdx, mutatedIndividualRelStart(regionIdx, periodIdx):mutatedIndividualRelEnd(regionIdx, periodIdx)) = mutatedWheatSegment;
        end
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

