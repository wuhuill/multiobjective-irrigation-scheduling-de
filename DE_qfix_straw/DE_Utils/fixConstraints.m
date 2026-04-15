function [individual, violated] = fixConstraints(individual, params, numStages)
    % 修复所有约束条件，并返回是否存在违反约束的情况

    violated = false;

    % 1. 修复轮期长度和时间间隔的总天数约束
    totalDays = sum(individual.stageLengths) + sum(individual.stageIntervals);
    if totalDays > params.GPL
        violated = true;
        individual.stageLengths = resampleLengths(numStages, params);
        individual.stageIntervals = resampleIntervals(numStages, params);
    end

    % 2. 修复灌溉时间段约束（启发式优化）
    for j = 1:numStages
        for k = 1:params.I
            minDuration = ceil(individual.stageLengths(j) / 5);
            [individual.irrigationStart(k, j), individual.irrigationEnd(k, j)] = ...
                fixIrrigationTimes(individual.irrigationStart(k, j), ...
                                   individual.irrigationEnd(k, j), ...
                                   minDuration);
        end
    end

    % 3. 修复每日用水量约束（启发式规则+比例缩放）
    individual.dailyWater = fixDailyWater(individual.dailyWater, params.Qgd);

    % 4. 修复轮期总灌溉水量约束
    individual = fixStageWaterConstraints(individual, params, numStages);
end

