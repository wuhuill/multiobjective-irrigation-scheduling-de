function [V1, paretoObjectives, paretoSolutions, objectives, single_objective, hypervolumeList, spreadList] = Pareto_DE(params, DE_params, optimalIndividual) 

num_obj = DE_params.num_obj;     % 目标函数的数量
NIND = DE_params.NIND;           % 个体数目
Maxgen = DE_params.Maxgen;       % 最大遗传代数
F = DE_params.F;
Cr = DE_params.Cr;
% 差分进化参数，F为动态调整因子，用于控制变异的程度， Cr为交叉概率


Yieldmax = load('Yieldmax.mat');

v = v_generate_fixTurn_Pareto(NIND, params, optimalIndividual); % 生成初始种群
% v = v_generate_fixTurn_Pareto_version2(NIND, params); % 生成初始种群
objectives = evaluateObjectives(v, params);

[nonDominationRanks, crowdingDistances] = Copy_of_fastNonDominatedSort(objectives);

% 初始化存储指标的变量
hypervolumeList = []; % 用于存储每一代的 HV 值
spreadList = [];      % 用于存储每一代的 Spread 值
generationHistory = []; % 用于存储每一代的目标值

% 设置参考点（找最劣解，对于最小化问题，找最大值）
referencePoint = [-3.5 * 10^8  5 * 10^7  -0.001]; % 目标值的最小值加一个偏移量

V1 = v;
%%
for gen = 1: Maxgen
    
    gen
    
    F = 0.5 + 0.3 * exp( - gen / Maxgen);  % 早期搜索广，后期收敛快
    Cr = 0.9 - 0.3 * (gen / Maxgen);  % 早期较随机，后期稳定
    % 变异
    Vmut = DEMutation_fixTurn_version3(V1, F, params); 

    % 交叉产生试验个体
    Vcross = DECrossover_fixTurn_version3(Vmut, V1, Cr, params); 

    % 试验个体适应度计算
    trialObjectives = evaluateObjectives(Vcross, params);
    
    % 选择（父代个体Vsub1_1与 试验个体Vsub1_3的比较）
    [Vnext, objectives] = selectionOperation(V1, Vcross, objectives, trialObjectives);
  
    % 非支配排序与拥挤度更新
    [nonDominationRanks, crowdingDistances] = Copy_of_fastNonDominatedSort(objectives);
    
    % 如果种群大小超过限制，基于拥挤距离选择解
    if length(Vnext) > NIND
        Vnext = selectBasedOnCrowding(Vnext, nonDominationRanks, crowdingDistances, popSize);
    end
    
    finalParetoFront = extractParetoFront(Vnext, objectives);
    
    % 获取帕累托前沿的目标值部分
    paretoObjectives = cat(1, finalParetoFront.Objectives); % 提取目标值矩阵
    paretoSolutions = finalParetoFront.Solutions;  % 提取解矩阵
    
    % 计算 Hypervolume 指标
    hv = 0; % 初始化 HV
%     for i = 1:size(paretoObjectives, 1)
%         hv = hv + prod(referencePoint - paretoObjectives(i, :)); % 计算超体积
%     end
    hv = hypervolume(paretoObjectives, referencePoint);
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
    
    % 绘制三维帕累托前沿
%     figure(1);
%     clf;
%     hold on;
%     scatter3(objectives(:, 1), objectives(:, 2), objectives(:, 3), 50, 'b', 'filled');
%     xlabel('Objective 1');
%     ylabel('Objective 2');
%     zlabel('Objective 3');
%     view(3); % 设置默认 3D 视角
%     grid on;
%     drawnow;
%     
%     % 绘制三维帕累托前沿
%     figure(2);
%     clf;
%     hold on;
%     scatter3(paretoObjectives(:, 1), paretoObjectives(:, 2), paretoObjectives(:, 3), 50, 'b', 'filled');
%     xlabel('Objective 1');
%     ylabel('Objective 2');
%     zlabel('Objective 3');
%     view(3); % 设置默认 3D 视角
%     grid on;
%     drawnow;
     
    V1 = Vnext;
end

%% 
paretoObjectives = abs(finalParetoFront.Objectives);
paretoSolutions = finalParetoFront.Solutions;

single_objective(:, 1) = abs(newobj1(V1, params));  
single_objective(:, 2) = newobj2(V1, params);
single_objective(:, 3) = abs(newobj3(V1, params));


end




