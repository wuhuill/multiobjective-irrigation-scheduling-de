function  [totalWaterPerDayRegion, wheatRatioGPL, maizeRatioGPL] = Transfer(Population, params)
    % 将dailyWater 和 wheatRatio 转化为 params.I * param.GPL
    totalWaterPerDayRegion = zeros(length(Population), params.I, params.GPL); % 小麦和玉米每天的净灌水量
    wheatRatioGPL =  zeros(length(Population), params.I, params.GPL); % 小麦的灌水比例
    maizeRatioGPL =  zeros(length(Population), params.I, params.GPL); % 小麦的灌水比例
    for i = 1:length(Population)
        for j = 1:params.numStages
            for day = Population(i).stageStart(j): Population(i).stageEnd(j)
                totalWaterPerDayRegion(i, :, day) = Population(i).dailyWater(:, j, day - Population(i).stageStart(j) + 1);
                wheatRatioGPL(i, :, day) = Population(i).wheatRatio(:, j, day - Population(i).stageStart(j) + 1);
                maizeRatioGPL(i, :, day) = Population(i).maizeRatio(:, j, day - Population(i).stageStart(j) + 1);
            end
        end
    end
end

