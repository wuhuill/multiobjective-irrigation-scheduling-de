function [results] = run_crop_model(weather, irrigation, params)
% RUN_CROP_MODEL 单季作物生长模拟（土壤水分平衡 + 生物量/产量）
%
% 输入：
%   weather - 结构体，包含字段：
%       .Temp   : 逐日平均气温 (℃)，列向量
%       .RN     : 逐日净辐射 (MJ/m2/d)，列向量
%       .EP     : 逐日有效降水量 (mm)，列向量
%       .ET0    : 逐日参考蒸散量 (mm)，列向量
%   irrigation - 逐日灌水量 (mm)，列向量，长度与 weather 相同
%   params - 作物参数结构体，包含：
%       .Tb          : 基温 (℃)
%       .PHU         : 全生育期所需热单元 (℃·d)
%       .TO          : 最适温度 (℃)
%       .ab1, .ab2   : LAI 发育参数
%       .LAImax      : 最大叶面积指数
%       .HUI0        : 热单元指数阈值（LAI 下降起始点）
%       .ad          : LAI 下降形状参数
%       .BE          : 光能利用效率 ((kg/ha)/(MJ/m2))
%       .HI          : 收获指数
%       .Kc          : 逐日作物系数，列向量（长度与 weather 相同）
%       .torigin     : 根系开始生长天数 (d)
%       .tiending    : 根系停止生长天数 (d)
%       .Rootorigin  : 初始根深 (m)
%       .Rootending  : 最大根深 (m)
%       .fieldcapacity : 田间持水量 (cm3/cm3)
%       .wilting     : 凋萎系数 (cm3/cm3)
%       .theta0      : 初始土壤含水量 (cm3/cm3)
%
% 输出：
%   results - 结构体，包含：
%       .theta   : 逐日土壤含水量 (cm3/cm3)
%       .ETa     : 逐日实际蒸散量 (mm)
%       .Bio     : 逐日累积生物量 (kg/ha)
%       .Yield   : 最终产量 (kg/ha)
%       .Straw   : 最终秸秆量 (kg/ha)
%       .Ksw     : 逐日水分胁迫系数
%       .LAI     : 逐日叶面积指数


    %% 提取输入数据
    Temp = weather.Temp(:);
    RN   = weather.RN(:);
    EP   = weather.EP(:);
    ET0  = weather.ET0(:);
    IQ   = irrigation(:);
    GPL  = length(Temp);

    %% 预分配
    theta = zeros(GPL,1);
    ETa   = zeros(GPL,1);
    Ksw   = zeros(GPL,1);
    LAI   = zeros(GPL,1);
    Bio   = zeros(GPL,1);

    %% 根深
    Root = zeros(GPL,1);
    for t = 1:GPL
        Root(t) = Crop_Root(t, params.torigin, params.tiending, ...
                            params.Rootorigin, params.Rootending);
    end

    %% 热单元指数 HUI（限制不超过1）
    HU = max(0, Temp - params.Tb);
    HUI = cumsum(HU) / params.PHU;
    HUI = min(HUI, 1);   % 关键：限制最大为1

    %% 逐日循环
    for t = 1:GPL
        % 水分胁迫系数
        if t == 1
            theta_prev = params.theta0;
        else
            theta_prev = theta(t-1);
        end
        Ksw(t) = Crop_Ksw(params.fieldcapacity, params.wilting, theta_prev);

        % 温度胁迫系数
        KTS = max(0, sin(pi/2 * (Temp(t) - params.Tb) / (params.TO - params.Tb)));
        REG = min(KTS, Ksw(t));
        REG = max(0, REG);   % 确保非负

        % 叶面积指数 LAI
        HUF = max(0, HUI(t) / (HUI(t) + exp(params.ab1 - params.ab2 * HUI(t))));
        if t == 1
            delta_HUF = HUF;
            LAI(t) = delta_HUF * params.LAImax * (1 - exp(-5 * params.LAImax)) * sqrt(REG);
            LAI(t) = max(0, min(params.LAImax, LAI(t)));   % 限制范围
            LAI_max_act = LAI(t);
        else
            delta_HUF = max(0, HUF - HUF_prev);
            if HUI(t) < params.HUI0
                % 上升阶段：防止超调导致负数
                LAI_prev = min(LAI(t-1), params.LAImax);   % 限制前一时刻不超过LAImax
                exp_term = exp(5 * (LAI_prev - params.LAImax));
                inc = delta_HUF * params.LAImax * (1 - exp_term) * sqrt(REG);
                LAI(t) = LAI(t-1) + inc;
                LAI(t) = max(0, min(params.LAImax, LAI(t)));
                LAI_max_act = max(LAI_max_act, LAI(t));
            else
                % 下降阶段：防止底数为负
                ratio = (1 - HUI(t)) / (1 - params.HUI0);
                ratio = max(0, ratio);   % 关键：确保非负
                LAI(t) = LAI_max_act * (ratio ^ params.ad);
                LAI(t) = max(0, min(params.LAImax, LAI(t)));
            end
        end
        HUF_prev = HUF;

        % 光合有效辐射 PAR 和生物量增量
        PAR = 0.5 * RN(t) * (1 - exp(-0.65 * LAI(t)));
        delta_Bio = params.BE * PAR * REG;
        if t == 1
            Bio(t) = delta_Bio;
        else
            Bio(t) = Bio(t-1) + delta_Bio;
        end

        % 实际蒸散发
        if isempty(params.Kc)
            Kc_t = 1.0;
        else
            Kc_t = params.Kc(min(t, numel(params.Kc)));
        end
        ETa(t) = Kc_t * Ksw(t) * ET0(t);

        % 土壤水分平衡
        if t == 1
            [theta(t), ~] = Soil_Water(theta_prev, EP(t), IQ(t), ETa(t), ...
                Root(t), Root(t), params.fieldcapacity, params.theta0);
        else
            [theta(t), ~] = Soil_Water(theta_prev, EP(t), IQ(t), ETa(t), ...
                Root(t), Root(t-1), params.fieldcapacity, params.theta0);
        end
    end

    %% 最终产量和秸秆
    Yield = params.HI * Bio(end);
    Straw = 0.9 * (Bio(end) - Yield);

    %% 打包输出
    results.theta = theta;
    results.ETa   = ETa;
    results.Bio   = Bio;
    results.Yield = Yield;
    results.Straw = Straw;
    results.Ksw   = Ksw;
    results.LAI   = LAI;
end

% -------------------------------------------------------------------------
% 子函数（Crop_Ksw, Crop_Root, Soil_Water 与原相同，略）
function Kswi = Crop_Ksw(fieldcapacity, wilting, theta)
    if theta >= 0.9 * fieldcapacity
        Kswi = 1;
    elseif theta < wilting
        Kswi = 0;
    else
        Kswi = (theta - wilting) / (0.9 * fieldcapacity - wilting);
    end
end

function Rooti = Crop_Root(t, torigin, tending, Rootorigin, Rootending)
    if t <= torigin
        Rooti = Rootorigin;
    elseif t > tending
        Rooti = Rootending;
    else
        Rooti = Rootorigin + (Rootending - Rootorigin) / (tending - torigin) * (t - torigin);
    end
end

function [theta_next, Drain] = Soil_Water(theta_now, EP, IQ, ETa, Root_now, Root_prev, fieldcapacity, theta0)
    S_prev = theta_now * Root_now * 1000;
    S_inc  = theta0 * (Root_now - Root_prev) * 1000;
    S_new  = S_prev + S_inc + EP + IQ - ETa;
    S_max  = fieldcapacity * Root_now * 1000;
    Drain  = max(0, S_new - S_max);
    S_new  = min(S_new, S_max);
    theta_next = S_new / (Root_now * 1000);
    theta_next = max(theta_next, 0);
end