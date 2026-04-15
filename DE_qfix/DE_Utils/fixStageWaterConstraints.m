function individual = fixStageWaterConstraints(individual, params, numStages)
    % 修复轮期的总用水量约束
    for j = 1:numStages
        totalWater = sum(individual.dailyWater(:, j, :), 'all');
        if totalWater > params.maxWaterPerStage_all(j)
            scaleFactor = params.maxWaterPerStage_all(j) / totalWater;
            individual.dailyWater(:, j, :) = individual.dailyWater(:, j, :) * scaleFactor;
        end
    end
end
