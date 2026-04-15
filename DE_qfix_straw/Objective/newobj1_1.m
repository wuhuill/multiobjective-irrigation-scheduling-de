function f1=newobj1(v,params)
%NEWOBJ1 流量波动最小
% 模型运行本身需要的参数，实际测量得到
% 与作物/产量相关的参数 （小麦、玉米）
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

%渠系参数
I = params.I;% 支渠条数
A = params.A; m_canal = params.m_canal; l = params.l;% 计算支渠流量损失的参数
qd = params.qd;% 支渠的设计流量，m3/s
Qgd = params.Qgd;% 干渠的设计流量，m3/s
Ag = params.Ag; lg = params.lg; mg = params.mg; % 计算干渠流量损失的参数
b_dk = params.b_dk; m_bp = params.m_bp; i_pd = params.i_pd; n_cl = params.n_cl;

b = repmat(b_dk', [length(v), 1, GPL]); % 各支渠渠段底宽
m = repmat(m_bp', [length(v), 1, GPL]); % 各支渠渠段边坡系数
S = repmat(i_pd', [length(v), 1, GPL]); % 各支渠渠段渠道坡度
n = repmat(n_cl', [length(v), 1, GPL]); % 各支渠渠段曼宁糙率

bg = params.bg_dk; mg_bp = params.mg_bp; ig = params.ig_pd; ng = params.ng_cl;
bg = bg * ones(length(v), GPL); mg_bp = mg_bp * ones(length(v), GPL) ; ig = ig * ones(length(v), GPL); ng = ng * ones(length(v), GPL);

gate_weight = repmat(params.gate_weight', [length(v), 1, GPL - 1]); eta = 0.9; % 各支渠闸门重
Wz_weight = 26186.16; % 总干渠闸门
% 每条渠的小麦/玉米的控制面积，单位为ha
Area_wheat = params.Area_wheat; 
Area_maize = params.Area_maize; 

% 每日的小麦和玉米的总净灌水量
dailyWater = TransferWater(v, params);

% 小麦和玉米占区域总净灌水的比例 
RatioAll = [params.ratioWaterConsumption(:, 1) .* ones(1, params.start_time_maize - 1),...
    params.ratioWaterConsumption(:, 2) .* ones(1, params.end_time_wheat - params.start_time_maize + 1),...
    params.ratioWaterConsumption(:, 3) .* ones(1, params.GPL - params.end_time_wheat)];
RatioAll = repmat(RatioAll, 1, 1, length(v));
RatioAll = permute(RatioAll, [3, 1, 2]);

% 初始化f1
f1 = zeros(length(v),1);

% 支渠流量
    qz = dailyWater ./ RatioAll / (86400 * 0.9 * 0.71) ; % 每条支渠每天的净流量 [length(v, 1), I, GPL]  ET占比 田间水利用效率 斗渠和农渠输水效率    
    m_canal_expanded = reshape(m_canal, [1, I, 1]); % 确保 m_canal 的维度与 qz 匹配
    qzs = (reshape(A,[1, I, 1]) .* reshape(l,[1, I, 1])) .* (qz.^ (1 - m_canal_expanded)) / 100;
    qzm = qz + qzs; % [length(v, 1), I, GPL]  计算每条支渠每天的毛流量
% 干渠流量
    Qg = squeeze(sum(qzm, 2)); % [length(v, 1), GPL]  计算干渠的净流量（所有支渠毛流量之和）
    Qgs = Ag * lg * Qg .^ (1 - mg) / 100;
    Qgm = Qgs + Qg;
    
% 目标计算,各支渠的能耗和加上干渠流量调节能耗
% 计算支渠和干渠的水深变化
   h_branch = compute_water_depth(qzm, b, m, S, n, 0.05);
   h_main = compute_water_depth(Qgm, bg, mg_bp, ig, ng, 0.05);
% 计算支渠和干渠的启闭高度差和能耗
   delta_h_branch = diff(h_branch, 1, 3);
   delta_h_main = diff(h_main, 1, 2);
   E_height_variation_branch = abs(delta_h_branch) .* gate_weight * 9.8 / eta;
   E_height_variation_main = abs(delta_h_main) * Wz_weight  * 9.8 / eta;
   % 总能耗计算
   f1_branch = sum(E_height_variation_branch, [2, 3]);
   f1_main = sum(E_height_variation_main, 2);
   f1 = f1_branch + f1_main;
   
   if any(f1 > 1e10)
       disp('f1 contains values greater than 10^10. Entering debug mode...');
       keyboard;
   end
   
   
   % 罚函数
   for i = 1:length(v)
       if any(Qgm(i, :) > 1.2 * params.Qgd)
           f1(i) = f1(i) + 1e10;
       end
       
%        totalNonZeroDaysInRange = 0;
%        % 标记非零天数
%        nonZeroDays = Qgm(i, :) > 0;
%        % 提取非零天数对应的配水量
%        nonZeroWater = Qgm(i, nonZeroDays);
%        totalNonZeroDays = size(nonZeroWater, 2);
%        % 在非零配水天数中统计 0 ~ 0.4 倍最大用水量的天数
%        daysInRange = sum(nonZeroWater <= 0.4 * params.Qgd);
%        % 累加所有渠道的满足条件的天数
%        totalNonZeroDaysInRange = totalNonZeroDaysInRange + daysInRange;
%        
%        if totalNonZeroDaysInRange > 0.6 * totalNonZeroDays
%            f1(i) = f1(i) + 1e10; % 添加罚分
%        end
   end
  
   maxWaterPerStage = params.maxWaterPerStage_all(:, params.numStages - 2); % 因为3个轮期是第一列，4个轮期是第二列
   for i = 1:length(v)
       for j = 1:params.numStages
           totalWater(i, j) = sum(v(i).dailyWater(:, j, :), 'all');
       end
   end
   for i = 1:length(v)
       if totalWater(i, :) > maxWaterPerStage
           f1(i) = f1(i) + 1e10;
       end
   end
   
end
   
   
function h_final = compute_water_depth(Q_target, b, m, S, n, tolerance)
    % 初始化
    max_iterations = 1000;       % 最大迭代次数
    damping_factor = 0.5;        % 阻尼系数
    iteration = 0;               % 迭代计数
    sqrt_S = sqrt(S);            % 提前计算 sqrt(S)
    factor = n ./ sqrt_S;        % 曼宁公式中不变的系数

    % 使用曼宁公式的反推值作为初始水深估计，避免初值过远导致的震荡或不收敛
    h = max((Q_target .* factor) .^ (3/5) ./ (b + m), 0); 
    h(Q_target == 0) = 0;        % 流量为0时，水深设为0
    converged = (Q_target == 0); % 初始化收敛标志

    % 主循环
    while any(~converged, 'all') && iteration < max_iterations
        iteration = iteration + 1; % 更新迭代次数

        % 计算截面积、湿周、液压半径和流量
        canal_Area = b .* h + m .* h.^2;
        P = b + 2 * h .* sqrt(1 + m.^2);
        R = canal_Area ./ P;
        Q_calc = (1 ./ n) .* canal_Area .* R .^ (2/3) .* sqrt_S;

        % 计算相对误差，并更新收敛状态
        relative_error = abs(Q_calc - Q_target) ./ (Q_target + eps); % 防止除0错误
        converged = (relative_error < tolerance) | (Q_target == 0);

        % 动态步长调整，仅更新未收敛位置
        update_indices = ~converged;
        step_size = min(1, max(0.1, relative_error(update_indices))); % 控制步长在[0.1, 1]之间

        % 更新水深，使用阻尼系数控制更新幅度，防止震荡
        h(update_indices) = h(update_indices) - damping_factor * step_size .* ...
                            (Q_calc(update_indices) - Q_target(update_indices)) ./ ...
                            (b(update_indices) + 2 * m(update_indices) .* h(update_indices));
    end

    % 检查是否达到最大迭代次数
    if iteration >= max_iterations
        warning('迭代未收敛，已达到最大迭代次数。');
    end

    h_final = h;
end




