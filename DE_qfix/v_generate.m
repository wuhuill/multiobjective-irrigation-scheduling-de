function population = v_generate(populationSize, params)
% 初始种群生成
% numStages : 轮期 
% stageLengths: 轮期长度
% stageIntervals : 轮期间隔
% irrigationStart : 每个区域的灌溉开始时间
% irrigationEnd : 每个区域的灌溉结束时间
% dailyWater : 轮期内每个区域每天的小麦和玉米的总净灌水量
% wheatRatio : 小麦占dailyWater的比例

maxDays = params.GPL;   numRegions = params.I;
maxWaterPerDayRegion = params.maxWaterPerDayRegion;  % 每天每个分区的小麦和玉米的最大净灌水量，
maxWaterPerDay = params.maxWaterPerDay; % 每个轮期的最大可用水量，
maxWaterPerStage_all = params.maxWaterPerStage_all;  % 每天小麦和玉米的总最大净灌水量

population = struct('numStages', [], 'stageLengths', [], 'stageIntervals', [], ...
    'irrigationStart', [], 'irrigationEnd', [], ...
    'dailyWater', [], 'wheatRatio', []);
    
% 主循环：生成满足条件的每一个个体
for i = 1:populationSize
    
    validIndividual = false;
    while ~validIndividual
        % 随机选择轮期数量为3或4
        numStages = 3 + (rand() > 0.8);  % 80% chance for 3 stages
        
        % Select max water per stage based on the number of stages
        maxWaterPerStage = maxWaterPerStage_all(:, numStages - 2);
        
        % 重复尝试生成满足条件的轮期和间隔
        isValidLengths = false;
        while ~isValidLengths
            % 生成轮期的天数和间隔天数）
            if  numStages == 3
                targetLengths = [18, 27; 25, 35; 25, 32]; % 三个轮期的长度范围
                targetIntervals = [10, 30]; % 间隔天数的范围
            else
                targetLengths = [9, 11; 17, 23; 17, 23; 17, 23]; % 四个轮期的长度范围
                targetIntervals = [5, 15]; % 间隔天数的范围
            end
            
            % 生成轮期长度和间隔长度
            stageLengths = arrayfun(@(x) randi(targetLengths(x, :)), 1:numStages);
            stageIntervals = arrayfun(@(x) randi(targetIntervals), 1:numStages - 1);

            % 检查轮期和间隔的总天数是否小于maxDays
            if sum(stageLengths) + sum(stageIntervals) <= maxDays
                isValidLengths = true;
            end
        end
        
        % 随机选择第一个轮期的开始时间（可以不从第1天开始）
        stageStart = zeros(1, numStages);
        stageEnd = zeros(1, numStages);
        stageStart(1) = randi([1, maxDays - sum(stageLengths) - sum(stageIntervals) + 1]); % 保证总天数不超限
        
        % 计算每个轮期的开始和结束时间
        for j = 1:numStages
            if j > 1
                stageStart(j) = stageEnd(j - 1) + stageIntervals(j - 1) + 1;
            end
            stageEnd(j) = stageStart(j) + stageLengths(j) - 1;
        end
        
        % 初始化灌溉参数
        irrigationStart = zeros(numRegions, numStages); % 每个分区灌溉开始时间
        irrigationEnd = zeros(numRegions, numStages);   % 每个分区灌溉结束时间
        dailyWater = zeros(numRegions, numStages, max(stageLengths));
        wheatRatio = zeros(numRegions, numStages, max(stageLengths));
        maizeRatio = zeros(numRegions, numStages, max(stageLengths));
        
        validIrrigation = true;
        
        % 遍历每个轮期和区域，生成灌溉方案
        for j = 1:numStages
            
            % 随机选择两个不同的区域编号
            regionStartFixed = randi(numRegions);  % 随机选择一个区域的 irrigationStart 为 stageStart
            regionEndFixed = randi(numRegions);    % 随机选择一个区域的 irrigationEnd 为 stageEnd
            
            for k = 1:numRegions
                minDuration = ceil(stageLengths(j)/5);  % 最小灌溉持续时间为轮期的1/5

                if k == regionStartFixed
                    irrigationStart(k, j) = stageStart(j); % 这个区域的 irrigationStart 固定为 stageStart
                    irrigationEnd(k, j) = min(stageEnd(j), stageStart(j) + minDuration - 1 + randi([0, stageEnd(j) - stageStart(j) - minDuration + 1])); % 确保 irrigationEnd 不会超出 stageEnd(j) 的范围
                elseif k == regionEndFixed
                    irrigationEnd(k, j) = stageEnd(j); % 这个区域的 irrigationEnd 固定为 stageEnd
                    irrigationStart(k, j) = max(stageStart(j), stageEnd(j) - minDuration + 1 - randi([0, stageEnd(j) - stageStart(j) - minDuration + 1])); % 确保 irrigationStart 不会超出 stageEnd(j) 的范围   
                else
                    % 其他区域随机选择灌溉开始和结束时间，保证持续时间大于轮期的1/5
                    % 确保 irrigationStart 和 irrigationEnd 在范围内
                    irrigationStart(k, j) = randi([stageStart(j), max(stageStart(j), stageEnd(j) - minDuration + 1)]);
                    irrigationEnd(k, j) = min(stageEnd(j), irrigationStart(k, j) + minDuration - 1 + randi([0, stageEnd(j) - irrigationStart(k, j) - minDuration + 1]));
                end
                
                % 确定灌溉期间的每日用水量和小麦玉米的用水比例
                for day = irrigationStart(k, j):irrigationEnd(k, j)
                    dailyWater(k, j, day - stageStart(j) + 1) = (0.4 + 0.6 * rand) * maxWaterPerDayRegion(k, day);
                    if day < params.start_time_maize
                        wheatRatio(k, j, day - stageStart(j) + 1) = 1;
                        maizeRatio(k, j, day - stageStart(j) + 1) = 0;
                    elseif day <= params.end_time_wheat
                        wheatRatio(k, j, day - stageStart(j) + 1) = rand();
                        maizeRatio(k, j, day - stageStart(j) + 1) = 1 - wheatRatio(k, j, day - stageStart(j) + 1);
                    else
                        wheatRatio(k, j, day - stageStart(j) + 1) = 0;
                        maizeRatio(k, j, day - stageStart(j) + 1) = 1;
                    end
                end
   
            end
        end
        
        % 检查约束条件
        % （1）轮期内每天的总灌水量在0.6-1.2倍的设计总灌水量之间
        totalWaterPerDay = zeros(numStages, maxDays);
        for j = 1:numStages
            for day = stageStart(j):stageEnd(j)
                totalWaterPerDay(j, day) = sum(dailyWater(:, j, day - stageStart(j) + 1));
                if totalWaterPerDay(j, day) > 1.2 * maxWaterPerDay  %|| totalWaterPerDay (j, day) < 0.6 * maxWaterPerDay 
                    validIrrigation = false;
                    break;
                end
            end
            if ~validIrrigation
                break;
            end
        end
        
        % （2）每个轮期的总灌水量不超过最大可用水量
        if validIrrigation
            totalWater = sum(totalWaterPerDay, 2);
            for j = 1:numStages
                if totalWater(j) > maxWaterPerStage (j)
                    validIrrigation = false;
                    break;
                end
            end
        end

        % 如果所有约束都满足，保存个体信息
        if validIrrigation
            population(i).numStages = numStages;
            population(i).stageStart = stageStart;
            population(i).stageEnd = stageEnd;
            population(i).stageLengths = stageLengths;
            population(i).stageIntervals = stageIntervals;
            population(i).irrigationStart = irrigationStart;
            population(i).irrigationEnd = irrigationEnd;
            population(i).dailyWater = dailyWater;
            population(i).wheatRatio = wheatRatio;
            population(i).maizeRatio = maizeRatio;
            
            validIndividual = true;
        end
    end
end
end






