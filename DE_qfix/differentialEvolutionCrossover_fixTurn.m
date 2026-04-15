function crossedPopulation = differentialEvolutionCrossover_fixTurn(mutatedPopulation, parentPopulation, Cr, params)
    % 主函数：对变异后的种群和父代种群进行交叉操作，并修复约束
    % 输入参数：
    % - mutatedPopulation：变异后的种群
    % - parentPopulation：父代种群
    % - Cr：交叉概率
    % - params：参数结构体，包含约束信息
    % 输出参数：
    % - crossedPopulation：交叉后的种群，试验种群

    % 初始化交叉后的种群
    populationSize = length(parentPopulation);
    crossedPopulation = parentPopulation;

    % 遍历种群中的每个个体
    for i = 1:populationSize
        % 执行二元交叉操作
        crossedIndividual = crossoverIndividual(mutatedPopulation(i), parentPopulation(i), Cr, params);

        % 修复约束条件
        crossedPopulation(i) = fixStageWaterConstraints(crossedIndividual, params);
        
        % 修复玉米的灌水比例
        crossedPopulation(i).maizeRatio = zeros(params.I, params.numStages, max(crossedPopulation(i).stageLengths));
        
        for j = 1:params.numStages
            for day = crossedPopulation(i).stageStart(j):crossedPopulation(i).stageEnd(j)
                if day < params.start_time_maize
                    crossedPopulation(i).maizeRatio(:, j, day - crossedPopulation(i).stageStart(j) + 1) = 0;
                elseif day <= params.end_time_wheat
                    crossedPopulation(i).maizeRatio(:, j, day - crossedPopulation(i).stageStart(j) + 1) = 1 - crossedPopulation(i).wheatRatio(:, j, day - crossedPopulation(i).stageStart(j) + 1);
                else
                    crossedPopulation(i).maizeRatio(:, j, day - crossedPopulation(i).stageStart(j) + 1) = 1;
                end
            end
        end
        
    end
end

function crossedIndividual = crossoverIndividual(mutatedIndividual, parentIndividual, Cr, params)
    % 工具函数：对单个个体执行交叉操作
    % 输入参数：
    % - mutatedIndividual：变异后的个体
    % - parentIndividual：父代个体
    % - Cr：交叉概率
    % 输出参数：
    % - crossedIndividual：交叉后的个体

    % 初始化交叉后的个体
    crossedIndividual = parentIndividual;

    % 随机选择一个必须交叉的索引（确保至少有一个参数发生交叉）
    numVariables = numel(mutatedIndividual.stageLengths);
    forcedIndex = randi(numVariables);

    % 遍历所有参数
    for j = 1:numVariables
        if rand < Cr || j == forcedIndex
            % 根据交叉概率选择变异个体的值
            crossedIndividual.stageLengths(j) = mutatedIndividual.stageLengths(j);
        end
    end
    for j = 1:numVariables - 1
        if rand < Cr || j == forcedIndex
            % 根据交叉概率选择变异个体的值
            crossedIndividual.stageIntervals(j) = mutatedIndividual.stageIntervals(j);
        end
    end
    % 检查并修复轮期长度和间隔总天数约束
    crossedIndividual = fixStageLengthsAndIntervals(crossedIndividual, params);
    % 轮期开始时间的交叉 --- 加权融合交叉
    crossedIndividual = CrossStageStart(crossedIndividual, mutatedIndividual, params);
    
    % 对灌溉时间段参数进行交叉，这一段应该返回灌溉开始时间和结束时间，但应该对灌溉时长进行交叉并修复
    mutatedIrrigationLength = zeros(params.I, params.numStages);
    crossedIrrigationLength = zeros(params.I, params.numStages);
    % 对灌溉持续时间进行交叉
    for k = 1:params.I
        for  stage = 1:params.numStages
            % 随机选择交叉的灌溉时长
            mutatedIrrigationLength(k, stage) = mutatedIndividual.irrigationEnd(k, stage) - mutatedIndividual.irrigationStart(k, stage) + 1;
            if rand < Cr || stage == forcedIndex
                crossedIrrigationLength(k, stage) = mutatedIrrigationLength(k, stage);
            end
        end
    end
    % 限制灌溉持续时间的最小值和最大值
    for stage = 1:params.numStages
        minIrrigationLength = ceil(crossedIndividual.stageLengths(stage) / 5);
        maxIrrigationLength = crossedIndividual.stageLengths(stage);
        crossedIrrigationLength = max(minIrrigationLength, min(maxIrrigationLength, crossedIrrigationLength));
    end
    % 对灌溉开始时间进行交叉，计算结束时间，并使其满足约束
    crossedIndividual= CrossIrrigationStartTime(crossedIndividual, mutatedIndividual, crossedIrrigationLength, params);
    
    % 对每日用水量和比例参数进行交叉
    crossedIndividual = crossDailyWaterandWheatRatio(crossedIndividual, parentIndividual, mutatedIndividual, Cr, params); % 对每日小麦和玉米的总灌水量/小麦的灌水比例进行变异，并使其在灌溉开始时间和结束时期之间
end
function individual = fixStageLengthsAndIntervals(individual, params)
    % 修复轮期长度和间隔的约束
    individual.stageLengths = min(max(individual.stageLengths, 10), 45); % 确保最小长度为10
    individual.stageIntervals = min(max(individual.stageIntervals, 10), 30); % 确保最小间隔为10
    totalLength = sum(individual.stageLengths) + sum(individual.stageIntervals);
    if totalLength > params.GPL
        % 超出总天数时，按比例缩放轮期长度和间隔
        scaleFactor = params.GPL / totalLength;
        individual.stageLengths = max(floor(individual.stageLengths * scaleFactor), 15); % 确保最小长度为15
        individual.stageIntervals = max(floor(individual.stageIntervals * scaleFactor), 10); % 确保最小间隔为10
        
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
function crossedIndividual = CrossStageStart(crossedIndividual, mutatedIndividual, params)
    % 对第一个轮期的起始时间进行变异
    % 输入参数：
    % - crossedIndividual: 待交叉的个体，需要它的总轮期长度和间隔
    % - mutatedIndividual: 变异后的个体
    % - params: 参数结构体，包含 GPL 等约束信息

    % 获取总轮期长度和间隔
    totalStageLength = sum(crossedIndividual.stageLengths);
    totalStageInterval = sum(crossedIndividual.stageIntervals);

    % 第一个轮期的起始时间范围
    minStartDay = 1;
    maxStartDay = params.GPL - totalStageLength - totalStageInterval + 1;

    % 加权交叉融合第一个轮期起始时间
    w = rand(); % 随机权重
    crossedIndividual.stageStart(1) = round(w * crossedIndividual.stageStart(1) + (1 - w) * mutatedIndividual.stageStart(1));

    % 修正第一个轮期的起始时间到合法范围
    crossedIndividual.stageStart(1) = max(min(crossedIndividual.stageStart(1), maxStartDay), minStartDay);

    % 更新后续轮期的起始时间
    for i = 2:length(crossedIndividual.stageLengths)
        crossedIndividual.stageStart(i) = crossedIndividual.stageStart(i - 1) + crossedIndividual.stageLengths(i - 1) + crossedIndividual.stageIntervals(i - 1);
    end
    for i = 1:length(crossedIndividual.stageLengths)
        crossedIndividual.stageEnd(i) = crossedIndividual.stageStart(i) + crossedIndividual.stageLengths(i) - 1;
    end
end
function crossedIndividual= CrossIrrigationStartTime(crossedIndividual, mutatedIndividual, IrrigationLength, params)
    for stage = 1:params.numStages
        stageStartJ = crossedIndividual.stageStart(stage);
        stageEndJ = crossedIndividual.stageEnd(stage);
        % 设置灌溉开始时间与轮期开始时间相同，并给予一定浮动
        maxStartFloat = stageEndJ - stageStartJ - IrrigationLength + 1; % 设定最大浮动天数
        % 加权交叉融合
        w = rand(); % 随机权重
        irrigationStartFixed = randi(params.I);
        for  k = 1:params.I
            crossedIndividual.irrigationStart(k, stage) = round(w * crossedIndividual.irrigationStart(k, stage) + (1 - w) * mutatedIndividual.irrigationStart(k, stage));
            crossedIndividual.irrigationStart(k, stage) = min(max(crossedIndividual.irrigationStart(k, stage), crossedIndividual.stageStart(stage)), ...
                crossedIndividual.stageStart(stage) + maxStartFloat(k, stage));
            if k == irrigationStartFixed
                 crossedIndividual.irrigationStart(k, stage) = crossedIndividual.stageStart(stage);
            end
        end
        % 根据变异后的灌溉长度确定灌溉结束时间
        crossedIndividual.irrigationEnd(:, stage) = crossedIndividual.irrigationStart(:, stage) + IrrigationLength(:, stage) - 1;

        % 确保灌溉结束时间在轮期结束前
        for  k = 1:params.I
            crossedIndividual.irrigationEnd(k, stage) = min(crossedIndividual.irrigationEnd(k, stage), stageEndJ);
        end
    end
    
    crossedstageStart = repmat(crossedIndividual.stageStart, params.I, 1);
    crossedIndividualRelStart = crossedIndividual.irrigationStart - crossedstageStart + 1; % 测试代码
    crossedIndividualRelEnd = crossedIndividual.irrigationEnd - crossedstageStart + 1;
    if any(crossedIndividualRelStart(:) <= 0)
        disp('crossedIndividualRelStart 包含0或负数，程序已暂停，请检查变量。');
        keyboard; % 进入调试模式，暂停程序
    end 
end
function crossedIndividual = crossDailyWaterandWheatRatio(crossedIndividual, parentIndividual, mutatedIndividual, Cr, params)
    % 提取结构体中的数据
    crossedIndividualWater = crossedIndividual.dailyWater;  % cross个体的每日灌溉量 (3D 矩阵)
    mutatedIndividualWater = mutatedIndividual.dailyWater;  % 子代个体的每日灌溉量
    
    crossedIndividualWheat = crossedIndividual.wheatRatio;  % cross个体的每日灌溉量 (3D 矩阵)
    mutatedIndividualWheat = mutatedIndividual.wheatRatio;  % 子代个体1的每日灌溉量
    
    % 初始化交叉结果 --- 每日灌水量与小麦的灌水比例
    crossedWater = zeros(params.I, params.numStages, max(crossedIndividual.stageLengths));
    crossedWheat = zeros(params.I, params.numStages, max(crossedIndividual.stageLengths));
    
    for regionIdx = 1:params.I
        for periodIdx = 1:params.numStages
            % 1. 计算轮期内的相对时间范围
            parentIndividualRelStart(regionIdx, periodIdx) = parentIndividual.irrigationStart(regionIdx, periodIdx) - parentIndividual.stageStart(periodIdx) + 1;
            parentIndividualRelEnd(regionIdx, periodIdx) = parentIndividual.irrigationEnd(regionIdx, periodIdx) - parentIndividual.stageStart(periodIdx) + 1;
            
            mutatedIndividualRelStart(regionIdx, periodIdx) = mutatedIndividual.irrigationStart(regionIdx, periodIdx) - mutatedIndividual.stageStart(periodIdx) + 1;
            mutatedIndividualRelEnd(regionIdx, periodIdx) = mutatedIndividual.irrigationEnd(regionIdx, periodIdx) - mutatedIndividual.stageStart(periodIdx) + 1;
            
            crossedIndividualRelStart(regionIdx, periodIdx) = crossedIndividual.irrigationStart(regionIdx, periodIdx) - crossedIndividual.stageStart(periodIdx) + 1;
            crossedIndividualRelEnd(regionIdx, periodIdx) = crossedIndividual.irrigationEnd(regionIdx, periodIdx) - crossedIndividual.stageStart(periodIdx) + 1;
            
            % 2. 提取目标区域和轮期的 DailyWater 和 wheatRatio 数据
            parentIndividualWaterSegment = squeeze(crossedIndividualWater(regionIdx, periodIdx, parentIndividualRelStart(regionIdx, periodIdx):parentIndividualRelEnd(regionIdx, periodIdx)));
            mutatedIndividualWaterSegment = squeeze(mutatedIndividualWater(regionIdx, periodIdx, mutatedIndividualRelStart(regionIdx, periodIdx):mutatedIndividualRelEnd(regionIdx, periodIdx)));
            
            parentIndividualWheatSegment = squeeze(crossedIndividualWheat(regionIdx, periodIdx, parentIndividualRelStart(regionIdx, periodIdx):parentIndividualRelEnd(regionIdx, periodIdx)));
            mutatedIndividualWheatSegment = squeeze(mutatedIndividualWheat(regionIdx, periodIdx, mutatedIndividualRelStart(regionIdx, periodIdx):mutatedIndividualRelEnd(regionIdx, periodIdx)));
                        
            % 3. 调用 alignRelativePeriods 对 DailyWater 和 wheatRatio 数据交叉
            crossedWaterSegment = alignRelativePeriods(parentIndividualWaterSegment, mutatedIndividualWaterSegment, Cr);
            crossedWheatSegment = alignRelativePeriods(parentIndividualWheatSegment, mutatedIndividualWheatSegment, Cr);
            
            crossedWaterSegment = reshape(crossedWaterSegment, 1, []);
            crossedWheatSegment = reshape(crossedWheatSegment, 1, []);

            % 4. 填充交叉后的数据 
            % 如果变异后的长度超过目标范围，截断
            irrigationLength = crossedIndividual.irrigationEnd(regionIdx, periodIdx) - crossedIndividual.irrigationStart(regionIdx, periodIdx) + 1;
            if length(crossedWaterSegment) > irrigationLength
                crossedWaterSegment = crossedWaterSegment(1:irrigationLength);
                crossedWheatSegment = crossedWheatSegment(1:irrigationLength);
            elseif length(crossedWaterSegment) < irrigationLength
                % 如果不足，补均值
                meanWaterValue = mean(crossedWaterSegment, 'omitnan');
                addingWaterSegment = repmat(meanWaterValue, 1, irrigationLength - length(crossedWaterSegment));
                crossedWaterSegment = [crossedWaterSegment, addingWaterSegment];
 
                meanWheatValue = mean(crossedWheatSegment, 'omitnan');
                addingWheatSegment = repmat(meanWheatValue, 1, irrigationLength - length(crossedWheatSegment));
                crossedWheatSegment = [crossedWheatSegment, addingWheatSegment];
            end

            % 将变异后的结果更新到目标区域和轮期
            crossedWater(regionIdx, periodIdx, crossedIndividualRelStart(regionIdx, periodIdx):crossedIndividualRelEnd(regionIdx, periodIdx)) = crossedWaterSegment;
            crossedWheat(regionIdx, periodIdx, crossedIndividualRelStart(regionIdx, periodIdx):crossedIndividualRelEnd(regionIdx, periodIdx)) = crossedWheatSegment;
        end
    end
    
    % 修复dailyWater，在0.4到1最大灌水量
    maxDailyWater= zeros(params.I, params.numStages, max(crossedIndividual.stageLengths)); % 提取最大灌水量
    for j = 1:params.numStages
        for k = 1:params.I
            % 提取当前轮期数据
            round_data = params.maxWaterPerDayRegion(k, crossedIndividual.irrigationStart(k, j):crossedIndividual.irrigationEnd(k, j));
            % 填充到结果矩阵中
            maxDailyWater(k, j, crossedIndividualRelStart(k, j):crossedIndividualRelEnd(k, j)) = round_data;
        end
    end
    crossedWater = max(min(crossedWater, maxDailyWater), 0.4 * maxDailyWater);   
    
    indices_between_0_and_100 = find(crossedWater(:) < 100 & crossedWater(:) > 0);
    if ~isempty(indices_between_0_and_100)
        disp('crossedIndividual.dailyWater contains values between 0 and 100. Entering debug mode...');
        disp('Indices of values between 0 and 100:');
        disp(indices_between_0_and_100); % 输出异常值的位置
        keyboard; % 进入调试模式
    end
        % 检查 dailyWater 中是否存在大于 1e10 的值
    indices_greater_than_1e10 = find(crossedWater(:) > 1e10);
    if ~isempty(indices_greater_than_1e10)
        disp('crossedIndividual.dailyWater contains values greater than 1e10. Entering debug mode...');
        disp('Indices of values greater than 1e10:');
        disp(indices_greater_than_1e10); % 输出异常值的位置
        keyboard; % 进入调试模式
    end
    
    % 修复wheatRatio，在 0 ~ 1 之间
    crossedWheat = max(min(crossedWheat, 1), 0); 
    for j = 1:params.numStages
        for day = crossedIndividual.stageStart(j):crossedIndividual.stageEnd(j)
            % 检查 day 是否在小麦生育期内
            if day > params.end_time_wheat
                % 生育期外，保持为 0
                crossedWheat(:, j, day - crossedIndividual.stageStart(j) + 1) = 0;
            end
        end
    end
    
    % 更新结果
    crossedIndividual.dailyWater = crossedWater;
    crossedIndividual.wheatRatio = crossedWheat;
        
end
function crossedSegment = alignRelativePeriods(parentIndividualSegment, mutatedindividualSegment, Cr)
    % 对齐 DailyWater 的长度
    maxLength = max([length(parentIndividualSegment), length(mutatedindividualSegment)]);
    crossedSegment = zeros(1, maxLength);
    
    % 如果不足，补齐为均值
    parentIndividualSegment = padWithMean(parentIndividualSegment, maxLength);
    mutatedindividualSegment = padWithMean(mutatedindividualSegment, maxLength);

    forcedIndexDay = randi(maxLength);

    for day = 1:maxLength
        % 进行交叉
        if rand < Cr || day == forcedIndexDay
            crossedSegment(day) = mutatedindividualSegment(day);
        else
            crossedSegment(day) = parentIndividualSegment(day);
        end
    end
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
