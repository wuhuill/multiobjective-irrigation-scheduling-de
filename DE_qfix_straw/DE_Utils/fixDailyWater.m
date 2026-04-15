function dailyWater = fixDailyWater(dailyWater, Qgd)
    % 修复每日用水量约束（基于种群统计特性）
    totalWater = sum(dailyWater(:));
    if totalWater > 1.2 * Qgd
        dailyWater = dailyWater * (1.2 * Qgd / totalWater);
    end
end

