function f3 = newobj3(v,params)
%NEWOBJ3 最大化水分生产力
% 模型运行本身需要的参数，实际测量得到
% 模型运行本身需要的参数，实际测量得到
% 与作物/产量相关的参数 （小麦、玉米）
start_time_wheat = params.start_time_wheat ; end_time_wheat = params.end_time_wheat ; % 小麦生育期开始时间与结束时间
start_time_maize = params.start_time_maize ; end_time_maize = params.end_time_maize ; % 玉米生育期开始时间与结束时间
GPL = max(end_time_wheat,end_time_maize); % 总作物的生长期长度

% 作物生理参数，两天
PHU = params.PHU;       Tb = params.Tb;    TO = params.TO;
ab1 = params.ab1;       ab2 = params.ab2;
LAImax = params.LAImax; HUI0 = params.HUI0; ad = params.ad;
BE = params.BE;         HI = params.HI;

torigin = params.torigin; tending = params.tending; Rootorigin = params.Rootorigin; Rootending = params.Rootending; % 根系生长有关的参数，单位为m
Kc_wheat = params.Kc_wheat; Kc_maize = params.Kc_maize; % 与蒸散发有关的参数,每天是不一样的
% 气象参数
Temp = params.Temp; RN = params.RN ;EP =params.EP ; ET0 = params.ET0;
Temp_wheat = Temp(start_time_wheat:end_time_wheat); Temp_maize = Temp(start_time_maize:end_time_maize);
RN_wheat = RN(start_time_wheat:end_time_wheat);     RN_maize = RN(start_time_maize:end_time_maize);
EP_wheat = EP(start_time_wheat:end_time_wheat);     EP_maize = EP(start_time_maize:end_time_maize);
ET0_wheat = ET0(start_time_wheat:end_time_wheat);   ET0_maize = ET0(start_time_maize:end_time_maize);
% 土壤参数
fieldcapacity = params.fieldcapacity; wilting = params.wilting; thetaorigin = params.thetaorigin; % 体积含水率
%渠系参数
I = params.I;% 支渠条数
A = params.A; m_canal = params.m_canal; l = params.l;% 计算支渠流量损失的参数
qd = params.qd;% 支渠的设计流量，m3/s
Qgd = params.Qgd;% 干渠的设计流量，m3/s
Ag = params.Ag; lg = params.lg; mg = params.mg; % 计算干渠流量损失的参数

% 每条渠的小麦/玉米的控制面积，单位为ha
Area_wheat = params.Area_wheat; 
Area_maize = params.Area_maize; 
Area_wheat_all = reshape(Area_wheat, [1, I, 1]);
Area_maize_all = reshape(Area_maize, [1, I, 1]);

% 初始化的参数
% 每日的小麦和玉米的总净灌水量
dailyWater = TransferWater(v, params);
wheatRatio = TransferField(v, params, 'wheatRatio');
maizeRatio = TransferField(v, params, 'maizeRatio');

% 小麦和玉米占区域总净灌水的比例 
RatioAll = [params.ratioWaterConsumption(:, 1) .* ones(1, params.start_time_maize - 1),...
    params.ratioWaterConsumption(:, 2) .* ones(1, params.end_time_wheat - params.start_time_maize + 1),...
    params.ratioWaterConsumption(:, 3) .* ones(1, params.GPL - params.end_time_wheat)];
RatioAll = repmat(RatioAll, 1, 1, length(v));
RatioAll = permute(RatioAll, [3, 1, 2]);

% 每条渠的小麦/玉米的灌水量
IQwheat = dailyWater .* wheatRatio ./ (10 * Area_wheat_all);
IQmaize = dailyWater .* maizeRatio ./ (10 * Area_maize_all);
wheat_Yield_unit = zeros(length(v),I);  maize_Yield_unit = zeros(length(v),I);
% 初始化f3
f3 = zeros(length(v),1);

% 支渠流量
    qz = dailyWater ./ RatioAll / (86400 * 0.9 * 0.71) ; % 每条支渠每天的净流量 [length(v, 1), I, GPL]  ET占比 田间水利用效率 斗渠和农渠输水效率    
    m_canal_expanded = reshape(m_canal, [1, I, 1]); % 确保 m_canal 的维度与 qz 匹配
    qzs = (reshape(A,[1, I, 1]) .* reshape(l,[1, I, 1])) .* (qz.^ (1 - m_canal_expanded)) / 100 * 0.5;
    qzm = qz + qzs; % [length(v, 1), I, GPL]  计算每条支渠每天的毛流量
% 干渠流量
    Qg = squeeze(sum(qzm, 2)); % [length(v, 1), GPL]  计算干渠的净流量（所有支渠毛流量之和）
    Qgs = Ag * lg * Qg .^ (1 - mg) / 100 * 0.3;
    Qgm = Qgs + Qg;
% 总用水量
    Water_total = squeeze(sum(Qgm * 86400, 2));
% 目标计算
for j = 1:length(v)
    for i = 1:I
        [wheat_Yield_unit(j, i),theta1] = Crop_Yield(IQwheat(j, i, :),Temp_wheat,RN_wheat,EP_wheat,ET0_wheat,start_time_wheat,end_time_wheat,Tb(1),PHU(1),TO(1),ab1(1),ab2(1),LAImax(1),HUI0(1),ad(1),BE(1),HI(1),Kc_wheat,torigin(1),tending(1),Rootorigin(1),Rootending(1),thetaorigin,fieldcapacity,wilting);
        [maize_Yield_unit(j, i),theta2] = Crop_Yield(IQmaize(j, i, :),Temp_maize,RN_maize,EP_maize,ET0_maize,start_time_maize,end_time_maize,Tb(2),PHU(2),TO(2),ab1(2),ab2(2),LAImax(2),HUI0(2),ad(2),BE(2),HI(2),Kc_maize,torigin(2),tending(2),Rootorigin(2),Rootending(2),thetaorigin,fieldcapacity,wilting);
        wheat_yield (j, i) = wheat_Yield_unit(j, i) * Area_wheat(i);
        maize_yield (j, i) = maize_Yield_unit(j, i) * Area_maize(i);
    end
end
wheat_yield = sum(wheat_yield,2);
maize_yield = sum(maize_yield,2);
% 总产量
Yield_tot = wheat_yield + maize_yield;
f3 = Yield_tot ./ Water_total;
f3 = - f3;

   if any(f3 < -1e10)
       disp('f3 contains values greater than 10^10. Entering debug mode...');
       keyboard;
   end
   
   % 罚函数
   for i = 1:length(v)
       if any(Qgm(i, :) > 1.2 * params.Qgd)
           f3(i) = f3(i) + 1e10;
       end
   end

   
   maxWaterPerStage = params.maxWaterPerStage_all; % 因为3个轮期是第一列，4个轮期是第二列
   for i = 1:length(v)
       for j = 1:params.numStages
           stageWater_region(i, :, j) = v(i).dailyWater(:, j) .* (v(i).irrigationEnd(:, j) - v(i).irrigationStart(:, j) + 1);
           totalWater(i, j) = sum(stageWater_region(i, :, j), 'all');
       end
   end
%    for i = 1:length(v)
%        for j = 1:params.numStages
%            totalWater(i, j) = sum(v(i).dailyWater(:, j, :), 'all');
%        end
%    end
   for i = 1:length(v)
       comparison_result = totalWater(i, :) > maxWaterPerStage;
       if any(comparison_result)
           f3(i) = f3(i) + 1e10;
       end
   end
  for i = 1:length(v)
       if Yield_tot(i) < 4.2e7
           f3(i) = f3(i) + 1e10;
       end
   end
   
end

