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
params.torigin = [30 80]; params.tending = [90 175]; params.Rootorigin = [0.2 0.3]; params.Rootending = [0.7 0.9]; % 根系生长有关的参数，初始根长与终了根长，单位为m，根系开始生长时间与根系结束生长时间
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
    params.(variableNames3{k}) = dataTable3{:, k}18
end

params.ratioWaterConsumption = load('E:\7-工作\02-论文\023-自己在写的论文2024\0231-202408\渠系输水优化\我自己的模型\input\ratio_of_water_turn.txt');
params.maxWaterPerStage_all = load('E:\7-工作\02-论文\023-自己在写的论文2024\0231-202408\渠系输水优化\我自己的模型\input\water_availability_turn.txt');

% 与约束相关的参数
params.numStages = 3; % 轮期数量
% 每天每个分区的小麦和玉米的最大净灌水量，0.71为支斗农渠的渠系水利用系数，0.9为田间水利用效率
params.maxWaterPerDayRegion = params.qd * 86400 * 0.71 * 0.9 .* [params.ratioWaterConsumption(:, 1) .* ones(1, params.start_time_maize - 1),...
    params.ratioWaterConsumption(:, 2) .* ones(1, params.end_time_wheat - params.start_time_maize + 1),...
    params.ratioWaterConsumption(:, 3) .* ones(1, params.GPL - params.end_time_wheat)];
% 每个轮期的最大可用水量，这里第一列为轮期为3，第二列轮期为4，假设斗农渠水利用效率为0.77，田间水利用效率为0.9，小麦玉米耗水占比0.78
params.maxWaterPerStage_all = params.maxWaterPerStage_all * 0.77 * 0.9 * 0.78; 
% 每天小麦和玉米的总最大净灌水量,假设干支斗农水利用效率为0.641，田间水利用效率为0.9，每天小麦和玉米占总耗水的比例为0.76
params.maxWaterPerDay = params.Qgd * 86400 * 0.641 * 0.9 * 0.76; 

%% 差分进化主体

p1 = 0.1;  p2 = 0.3;  p3 = 0.6;  %p4 = 0.25;   % 多目标权重 

DE_params.num_obj = 3;                    num_obj = DE_params.num_obj;     % 目标函数的数量
DE_params.NIND = 50 * DE_params.num_obj;  NIND = DE_params.NIND;           % 个体数目
DE_params.Maxgen = 1000;                   Maxgen = DE_params.Maxgen;       % 最大遗传代数
M=fix(NIND/num_obj);  % 取整，使M为整数，有几个目标函数，就将种群分为几等份，种群1用来计算f1，种群2用来计算f2，...

trace1 = zeros(Maxgen,6);    trace2 = zeros(Maxgen,7);    trace3 = zeros(Maxgen,6);

% 差分进化参数，F为动态调整因子，用于控制变异的程度， Cr为变异概率
F = 1; Cr = 0.7; 

v = v_generate_fixTurn(NIND, params); % 生成初始种群
V1 = v;
 %%
 Vchild = DEMutation_fixTurn_version3(v, F, params); % 变异 
 Vcross = DECrossover_fixTurn_version3(Vchild, v, Cr, params); % 交叉

%%
for gen = 1: Maxgen
    gen
    % 通过单目标的计算，形成新的种群--为多目标的初始种群
    % 个体分组
    VsubParent1 = V1(1:M);  VsubParent2 = V1(M + 1: 2 * M);  VsubParent3 = V1(2 * M + 1: 3 * M);  %VsubParent4 = V1(3 * M + 1: 4 * M);
    % 计算单目标的函数值，其中f3为目标值越大越好，f1能耗、f2水量损失、f4灌水量为目标值越小越好
    f1_parent = newobj1(VsubParent1, params);
    f2_parent = newobj2(VsubParent2, params);
    f3_parent = newobj3(VsubParent3, params);

    % 分组个体变异
    VsubMut1 = DEMutation_fixTurn_version3(VsubParent1, F, params); 
    VsubMut2 = DEMutation_fixTurn_version3(VsubParent2, F, params); 
    VsubMut3 = DEMutation_fixTurn_version3(VsubParent3, F, params);  

    % 分组个体交叉产生试验个体
    VsubTrial1 = DECrossover_fixTurn_version3(VsubMut1, VsubParent1, F, params); 
    VsubTrial2 = DECrossover_fixTurn_version3(VsubMut2, VsubParent2, F, params); 
    VsubTrial3 = DECrossover_fixTurn_version3(VsubMut3, VsubParent3, F, params); 

    % 分组试验个体适应度计算
    f1_Trial = newobj1(VsubTrial1, params);
    f2_Trial = newobj2(VsubTrial2, params);
    f3_Trial = newobj3(VsubTrial3, params);

    % 选择1（父代个体Vsub1_1与 试验个体Vsub1_3的比较）
    VsubNext1 = differentialEvolutionSelection(VsubTrial1, VsubParent1, f1_Trial, f1_parent);
    VsubNext2 = differentialEvolutionSelection(VsubTrial2, VsubParent2, f2_Trial, f2_parent);
    VsubNext3 = differentialEvolutionSelection(VsubTrial3, VsubParent3, f3_Trial, f3_parent);
  
    % 新的种群---对于多目标
    VtotalParent = [VsubNext1, VsubNext2, VsubNext3];
    % 计算多目标的适应度
        f1_MultiTrial = newobj1(VtotalParent, params);
        f2_MultiTrial = newobj2(VtotalParent, params);
        f3_MultiTrial = newobj3(VtotalParent, params);

        [trace1(gen, 1), location1(gen, 1)] = min(f1_MultiTrial);
        [trace1(gen, 2), location1(gen, 2)] = max(f1_MultiTrial);
        [trace1(gen, 3), location1(gen, 3)] = min(f2_MultiTrial);
        [trace1(gen, 4), location1(gen, 4)] = max(f2_MultiTrial);
        [trace1(gen, 5), location1(gen, 5)] = min(f3_MultiTrial);
        [trace1(gen, 6), location1(gen, 6)] = max(f3_MultiTrial);

         f_parent = p1 * ((f1_MultiTrial - trace1(gen, 1)) / (trace1(gen, 2) - trace1(gen, 1))) ...
                  + p2 * ((f2_MultiTrial - trace1(gen, 3)) / (trace1(gen, 4) - trace1(gen, 3))) ...
                  + p3 * ((f3_MultiTrial - trace1(gen, 5)) / (trace1(gen, 6) - trace1(gen, 5)));
    % 变异
    VtotalMut = DEMutation_fixTurn_version3(VtotalParent, F, params);
    % 交叉
    VtotalTrial = DECrossover_fixTurn_version3(VtotalMut, VtotalParent, F, params);
    % 交叉适应度计算
        f1_MultiTrial = newobj1(VtotalTrial, params);
        f2_MultiTrial = newobj2(VtotalTrial, params);
        f3_MultiTrial = newobj3(VtotalTrial, params);

        [trace2(gen, 1), location2(gen, 1)] = min(f1_MultiTrial);
        [trace2(gen, 2), location2(gen, 2)] = max(f1_MultiTrial);
        [trace2(gen, 3), location2(gen, 3)] = min(f2_MultiTrial);
        [trace2(gen, 4), location2(gen, 4)] = max(f2_MultiTrial);
        [trace2(gen, 5), location2(gen, 5)] = min(f3_MultiTrial);
        [trace2(gen, 6), location2(gen, 6)] = max(f3_MultiTrial);

        f_trial =  p1 * ((f1_MultiTrial - trace2(gen, 1)) / (trace2(gen, 2) - trace2(gen, 1))) ...
                 + p2 * ((f2_MultiTrial - trace2(gen, 3)) / (trace2(gen, 4) - trace2(gen, 3))) ...
                 + p3 * ((f3_MultiTrial - trace2(gen, 5)) / (trace2(gen, 6) - trace2(gen, 5)));
     % 选择1
     % Vnext = differentialEvolutionSelection(VtotalTrial, VtotalParent, f_trial, f_parent);
    
     % 选择2
     Vnext = DESelection_version3(VtotalTrial, VtotalParent, f_trial, f_parent);
     
     % 提取最好值，为了画图
     f1_final = newobj1(Vnext, params);
     f2_final = newobj2(Vnext, params);
     f3_final = newobj3(Vnext, params);

     [trace3(gen, 1), location3(gen, 1)] = min(f1_final);
     [trace3(gen, 2), location3(gen, 2)] = max(f1_final);
     [trace3(gen, 3), location3(gen, 3)] = min(f2_final);
     [trace3(gen, 4), location3(gen, 4)] = max(f2_final);
     [trace3(gen, 5), location3(gen, 5)] = min(f3_final);
     [trace3(gen, 6), location3(gen, 6)] = max(f3_final);

     Vtrace1(gen) = Vnext(location3(gen,1)); % 提取f1_final的最小值对应的决策变量值
     Vtrace2(gen) = Vnext(location3(gen,3)); % 提取f2_final的最小值对应的决策变量值
     Vtrace3(gen) = Vnext(location3(gen,5)); % 提取f3_final的最大值对应的决策变量值

     f_final = p1 * ((f1_final - trace3(gen,1))/(trace3(gen,2) - trace3(gen,1))) ...
             + p2 * ((f2_final - trace3(gen,3))/(trace3(gen,4) - trace3(gen,3))) ...
             + p3 * ((f3_final - trace3(gen,5))/(trace3(gen,6) - trace3(gen,5)));
         
     [trace3(gen,9), location3(gen,9)] = min(f_final);
     
     Vtrace5(gen) = Vnext(location3(gen,9));  % 提取标准化f33333的最小值对应的决策变量值（每一代的最优值）到Vtrace5
     f1_best(gen) = f1_final(location3(gen,9));
     f2_best(gen) = f2_final(location3(gen,9));
     f3_best(gen) = f3_final(location3(gen,9));
     
     % 定义保留的精英个体数量
     num_elites = 3; % 设定需要保留的精英个体数量
     
     % 记录当前代的最优个体及适应度
     if gen == 1
         % 初始化精英个体
         [~, sorted_indices] = sort(f_final); % 按适应度从小到大排序
         elite_individuals = Vnext(:, sorted_indices(1:num_elites)); % 记录前 num_elites 个精英个体
         elite_fitnesses = f_final(sorted_indices(1:num_elites)); % 记录精英个体对应的适应度
         elite_fitnesses = elite_fitnesses(:)'; % 转为行向量
     else
         % 比较当前代和上一代的精英个体
         [~, sorted_indices] = sort(f_final);
         current_elite_individuals = Vnext(:, sorted_indices(1:num_elites)); % 当前代的精英个体
         current_elite_fitnesses = f_final(sorted_indices(1:num_elites)); % 当前代的精英适应度
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
     [~, worst_indices] = sort(f_final, 'descend'); % 按适应度从大到小排序，找到最差的个体
     Vnext(:, worst_indices(1:num_elites)) = elite_individuals; % 用精英个体替换最差的个体

     V1 = Vnext;
end

%% 
figure(1);clf;
plot(trace3(:,9),'-');hold on;
plot(trace3(:,9),'.');
grid;
legend('标准化(f1 + f2 + f3)');
xlabel('迭代次数');ylabel('目标函数值');

figure(2);clf;
plot(newobj1(Vtrace5(:,:), params),'-');hold on;
plot(newobj1(Vtrace5(:,:), params),'.');
grid;
legend('对应f1真实值');
xlabel('迭代次数');ylabel('目标函数值');

figure(3);clf;
plot(newobj2(Vtrace5(:,:), params),'-');hold on;
plot(newobj2(Vtrace5(:,:), params),'.');
grid;
legend('对应f2真实值');
xlabel('迭代次数');ylabel('目标函数值');

figure(4);clf;
plot(newobj3(Vtrace5(:,:), params),'-'); hold on;
plot(newobj3(Vtrace5(:,:), params),'.');
grid;
legend('对应f3真实值');
xlabel('迭代次数');ylabel('目标函数值');

figure(6);clf;
plot(newobj1(V1, params)); hold on;
plot(newobj2(V1, params),'r-.'); grid;
plot(newobj3(V1, params),'g+'); grid;
legend('f1','f2','f3');
xlabel('个体数目编号');ylabel('目标函数值');
title('最终代种群目标函数值');

%%
object = zeros(1, 3);
save_data.variables = V1(138);
object(1) = f1_final(138);
object(2) = f2_final(138);  
object(3) = f3_final(138); 
save_data.object = object;
save('optimization_result.mat', 'save_data')

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
