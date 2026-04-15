function expanded_dailyWater = TransferWater(Population, params)
    % 通用函数，将指定字段的数据从阶段索引转换到整个 GPL 范围
    % 输入:
    % - Population: 种群数组
    % - params: 参数结构体，包含 I 和 GPL
    % - fieldName: 要处理的字段名 ('dailyWater'、'wheatRatio'、'maizeRatio')
    
    expanded_dailyWater = zeros(length(Population), params.I, params.GPL); % 初始化结果矩阵
    
    % 填充结果矩阵
    for i = 1:length(Population)
        for j = 1:params.I
            for stage = 1:params.numStages
                % 获取当前渠和轮期的开始和结束时间
                start_day = Population(i).irrigationStart(j, stage);
                end_day = Population(i).irrigationEnd(j, stage);
                % 填充每日灌水量到对应天数
                expanded_dailyWater(i, j, start_day:end_day) = Population(i).dailyWater(j, stage) * ones(1, end_day - start_day + 1);
            end
        end
    end
       % expanded_dailyWater 是最终的 8x215 矩阵

end
