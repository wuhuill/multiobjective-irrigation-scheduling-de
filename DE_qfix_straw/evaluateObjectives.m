function objectives = evaluateObjectives(population, params)
    % 获取种群规模和维度
    [numIndividuals] = length(population);
    numObjectives = 3;  % 假设有三个目标
    objectives = zeros(numIndividuals, numObjectives); % 存储目标值

        objectives(:, 1) = newobj1(population, params); % 计算第一个目标函数值（例如：秸秆热量）       
        objectives(:, 2) = newobj2(population, params); % 计算第二个目标函数值（例如：最小化流量损失）   
        objectives(:, 3) = newobj3(population, params); % 计算第三个目标函数值（例如：最大化水分生产力）
  
end

