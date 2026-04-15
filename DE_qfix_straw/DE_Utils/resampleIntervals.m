function stageIntervals = resampleIntervals(numStages, params)
    % 重新采样轮期时间间隔
    targetIntervals = params.targetIntervals{numStages};
    stageIntervals = arrayfun(@(x) randi(targetIntervals), 1:numStages - 1);
end