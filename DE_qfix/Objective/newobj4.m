function f4=newobj4(v,params)
%NEWOBJ1 最小化灌水量
% 模型运行本身需要的参数，实际测量得到
% 与作物/产量相关的参数 （小麦、玉米）
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
torigin=params.torigin;    tending=params.tending;   Rootorigin=params.Rootorigin;      Rootending=params.Rootending; % 根系生长有关的参数，单位为m
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
I=params.I;% 支渠条数
A=params.A; m_canal=params.m_canal; l=params.l;% 计算支渠流量损失的参数
qd=params.qd;% 支渠的设计流量，m3/s
Qgd=params.Qgd;% 干渠的设计流量，m3/s
Ag=params.Ag; lg=params.lg; mg=params.mg; % 计算干渠流量损失的参数
% 每条渠的小麦/玉米的控制面积，单位为ha
Area_wheat = params.Area_wheat; 
Area_maize = params.Area_maize; 

% 初始化的参数
% 每日的小麦和玉米的总净灌水量
dailyWater = TransferField(v, params, 'dailyWater');
% 小麦和玉米占区域总净灌水的比例 
RatioAll = [params.ratioWaterConsumption(:, 1) .* ones(1, params.start_time_maize - 1),...
    params.ratioWaterConsumption(:, 2) .* ones(1, params.end_time_wheat - params.start_time_maize + 1),...
    params.ratioWaterConsumption(:, 3) .* ones(1, params.GPL - params.end_time_wheat)];
RatioAll = repmat(RatioAll, 1, 1, length(v));
RatioAll = permute(RatioAll, [3, 1, 2]);

f4 = zeros(length(v),1);

% 支渠流量
    qz = dailyWater ./ RatioAll / (86400 * 0.9 * 0.71) ; % 每条支渠每天的净流量 [length(v, 1), I, GPL]  ET占比 田间水利用效率 斗渠和农渠输水效率    
    m_canal_expanded = reshape(m_canal, [1, I, 1]); % 确保 m_canal 的维度与 qz 匹配
    qzs = (reshape(A,[1, I, 1]) .* reshape(l,[1, I, 1])) .* (qz.^ (1 - m_canal_expanded)) / 100;
    qzm = qz + qzs; % [length(v, 1), I, GPL]  计算每条支渠每天的毛流量
% 干渠流量
    Qg = squeeze(sum(qzm, 2)); % [length(v, 1), GPL]  计算干渠的净流量（所有支渠毛流量之和）
    Qgs = Ag * lg * Qg .^ (1 - mg) / 100;
    Qgm = Qgs + Qg;

% 目标计算
    f4 = sum(Qgm * 86400, 2);
    
    if any(f4 > 1e10)
       disp('f4 contains values greater than 10^10. Entering debug mode...');
       keyboard;
    end
end
    
