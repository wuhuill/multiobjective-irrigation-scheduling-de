clc;
clear;
%% 定义结构体（该模型中所使用全局变量）
% 气象参数
params = struct(); % 初始化结构体
filePath1 = 'E:\7-工作\02-论文\023-自己在写的论文2024\0231-202408\渠系输水优化\我自己的模型\input\weather.txt'; % 设定文件路径
dataTable1 = readtable(filePath1, 'Delimiter', '\t');% 读取文件内容为表格
variableNames1 = {'Temp', 'RN', 'EP', 'ET0'};% 定义变量名称
% 动态生成结构体字段并赋值
for k = 1:length(variableNames1)
    % 为每个自定义变量名创建结构体字段并赋值
    params.(variableNames1{k}) = dataTable1{:, k};
end

% 土壤参数
params.fieldcapacity = 0.28 ; params.wilting= 0.10 ; params.thetaorigin = 0.168; % 体积含水率,cm3/cm3

% 与作物/产量相关的参数 （小麦、玉米）
params.torigin = [30 80]; params.tending = [90 175]; params.Rootorigin = [0.25 0.3]; params.Rootending = [0.9 1]; % 根系生长有关的参数，初始根长与终了根长，单位为m，根系开始生长时间与根系结束生长时间
params.PHU = [1850 2030]; params.Tb = [2 8]; params.TO = [20 26];
params.ab1 = [15.01 15.03]; params.ab2 =[50.95 60.95];
params.LAImax = [4.8 5.5]; params.HUI0 = [0.51 0.8];  params.ad = [0.75 0.8];
params.BE = [37 40]; params.HI = [0.45 0.5];

params.start_time_wheat = 1 ;   % 小麦生育期开始时间
params.start_time_maize = 45 ;  % 玉米生育期开始时间

% 小麦的生育期结束时间
wheat_HU = max(0, params.Temp - params.Tb(1));  % 如果温度低于基温，则积温为0 
wheat_cumulative_HU = cumsum(wheat_HU);  % 计算积温的累积值
params.end_time_wheat = find(wheat_cumulative_HU >= params.PHU(1), 1); % 找到累计积温达到全生育期所需总积温的天数

% 玉米的生育期结束时间
maize_HU = max(0, params.Temp - params.Tb(2));  % 如果温度低于基温，则积温为0 
maize_cumulative_HU = cumsum(maize_HU(params.start_time_maize:end));  % 计算积温的累积值
params.end_time_maize = find(maize_cumulative_HU >= params.PHU(2), 1) + params.start_time_maize - 1; % 找到累计积温达到全生育期所需总积温的天数

params.GPL= max(params.end_time_wheat,params.end_time_maize); % 总作物的生长期长度

filePath2 = 'E:\7-工作\02-论文\023-自己在写的论文2024\0231-202408\渠系输水优化\我自己的模型\input\Kc.txt';
dataTable2 = readtable(filePath2, 'Delimiter', '\t');% 读取文件内容为表格
variableNames2 = {'Kc_wheat', 'Kc_maize'};% 定义变量名称
for k = 1:length(variableNames2)
    % 为每个自定义变量名创建结构体字段并赋值
    params.(variableNames2{k}) = dataTable2{:, k};
end

%渠系参数
params.I = 8;% 支渠条数
params.Qgd = 18;% 干渠的设计流量，m3/s
params.Ag = 3.4; params.lg = 8.41; params.mg = 0.5; %计算干渠流量损失的参数
params.bg_dk = 2.5; params.mg_bp = 1.5; params.ig_pd = 1/15000; params.ng_cl = 0.022; % 干渠横断面参数
filePath3 = 'E:\7-工作\02-论文\023-自己在写的论文2024\0231-202408\渠系输水优化\我自己的模型\input\canal.txt';
dataTable3 = readtable(filePath3, 'Delimiter', '\t');% 读取文件内容为表格
variableNames3 = {'Index', 'A','m_canal','l','qd','Area_wheat','Area_maize','b_dk','m_bp','i_pd','n_cl','gate_weight'};% 定义变量名称（计算支渠流量损失的参数、支渠的设计流量m3/s、支渠小麦/玉米的面积ha,支渠的设计参数）
for k = 1:length(variableNames3)
    % 为每个自定义变量名创建结构体字段并赋值
    params.(variableNames3{k}) = dataTable3{:, k};
end

params.ratioWaterConsumption = load('E:\7-工作\02-论文\023-自己在写的论文2024\0231-202408\渠系输水优化\我自己的模型\input\ratio_of_water_turn.txt');
params.maxWaterPerStage_all = load('E:\7-工作\02-论文\023-自己在写的论文2024\0231-202408\渠系输水优化\我自己的模型\input\water_availability_turn.txt');

% 与约束相关的参数
params.numStages = 3; % 轮期数量
% 每天每个分区的小麦和玉米的最大净灌水量，0.71为支斗农渠的渠系水利用系数，0.9为田间水利用效率
% params.maxWaterPerDayRegion = params.qd * 86400 * 0.71 * 0.9 .* [params.ratioWaterConsumption(:, 1) .* ones(1, params.start_time_maize - 1),...
%     params.ratioWaterConsumption(:, 2) .* ones(1, params.end_time_wheat - params.start_time_maize + 1),...
%     params.ratioWaterConsumption(:, 3) .* ones(1, params.GPL - params.end_time_wheat)];
params.maxWaterPerDayRegion = params.qd * 86400 * 0.71 * 0.9 .* params.ratioWaterConsumption;
% 每个轮期的最大可用水量，这里第一列为轮期为3，第二列轮期为4，假设斗农渠水利用效率为0.77，田间水利用效率为0.9，小麦玉米耗水占比0.78
params.maxWaterPerStage_all = params.maxWaterPerStage_all * 0.77 * 0.9 * 0.78; 
% 每天小麦和玉米的总最大净灌水量,假设干支斗农水利用效率为0.641，田间水利用效率为0.9，每天小麦和玉米占总耗水的比例为0.76
params.maxWaterPerDay = params.Qgd * 86400 * 0.641 * 0.9 * 0.76; 

%% 差分进化主体

DE_params.num_obj = 3;                    num_obj = DE_params.num_obj;     % 目标函数的数量
DE_params.NIND = 40 * DE_params.num_obj;  NIND = DE_params.NIND;           % 个体数目
DE_params.Maxgen = 300;                   Maxgen = DE_params.Maxgen;       % 最大遗传代数
M=fix(NIND/num_obj);  % 取整，使M为整数，有几个目标函数，就将种群分为几等份，种群1用来计算f1，种群2用来计算f2，...

trace1 = zeros(Maxgen,6);    trace2 = zeros(Maxgen,7);    trace3 = zeros(Maxgen,6);

% 差分进化参数，F为动态调整因子，用于控制变异的程度， Cr为变异概率
F = 1; Cr = 0.7; 

v = v_generate_fixTurn_Pareto(NIND, params); % 生成初始种群
V1 = v;
f1 = newobj3(V1, params);
 %%
 Vchild = DEMutation_fixTurn_version3(v, F, params); % 变异 
 Vcross = DECrossover_fixTurn_version3(Vchild, v, Cr, params); % 交叉

%%
for gen = 1: Maxgen
    gen
    % 通过单目标的计算，形成新的种群--为多目标的初始种群
    % 个体分组
    % 计算单目标的函数值，其中f3为目标值越大越好，f1能耗、f2水量损失为目标值越小越好
    f1_parent = newobj3(V1, params);

    % 个体变异
    VsubMut1 = DEMutation_fixTurn_version3(V1, F, params); 

    % 个体交叉产生试验个体
    VsubTrial1 = DECrossover_fixTurn_version3(VsubMut1, V1, F, params); 

    % 试验个体适应度计算
    f1_Trial = newobj3(VsubTrial1, params);

    % 选择1（父代个体Vsub1_1与 试验个体Vsub1_3的比较）
%     if gen <= 100
%         Vnext = differentialEvolutionSelection(VsubTrial1, V1, f1_Trial, f1_parent);
%     else
%         Vnext = DESelection_version3(VsubTrial1, V1, f1_Trial, f1_parent);
%     end
    
%     % 选择2
    Vnext = differentialEvolutionSelection(VsubTrial1, V1, f1_Trial, f1_parent);
    
    f1_final = newobj3(Vnext, params);
    
%     % 定义保留的精英个体数量
     num_elites = 3; % 设定需要保留的精英个体数量
     
     % 记录当前代的最优个体及适应度
     if gen == 1
         % 初始化精英个体
         [~, sorted_indices] = sort(f1_final); % 按适应度从小到大排序
         elite_individuals = Vnext(:, sorted_indices(1:num_elites)); % 记录前 num_elites 个精英个体
         elite_fitnesses = f1_final(sorted_indices(1:num_elites)); % 记录精英个体对应的适应度
         elite_fitnesses = elite_fitnesses(:)'; % 转为行向量
     else
         % 比较当前代和上一代的精英个体
         [~, sorted_indices] = sort(f1_final);
         current_elite_individuals = Vnext(:, sorted_indices(1:num_elites)); % 当前代的精英个体
         current_elite_fitnesses = f1_final(sorted_indices(1:num_elites)); % 当前代的精英适应度
         current_elite_fitnesses = current_elite_fitnesses(:)'; % 转为行向量
         
         % 更新精英池（取当前和历史的最优个体）
         combined_individuals = [elite_individuals, current_elite_individuals];
         combined_fitnesses = [elite_fitnesses, current_elite_fitnesses];
         
         % 按适应度重新排序，保留前 num_elites 个个体
         [~, combined_sorted_indices] = sort(combined_fitnesses);
         elite_individuals = combined_individuals(:, combined_sorted_indices(1:num_elites));
         elite_fitnesses = combined_fitnesses(combined_sorted_indices(1:num_elites));
         elite_fitnesses = elite_fitnesses(:)'; % 转为行向量
     end
     
     % 替换下一代中的最差个体
     [~, worst_indices] = sort(f1_final, 'descend'); % 按适应度从大到小排序，找到最差的个体
     Vnext(:, worst_indices(1:num_elites)) = elite_individuals; % 用精英个体替换最差的个体
%     
    % 迭代中总群的最好值
    [trace3(gen, 1), location3(gen, 1)] = min(f1_final);
    Vtrace5(gen) = Vnext(location3(gen, 1));
    
    % 最后一代种群的适应度

     V1 = Vnext;
end

%% 

figure(2);clf;
plot(newobj3(Vtrace5(:,:), params),'-');hold on;
plot(newobj3(Vtrace5(:,:), params),'.');
grid;
legend('对应f1真实值');
xlabel('迭代次数');ylabel('目标函数值');

figure(6);clf;
plot(newobj3(V1, params)); 
legend('f1');
xlabel('个体数目编号');ylabel('目标函数值');
title('最终代种群目标函数值');


totalWater = squeeze(sum(sum(Vchild(1).dailyWater, 3),1));
totalWaterPerDay = zeros(params.numStages, params.GPL);
totalWaterPerDayRegion = zeros(params.I, params.GPL);
wheatRatio = zeros(params.I, params.GPL);

for j = 1: params.numStages
    for day = Vchild(1).stageStart(j): Vchild(1).stageEnd(j)
        totalWaterPerDayRegion(:, day) = Vchild(1).dailyWater(:, j, day - Vchild(1).stageStart(j) + 1);
    end
end
totalWaterPerDayRegion = totalWaterPerDayRegion';

for j = 1: params.numStages
    for day = Vchild(1).stageStart(j): Vchild(1).stageEnd(j)
        totalWaterPerDay(j, day) = sum(Vchild(1).dailyWater(:, j, day - Vchild(1).stageStart(j) + 1));
    end
end

for j = 1: params.numStages
    for day = Vchild(1).stageStart(j): Vchild(1).stageEnd(j)
        wheatRatio(:, day) = Vchild(1).wheatRatio(:, j, day - Vchild(1).stageStart(j) + 1);
    end
end
wheatRatio = wheatRatio';
