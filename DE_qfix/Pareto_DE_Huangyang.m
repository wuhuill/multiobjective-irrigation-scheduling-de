clc
clear
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
params.torigin = [30 80]; params.tending = [90 175]; params.Rootorigin = [0.2 0.3]; params.Rootending = [0.9 1]; % 根系生长有关的参数，初始根长与终了根长，单位为m，根系开始生长时间与根系结束生长时间
params.PHU = [1850 2030]; params.Tb = [2 8]; params.TO = [22 26];
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
params.end_time_maize = find(maize_cumulative_HU >= params.PHU(2), 1)+params.start_time_maize-1; % 找到累计积温达到全生育期所需总积温的天数

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

DE_params.num_obj = 5;                     num_obj = DE_params.num_obj;     % 目标函数的数量
DE_params.NIND = 40 * DE_params.num_obj;   NIND = DE_params.NIND;           % 个体数目
DE_params.Maxgen = 400;                    Maxgen = DE_params.Maxgen;       % 最大遗传代数

% 差分进化参数，F为动态调整因子，用于控制变异的程度， Cr为变异概率
F = 1;      Cr = 0.75; 

Yieldmax = load('Yieldmax.mat');

v = v_generate_fixTurn_Pareto(NIND, params); % 生成初始种群
objectives = evaluateObjectives(v, params);
[nonDominationRanks, crowdingDistances] = fastNonDominatedSort(objectives);

% 初始化存储指标的变量
hypervolumeList = []; % 用于存储每一代的 HV 值
spreadList = [];      % 用于存储每一代的 Spread 值
generationHistory = []; % 用于存储每一代的目标值

% 设置参考点（适用于最小化问题）
referencePoint = max(objectives, [], 1) + 1; % 目标值的最大值加一个偏移量

V1 = v;
%%
for gen = 1: Maxgen
    
    gen
  
    % 变异
    Vmut = DEMutation_fixTurn_version3(V1, F, params); 

    % 交叉产生试验个体
    Vcross = DECrossover_fixTurn_version3(Vmut, V1, F, params); 

    % 试验个体适应度计算
    trialObjectives = evaluateObjectives(Vcross, params);
    
    % 选择（父代个体Vsub1_1与 试验个体Vsub1_3的比较）
    [Vnext, objectives] = selectionOperation(V1, Vcross, objectives, trialObjectives);
  
    % 非支配排序与拥挤度更新
    [nonDominationRanks, crowdingDistances] = fastNonDominatedSort(objectives);

    
    % 如果种群大小超过限制，基于拥挤距离选择解
    if length(Vnext) > NIND
        Vnext = selectBasedOnCrowding(Vnext, nonDominationRanks, crowdingDistances, popSize);
    end
    
    finalParetoFront = extractParetoFront(Vnext, objectives);
    
    % 获取帕累托前沿的目标值部分
    paretoObjectives = cat(1, finalParetoFront.Objectives); % 提取目标值矩阵

    % 计算 Hypervolume 指标
    hv = 0; % 初始化 HV
    for i = 1:size(paretoObjectives, 1)
        hv = hv + prod(referencePoint - paretoObjectives(i, :)); % 计算超体积
    end
    hypervolumeList = [hypervolumeList; hv]; % 存储当前代的 HV 值
    
    % 计算 Spread 指标
    distances = sqrt(sum(diff(sortrows(paretoObjectives)).^2, 2)); % 相邻点之间的欧氏距离
    meanDistance = mean(distances);
    spread = sum(abs(distances - meanDistance)) / (length(distances) * meanDistance);
    spreadList = [spreadList; spread]; % 存储当前代的 Spread 值

    % 输出当前代的指标值
    fprintf('Generation %d: HV = %.4f, Spread = %.4f\n', gen, hv, spread);
    
    % 保存每代的目标值
    generationHistory = [generationHistory; objectives];   
    
    % 绘制目标值变化
%     figure(1);
%     clf;
%     hold on;
%     plot(generationHistory(:, 1), 'r', 'LineWidth', 2);  % 第一个目标
%     plot(generationHistory(:, 2), 'g', 'LineWidth', 2);  % 第二个目标
%     plot(generationHistory(:, 3), 'b', 'LineWidth', 2);  % 第三个目标
%     title('Objective Values Over Generations');
%     xlabel('Generation');
%     ylabel('Objective Value');
%     legend('Objective 1', 'Objective 2', 'Objective 3');
%     drawnow;
    
    V1 = Vnext;
end

%% 
paretoObjectives = abs(finalParetoFront.Objectives);

% 绘制三维帕累托前沿
figure(1);clf;
scatter3(paretoObjectives(:, 1), paretoObjectives(:, 2), paretoObjectives(:, 3), 50, 'b', 'filled');
xlabel('Objective 1');
ylabel('Objective 2');
zlabel('Objective 3');
title('Pareto Front (3 Objectives)');
grid on;

% 绘制最后一代的所有解
single_objective(:, 1) = newobj1(V1, params);  
single_objective(:, 2) = newobj2(V1, params);
single_objective(:, 3) = abs(newobj3(V1, params));
% 绘制三维所有目标值
figure(2);clf;
scatter3(single_objective(:, 1), single_objective(:, 2), single_objective(:, 3), 50, 'b', 'filled');
xlabel('Objective 1');
ylabel('Objective 2');
zlabel('Objective 3');
title('Pareto Front (3 Objectives)');
grid on;


% 绘制 Hypervolume 和 Spread 的变化曲线
figure(3);clf;
subplot(2, 1, 1);
plot(1:Maxgen, hypervolumeList, 'b-o', 'LineWidth', 1.5);
title('Hypervolume Across Generations');
xlabel('Generation');
ylabel('Hypervolume');

subplot(2, 1, 2);
plot(1:Maxgen, spreadList, 'r-o', 'LineWidth', 1.5);
title('Spread Across Generations');
xlabel('Generation');
ylabel('Spread');


