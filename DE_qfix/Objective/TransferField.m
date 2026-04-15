function fieldResult = TransferField(Population, params, fieldName)
    % 通用函数，将指定字段的数据从阶段索引转换到整个 GPL 范围
    % 输入:
    % - Population: 种群数组
    % - params: 参数结构体，包含 I 和 GPL
    % - fieldName: 要处理的字段名 ('dailyWater'、'wheatRatio'、'maizeRatio')
    
    fieldResult = zeros(length(Population), params.I, params.GPL); % 初始化结果矩阵
    
    for i = 1:length(Population)
        for j = 1:params.numStages
            for day = Population(i).stageStart(j):Population(i).stageEnd(j)
                fieldResult(i, :, day) = Population(i).(fieldName)(:, j, day - Population(i).stageStart(j) + 1);
            end
        end
    end
end
