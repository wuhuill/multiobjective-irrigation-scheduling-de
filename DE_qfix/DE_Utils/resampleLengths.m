function stageLengths = resampleLengths(numStages, params)
    % 重新采样轮期长度
    targetLengths = params.targetLengths{numStages};
    stageLengths = arrayfun(@(x) randi(targetLengths(x, :)), 1:numStages);
end
