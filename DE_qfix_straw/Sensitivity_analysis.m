clc;
clear;

%% ================== 基准情景 ==================
hydrology = 2;   % 平水年
numturn   = 2;   % 轮期参数 (注意：你原始代码中 params.numStages = numturn + 2)

%% ================== 敏感性参数 ==================
ET0_factors  = [0.9, 0.95, 1.05, 1.1];
Kc_factors   = [0.9, 0.95, 1.05, 1.1];
HI_factors   = [0.9, 0.95, 1.05, 1.1];  % ±10% 扰动

%% ================== 读取基础参数（补齐缺失参数） ==================
params = struct();

% --- 1. 气象参数 ---
filePath1 = 'E:\7-工作\02-论文\023-自己在写的论文\0231-202408\渠系输水优化\我自己的模型\input\weather_3.txt';
dataTable1 = readtable(filePath1, 'Delimiter', '\t');
variableNames1 = {'Temp', 'RN', 'ET0'};
for k = 1:length(variableNames1)
    params.(variableNames1{k}) = dataTable1{:, k};
end

filePath2 = 'E:\7-工作\02-论文\023-自己在写的论文\0231-202408\渠系输水优化\我自己的模型\input\EP_hydrological.txt';
dataTable2 = readtable(filePath2, 'Delimiter', '\t');
params.EP = dataTable2{:, hydrology};

% --- 2. 土壤参数 ---
params.fieldcapacity = 0.32; 
params.wilting = 0.10; 
params.thetaorigin = 0.168;

% --- 3. 作物/产量参数 ---
params.torigin = [30 80]; params.tending = [90 175]; 
params.Rootorigin = [0.2 0.3]; params.Rootending = [0.9 1];
params.PHU = [1850 2030]; params.Tb = [2 8]; params.TO = [22 26];
params.ab1 = [15.01 15.03]; params.ab2 = [50.95 60.95];
params.LAImax = [4.8 5.5]; params.HUI0 = [0.51 0.8]; params.ad = [0.75 0.8];
params.BE = [37 40]; params.HI = [0.45 0.5];

params.start_time_wheat = 1;
params.start_time_maize = 45;

% 计算生育期结束时间
wheat_HU = max(0, params.Temp - params.Tb(1));
params.end_time_wheat = find(cumsum(wheat_HU) >= params.PHU(1), 1);

maize_HU = max(0, params.Temp - params.Tb(2));
maize_cum = cumsum(maize_HU(params.start_time_maize:end));
params.end_time_maize = find(maize_cum >= params.PHU(2), 1) + params.start_time_maize - 1;

params.GPL = max(params.end_time_wheat, params.end_time_maize);

% --- 4. Kc 参数 ---
filePath3 = 'E:\7-工作\02-论文\023-自己在写的论文\0231-202408\渠系输水优化\我自己的模型\input\Kc.txt';
dataTable3 = readtable(filePath3, 'Delimiter', '\t');
params.Kc_wheat = dataTable3{:, 1};
params.Kc_maize = dataTable3{:, 2};

% --- 5. 渠系参数 (补齐原始代码中的所有字段) ---
params.I = 8;          % 支渠条数
params.Qgd = 18;       % 干渠设计流量
params.Ag = 3.4; params.lg = 8.41; params.mg = 0.5; % 干渠损失参数
params.bg_dk = 2.5; params.mg_bp = 1.5; params.ig_pd = 1/15000; params.ng_cl = 0.022;

filePath4_canal = 'E:\7-工作\02-论文\023-自己在写的论文\0231-202408\渠系输水优化\我自己的模型\input\canal.txt';
dataTable4 = readtable(filePath4_canal, 'Delimiter', '\t');
% 匹配原始代码的 12 个字段
vNames4 = {'Index', 'A','m_canal','l','qd','Area_wheat','Area_maize','b_dk','m_bp','i_pd','n_cl','gate_weight'};
for k = 1:length(vNames4)
    params.(vNames4{k}) = dataTable4{:, k};
end

% --- 6. 轮期与水量约束计算 ---
filePath4 = sprintf('E:/7-工作/02-论文/023-自己在写的论文/0231-202408/渠系输水优化/我自己的模型/input/ratio_of_water_turnall_%d.txt', numturn);
filePath5 = sprintf('E:/7-工作/02-论文/023-自己在写的论文/0231-202408/渠系输水优化/我自己的模型/input/water_availability_turnall_%d.txt', numturn);
params.ratioWaterConsumption = load(filePath4);
params.maxWaterPerStage_all = load(filePath5);

params.numStages = numturn + 2;
params.maxWaterPerDayRegion = params.qd * 86400 * 0.71 * 0.9 .* params.ratioWaterConsumption;

% 自动确定水文年系数
if hydrology == 1
    ratio_hydrology = 1;
elseif hydrology == 2
    ratio_hydrology = 0.87;
else
    ratio_hydrology = 0.72;
end
params.maxWaterPerStage_all = params.maxWaterPerStage_all * 0.77 * 0.9 * 0.78 * ratio_hydrology;
params.maxWaterPerDay = params.Qgd * 86400 * 0.641 * 0.9 * 0.76;

%% --- DE 参数 ---
DE_params.num_obj = 5;
DE_params.NIND = 40 * DE_params.num_obj;
DE_params.Maxgen = 1000;
DE_params.F = 1;
DE_params.Cr = 0.75;

% 加载单目标参考解
optPath = sprintf('E:\\7-工作\\02-论文\\023-自己在写的论文\\0231-202408\\渠系输水优化\\我自己的模型\\DE_qfix_straw\\results\\optimalIndividual_%d_%d.mat', hydrology, numturn);
optimalIndividual = load(optPath);

%% ================== 敏感性分析循环 ==================
resultFolder = fullfile(pwd,'sensitivity_results','sensitivity');
if ~exist(resultFolder,'dir'), mkdir(resultFolder); end

% 定义一个辅助函数或直接循环调用
% 提示：为了代码简洁，这里可以使用统一的循环结构，但为了保持逻辑清晰，按你原来的结构补齐

factors = [ET0_factors; Kc_factors; HI_factors]; 

%% ---------- 1. ET0 ----------
for i = 1:length(ET0_factors)
    params_p = params;
    params_p.ET0 = params.ET0 * ET0_factors(i);
    [~, paretoObjectives] = Pareto_DE(params_p, DE_params, optimalIndividual);
    save(fullfile(resultFolder, sprintf('ET0_%0.2f.mat', ET0_factors(i))), 'paretoObjectives');
end

%% ---------- 2. 小麦 Kc ----------
for i = 1:length(Kc_factors)
    params_p = params;
    params_p.Kc_wheat = params.Kc_wheat * Kc_factors(i);
    [~, paretoObjectives] = Pareto_DE(params_p, DE_params, optimalIndividual);
    save(fullfile(resultFolder, sprintf('Kc_wheat_%0.2f.mat', Kc_factors(i))), 'paretoObjectives');
end

%% ---------- 3. 玉米 Kc ----------
for i = 1:length(Kc_factors)
    params_p = params;
    params_p.Kc_maize = params.Kc_maize * Kc_factors(i);
    [~, paretoObjectives] = Pareto_DE(params_p, DE_params, optimalIndividual);
    save(fullfile(resultFolder, sprintf('Kc_maize_%0.2f.mat', Kc_factors(i))), 'paretoObjectives');
end

%% ---------- 4. 小麦 HI ----------
for i = 1:length(HI_factors)
    params_p = params;
    params_p.HI(1) = params.HI(1) * HI_factors(i); 
    [~, paretoObjectives] = Pareto_DE(params_p, DE_params, optimalIndividual);
    save(fullfile(resultFolder, sprintf('HI_wheat_%0.2f.mat', HI_factors(i))), 'paretoObjectives');
end

%% ---------- 5. 玉米 HI ----------
for i = 1:length(HI_factors)
    params_p = params;
    params_p.HI(2) = params.HI(2) * HI_factors(i); 
    [~, paretoObjectives] = Pareto_DE(params_p, DE_params, optimalIndividual);
    save(fullfile(resultFolder, sprintf('HI_maize_%0.2f.mat', HI_factors(i))), 'paretoObjectives');
end

fprintf('敏感性分析运行完成，结果已保存至: %s\n', resultFolder);