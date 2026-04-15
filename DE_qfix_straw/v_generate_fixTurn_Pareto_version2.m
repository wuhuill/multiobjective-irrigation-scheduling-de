function population = v_generate_fixTurn_Pareto_version2(populationSize, params)
% 初始种群生成
% stageLengths: 轮期长度
% stageIntervals : 轮期间隔
% irrigationStart : 每个区域的灌溉开始时间
% irrigationEnd : 每个区域的灌溉结束时间
% dailyWater : 轮期内每个区域每天的小麦和玉米的总净灌水量
% wheatRatio : 小麦占dailyWater的比例

maxDays = params.GPL;   numRegions = params.I; numStages = params.numStages;
maxWaterPerDayRegion = params.maxWaterPerDayRegion;  % 每天每个分区的小麦和玉米的最大净灌水量，
maxWaterPerDay = params.maxWaterPerDay; % 每个轮期的最大可用水量，
maxWaterPerStage_all = params.maxWaterPerStage_all;  % 每天小麦和玉米的总最大净灌水量


start_time_wheat=params.start_time_wheat ; end_time_wheat=params.end_time_wheat ; % 小麦生育期开始时间与结束时间
start_time_maize=params.start_time_maize ; end_time_maize=params.end_time_maize ; % 玉米生育期开始时间与结束时间
GPL= max(end_time_wheat,end_time_maize); % 总作物的生长期长度

% 作物生理参数
PHU=params.PHU;       Tb=params.Tb;    TO=params.TO;
ab1=params.ab1;       ab2=params.ab2;
LAImax=params.LAImax; HUI0=params.HUI0; ad=params.ad;
BE=params.BE;         HI= params.HI;

torigin=params.torigin; tending=params.tending; Rootorigin=params.Rootorigin; Rootending=params.Rootending; % 根系生长有关的参数，单位为m
Kc_wheat =params.Kc_wheat; Kc_maize=params.Kc_maize; % 与蒸散发有关的参数,每天是不一样的
% 气象参数
Temp = params.Temp; RN = params.RN ;EP =params.EP ; ET0 = params.ET0;
Temp_wheat=Temp(start_time_wheat:end_time_wheat); Temp_maize=Temp(start_time_maize:end_time_maize);
RN_wheat = RN(start_time_wheat:end_time_wheat);   RN_maize = RN(start_time_maize:end_time_maize);
EP_wheat = EP(start_time_wheat:end_time_wheat);   EP_maize = EP(start_time_maize:end_time_maize);
ET0_wheat = ET0(start_time_wheat:end_time_wheat); ET0_maize = ET0(start_time_maize:end_time_maize);
% 土壤参数
fieldcapacity = params.fieldcapacity; wilting= params.wilting; thetaorigin= params.thetaorigin; % 体积含水率

population = struct('stageLengths', [], 'stageIntervals', [], ...
    'irrigationStart', [], 'irrigationEnd', [], ...
    'dailyWater', [], 'wheatRatio', []);

% 主循环：生成满足条件的每一个个体
for i = 1:populationSize
%     if i <= 5 % 如果是第一个个体，将其设置为单目标最优个体（这里假设加入1个单目标最优个体）
%         population(i).stageStart = optimalIndividual(i).stageStart;
%         population(i).stageEnd = optimalIndividual(i).stageEnd;
%         population(i).stageLengths = optimalIndividual(i).stageLengths;
%         population(i).stageIntervals = optimalIndividual(i).stageIntervals;
%         population(i).irrigationStart = optimalIndividual(i).irrigationStart;
%         population(i).irrigationEnd = optimalIndividual(i).irrigationEnd;
%         population(i).dailyWater = optimalIndividual(i).dailyWater;
%         population(i).wheatRatio = optimalIndividual(i).wheatRatio;
%         population(i).maizeRatio = optimalIndividual(i).maizeRatio;
%     else
        validIndividual = false;
        while ~validIndividual
            
            % Select max water per stage based on the number of stages
            maxWaterPerStage = maxWaterPerStage_all;
            
            % 重复尝试生成满足条件的轮期和间隔
            isValidLengths = false;
            while ~isValidLengths
%                 % 生成轮期的天数和间隔天数）
%                 if  numStages == 3
%                     targetLengths = [15, 40; 15, 40; 15, 40]; % 三个轮期的长度范围
%                     targetIntervals = [10, 30]; % 间隔天数的范围
%                 else
%                     targetLengths = [9, 11; 17, 23; 17, 23; 17, 23]; % 四个轮期的长度范围
%                     targetIntervals = [5, 15]; % 间隔天数的范围
%                 end

                    if  numStages == 3
                        targetLengths = [15, 40; 15, 40; 15, 40]; % 三个轮期的长度范围
                        targetIntervals = [10, 30]; % 间隔天数的范围
                    elseif numStages == 4
                        targetLengths = [10, 25; 10, 25; 10, 25; 10, 25]; % 四个轮期的长度范围
                        targetIntervals = [5, 15]; % 间隔天数的范围
                    else
                        targetLengths = [5, 18; 5, 18; 5, 18; 5, 18; 5, 18]; % 四个轮期的长度范围
                        targetIntervals = [5, 13]; % 间隔天数的范围
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
            dailyWater = zeros(numRegions, numStages);      % 每个分区每个轮期的每天的灌水量，假设在整个轮期是不变的
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
                    
                    
                    dailyWater(k, j) = (0.4 + 0.6 * rand) * maxWaterPerDayRegion(k, j);
                    
                    % 确定灌溉期间的每日用水量和小麦玉米的用水比例
                    for day = irrigationStart(k, j):irrigationEnd(k, j)
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
            dailyWater_all = zeros(numRegions, numStages, max(stageLengths));
            for j = 1:numStages
                for k = 1:numRegions
                    dailyWater_all(k, j, (irrigationStart(k, j) - stageStart(j) + 1) : (irrigationEnd(k, j) - stageStart(j) + 1)) = dailyWater(k, j) * ones(1, irrigationEnd(k, j) - irrigationStart(k, j) + 1);
                end
            end

            totalWaterPerDay = zeros(numStages, maxDays);
            for j = 1:numStages
                for day = stageStart(j):stageEnd(j)
                    totalWaterPerDay(j, day) = sum(dailyWater_all(:, j, day - stageStart(j) + 1));
                    if totalWaterPerDay(j, day) > 1.2 * maxWaterPerDay
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
            
            %(3)粮食安全约束
            % 每条渠的小麦/玉米的控制面积，单位为ha
            Area_wheat = params.Area_wheat;
            Area_maize = params.Area_maize;
            Area_wheat_all = reshape(Area_wheat, [1, params.I]);
            Area_maize_all = reshape(Area_maize, [1, params.I]);
            
            expanded_dailyWater = zeros(params.I, params.GPL);
            expanded_wheatRatio = zeros(params.I, params.GPL);
            expanded_maizeRatio = zeros(params.I, params.GPL);
           
            % 每日的小麦和玉米的总净灌水量
            for j = 1:params.I
                for stage = 1:params.numStages
                    % 获取当前渠和轮期的开始和结束时间
                    start_day = irrigationStart(j, stage);
                    end_day = irrigationEnd(j, stage);
                    % 填充每日灌水量到对应天数
                    expanded_dailyWater(j, start_day:end_day) = dailyWater(j, stage) * ones(1, end_day - start_day + 1);
                end
            end
            
            for j = 1:params.numStages
                for day = stageStart(j):stageEnd(j)
                    expanded_wheatRatio( :, day) = wheatRatio(:, j, day - stageStart(j) + 1);
                    expanded_maizeRatio( :, day) = maizeRatio(:, j, day - stageStart(j) + 1);
                end
            end
            
            % 小麦和玉米占区域总净灌水的比例
            RatioAll = [params.ratioWaterConsumption(:, 1) .* ones(1, params.start_time_maize - 1),...
                params.ratioWaterConsumption(:, 2) .* ones(1, params.end_time_wheat - params.start_time_maize + 1),...
                params.ratioWaterConsumption(:, 3) .* ones(1, params.GPL - params.end_time_wheat)];
            RatioAll = repmat(RatioAll, 1, 1);
            %RatioAll = permute(RatioAll, [3, 1, 2]);
            
            % 每条渠的小麦/玉米的灌水量
            IQwheat = expanded_dailyWater .* expanded_wheatRatio ./ (10 * Area_wheat);
            IQmaize = expanded_dailyWater .* expanded_maizeRatio ./ (10 * Area_maize);
            wheat_Yield_unit = zeros(params.I, 1);  maize_Yield_unit = zeros(params.I, 1);
            
            for j = 1:params.I
                [wheat_Yield_unit(j), ~] = Crop_Yield(IQwheat(j, :),Temp_wheat,RN_wheat,EP_wheat,ET0_wheat,start_time_wheat,end_time_wheat,Tb(1),PHU(1),TO(1),ab1(1),ab2(1),LAImax(1),HUI0(1),ad(1),BE(1),HI(1),Kc_wheat,torigin(1),tending(1),Rootorigin(1),Rootending(1),thetaorigin,fieldcapacity,wilting);
                [maize_Yield_unit(j), ~] = Crop_Yield(IQmaize(j, :),Temp_maize,RN_maize,EP_maize,ET0_maize,start_time_maize,end_time_maize,Tb(2),PHU(2),TO(2),ab1(2),ab2(2),LAImax(2),HUI0(2),ad(2),BE(2),HI(2),Kc_maize,torigin(2),tending(2),Rootorigin(2),Rootending(2),thetaorigin,fieldcapacity,wilting);
                wheat_Yield (j) = wheat_Yield_unit(j) * Area_wheat(j);
                maize_Yield (j) = maize_Yield_unit(j) * Area_maize(j);
            end
            
            Yield_total = sum(wheat_Yield, 2) + sum(maize_Yield, 2);
            if Yield_total < 4.2e7
                validIrrigation = false;
            end
             
            % 如果所有约束都满足，保存个体信息
            if validIrrigation
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







