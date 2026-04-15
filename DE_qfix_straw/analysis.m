clear;
clc;
% 计算每个分区每次灌溉用水量，总灌溉用水量（毛、净），产量，干渠流量
result_1_1 = load('reanalyze_result_1_1.mat');
result_1_2 = load('reanalyze_result_1_2.mat');
result_1_3 = load('reanalyze_result_1_3.mat');
result_2_1 = load('reanalyze_result_2_1.mat');
result_2_2 = load('reanalyze_result_2_2.mat');
result_2_3 = load('reanalyze_result_2_3.mat');
result_3_1 = load('reanalyze_result_3_1.mat');
result_3_2 = load('reanalyze_result_3_2.mat');
result_3_3 = load('reanalyze_result_3_3.mat');

perato_location = [12 13 11; 3 13 7;10 30 5];

for hydrology = 1:3
    for numturn = 1:3      
%% 定义结构体（该模型中所使用全局变量）
        % 气象参数
        params = struct(); % 初始化结构体
        filePath1 = 'E:\7-工作\02-论文\023-自己在写的论文2024\0231-202408\渠系输水优化\我自己的模型\input\weather_3.txt'; % 设定文件路径
        dataTable1 = readtable(filePath1, 'Delimiter', '\t');% 读取文件内容为表格
        variableNames1 = {'Temp', 'RN', 'ET0'};% 定义变量名称
        % 动态生成结构体字段并赋值
        for k = 1:length(variableNames1)
            % 为每个自定义变量名创建结构体字段并赋值
            params.(variableNames1{k}) = dataTable1{:, k};
        end
        filePath2 = 'E:\7-工作\02-论文\023-自己在写的论文2024\0231-202408\渠系输水优化\我自己的模型\input\EP_hydrological.txt'; % 设定文件路径
        dataTable2 = readtable(filePath2, 'Delimiter', '\t');% 读取文件内容为表格
        variableNames2 = 'EP';% 定义变量名称
        params.(variableNames2) = dataTable2{:, hydrology};
        
        % 土壤参数
        params.fieldcapacity = 0.32 ; params.wilting= 0.10 ; params.thetaorigin = 0.168; % 体积含水率,cm3/cm3
        
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
        
        filePath3 = 'E:\7-工作\02-论文\023-自己在写的论文2024\0231-202408\渠系输水优化\我自己的模型\input\Kc.txt';
        dataTable3 = readtable(filePath3, 'Delimiter', '\t');% 读取文件内容为表格
        variableNames3 = {'Kc_wheat', 'Kc_maize'};% 定义变量名称
        for k = 1:length(variableNames3)
            % 为每个自定义变量名创建结构体字段并赋值
            params.(variableNames3{k}) = dataTable3{:, k};
        end
        
        %渠系参数
        params.I = 8;% 支渠条数
        params.Qgd = 18;% 干渠的设计流量，m3/s
        params.Ag = 3.4; params.lg = 8.41; params.mg = 0.5; %计算干渠流量损失的参数
        params.bg_dk = 2.5; params.mg_bp = 1.5; params.ig_pd = 1/15000; params.ng_cl = 0.022; % 干渠横断面参数
        filePath4 = 'E:\7-工作\02-论文\023-自己在写的论文2024\0231-202408\渠系输水优化\我自己的模型\input\canal.txt';
        dataTable4 = readtable(filePath4, 'Delimiter', '\t');% 读取文件内容为表格
        variableNames4 = {'Index', 'A','m_canal','l','qd','Area_wheat','Area_maize','b_dk','m_bp','i_pd','n_cl','gate_weight'};% 定义变量名称（计算支渠流量损失的参数、支渠的设计流量m3/s、支渠小麦/玉米的面积ha,支渠的设计参数）
        for k = 1:length(variableNames4)
            % 为每个自定义变量名创建结构体字段并赋值
            params.(variableNames4{k}) = dataTable4{:, k};
        end
        
        % 与轮期有关的参数
        filePath4 = sprintf('E:\\7-工作\\02-论文\\023-自己在写的论文2024\\0231-202408\\渠系输水优化\\我自己的模型\\input\\ratio_of_water_turnall_%d.txt', numturn);
        filePath5 = sprintf('E:\\7-工作\\02-论文\\023-自己在写的论文2024\\0231-202408\\渠系输水优化\\我自己的模型\\input\\water_availability_turnall_%d.txt', numturn);
        params.ratioWaterConsumption = load(filePath4);
        params.maxWaterPerStage_all = load(filePath5);
        
        % 与约束相关的参数
        params.numStages = numturn + 2; % 轮期数量
        
        % 每天每个分区的小麦和玉米的最大净灌水量，0.71为支斗农渠的渠系水利用系数，0.9为田间水利用效率
        params.maxWaterPerDayRegion = params.qd * 86400 * 0.71 * 0.9 .* params.ratioWaterConsumption;
        % 每个轮期的最大可用水量，假设斗农渠水利用效率为0.77，田间水利用效率为0.9，小麦玉米耗水占比0.78
        if hydrology == 1
            ratio_hydrology = 1;
        elseif hydrology == 2
            ratio_hydrology = 0.87;
        else
            ratio_hydrology = 0.72;
        end
        params.maxWaterPerStage_all = params.maxWaterPerStage_all * 0.77 * 0.9 * 0.78 * ratio_hydrology;
        % 每天小麦和玉米的总最大净灌水量,假设干支斗农水利用效率为0.641，田间水利用效率为0.9，每天小麦和玉米占总耗水的比例为0.76
        params.maxWaterPerDay = params.Qgd * 86400 * 0.641 * 0.9 * 0.76;
        
        var_name = sprintf('result_%d_%d', hydrology, numturn);
        result = eval(var_name);
        
        % 分析的参数的初始化
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
        
        % 目标值计算
        Objectives = evaluateObjectives(result.paretoSolutions, params);
        filename = sprintf('Objectives_%.d_%.d.mat', hydrology, numturn);
        save(filename,'Objectives');
       
        
        % 产量（输出小麦/玉米每个区域单产、小麦/玉米每个区域的总产、灌区小麦/玉米总产、粮食总产）
        % 每日的小麦和玉米的总净灌水量
        dailyWater = TransferWater(result.paretoSolutions, params);
        wheatRatio = TransferField(result.paretoSolutions, params, 'wheatRatio');
        maizeRatio = TransferField(result.paretoSolutions, params, 'maizeRatio');
        % 小麦和玉米占区域总净灌水的比例
        RatioAll = [params.ratioWaterConsumption(:, 1) .* ones(1, params.start_time_maize - 1),...
            params.ratioWaterConsumption(:, 2) .* ones(1, params.end_time_wheat - params.start_time_maize + 1),...
            params.ratioWaterConsumption(:, 3) .* ones(1, params.GPL - params.end_time_wheat)];
        RatioAll = repmat(RatioAll, 1, 1, length(result.paretoSolutions));
        RatioAll = permute(RatioAll, [3, 1, 2]);
        
        % 每条渠的小麦/玉米的灌水量（单位，mm）
        IQwheat = dailyWater .* wheatRatio ./ (10 * Area_wheat_all);
        IQmaize = dailyWater .* maizeRatio ./ (10 * Area_maize_all);
        wheat_Yield_unit = zeros(length(result.paretoSolutions),I);  maize_Yield_unit = zeros(length(result.paretoSolutions),I);
        for j = 1:length(result.paretoSolutions)
            for i = 1:I
                [wheat_Yield_unit(j, i), wheat_straw_unit(j, i)] = Crop_Yield(IQwheat(j, i, :),Temp_wheat,RN_wheat,EP_wheat,ET0_wheat,start_time_wheat,end_time_wheat,Tb(1),PHU(1),TO(1),ab1(1),ab2(1),LAImax(1),HUI0(1),ad(1),BE(1),HI(1),Kc_wheat,torigin(1),tending(1),Rootorigin(1),Rootending(1),thetaorigin,fieldcapacity,wilting);
                [maize_Yield_unit(j, i), maize_straw_unit(j, i)] = Crop_Yield(IQmaize(j, i, :),Temp_maize,RN_maize,EP_maize,ET0_maize,start_time_maize,end_time_maize,Tb(2),PHU(2),TO(2),ab1(2),ab2(2),LAImax(2),HUI0(2),ad(2),BE(2),HI(2),Kc_maize,torigin(2),tending(2),Rootorigin(2),Rootending(2),thetaorigin,fieldcapacity,wilting);
                wheat_yield_region(j, i) = wheat_Yield_unit(j, i) * Area_wheat(i);
                maize_yield_region(j, i) = maize_Yield_unit(j, i) * Area_maize(i);
                wheat_straw_region (j, i) = wheat_straw_unit(j, i) * Area_wheat(i);
                maize_straw_region (j, i) = maize_straw_unit(j, i) * Area_maize(i);
                wheat_bioenergy_region(j, i) = 14 * wheat_straw_region (j, i);
                maize_bioenergy_region(j, i) = 19 * maize_straw_region (j, i);
            end
        end
        
        wheat_straw_all = sum(wheat_straw_region,2);
        maize_straw_all = sum(maize_straw_region,2);       
        
        wheat_bioenergy_all = sum(wheat_bioenergy_region,2);
        maize_bioenergy_all = sum(maize_bioenergy_region,2); 
        
        wheat_yield_all = sum(wheat_yield_region,2);
        maize_yield_all = sum(maize_yield_region,2);
        
        straw_tot = wheat_straw_all + maize_straw_all;
        bioenergy_tot = wheat_bioenergy_all + maize_bioenergy_all;
        Yield_tot = wheat_yield_all + maize_yield_all;
        
        perato_location_1 =  perato_location(hydrology, numturn);
        IQwheat_perato = squeeze(IQwheat(perato_location_1,:,:));
        IQmaize_perato = squeeze(IQmaize(perato_location_1,:,:));
        
        filename = sprintf('Yield_%.d_%.d.mat', hydrology, numturn);
        save(filename,  'IQwheat_perato', 'IQmaize_perato', 'wheat_Yield_unit', 'maize_Yield_unit', 'wheat_yield_region', 'maize_yield_region', 'wheat_yield_all', 'maize_yield_all','Yield_tot',...
            'wheat_straw_unit', 'maize_straw_unit', 'wheat_straw_region', 'maize_straw_region', 'wheat_straw_all', 'maize_straw_all','straw_tot',...
            'wheat_bioenergy_region', 'maize_bioenergy_region', 'wheat_bioenergy_all', 'maize_bioenergy_all','bioenergy_tot' ); % 保存结果
        
        % 干支渠流量
        % 支渠流量
        qz = dailyWater ./ RatioAll / (86400 * 0.9 * 0.71) ; % 每条支渠每天的净流量 [size(v, 1), I, GPL]  ET占比 田间水利用效率 斗渠和农渠输水效率
        m_canal_expanded = reshape(m_canal, [1, I, 1]); % 确保 m_canal 的维度与 qz 匹配
        qzs = (reshape(A,[1, I, 1]) .* reshape(l,[1, I, 1])) .* (qz.^ (1 - m_canal_expanded)) / 100 * 0.5;
        qzm = qz + qzs; % [size(v, 1), I, GPL]  计算每条支渠每天的毛流量
        % 干渠流量
        Qg = squeeze(sum(qzm, 2)); % [size(v, 1), GPL]  计算干渠的净流量（所有支渠毛流量之和）
        Qgs = Ag * lg * Qg .^ (1 - mg) / 100 * 0.3;
        Qgm = Qgs + Qg;
        % 渠系水利用系数
        % 支渠水利用系数
        yeta_z = squeeze(sum(qz, 3)) ./ squeeze(sum(qzm, 3));
        yeta_g = squeeze(sum(Qg, 2)) ./ squeeze(sum(Qgm, 2));
        yeta = squeeze(sum(sum(qz, 3), 2)) ./ squeeze(sum(Qgm, 2));
        % 毛灌水量(m3)
        water_consumption_region_dou = squeeze(sum(qz, 3)) * 86400;
        water_consumption_dou = squeeze(sum(sum(qz, 3), 2)) * 86400;
        water_consumption_region = squeeze(sum(qzm, 3)) * 86400;
        water_comsumption = squeeze(sum(Qgm, 2)) * 86400; 
        
        qz_region_others = qz .* (1 - RatioAll) * 0.9 * 0.71; 
        water_consumption_others = squeeze(sum(qz_region_others, 3)) * 86400;
        
        dailyWater_qz = result.paretoSolutions(perato_location_1).dailyWater;
        Ratio = params.ratioWaterConsumption;
        qzm_round = dailyWater_qz ./ Ratio / (86400 * 0.9 * 0.71);
        
        filename = sprintf('Flow_%.d_%.d.mat', hydrology, numturn);
        save(filename, 'qzm', 'Qgm', 'yeta_z', 'yeta_g', 'yeta', 'water_consumption_dou', 'water_comsumption','water_consumption_region_dou', 'water_consumption_region', 'water_consumption_others', 'qzm_round'); % 保存结果
        
        % 小麦/玉米用水量 净灌水量
        % 单位面积灌水量（mm）
        wheat_irrigation_unit = squeeze(sum(sum(IQwheat, 3) ,2)) / I; % 小麦全生育期单位面积的灌水量，灌区平均
        maize_irrigation_unit = squeeze(sum(sum(IQmaize, 3), 2)) / I; % 小麦全生育期单位面积的灌水量，灌区平均
        % 每个区域小麦/玉米各自的总灌水量（m3）
        wheat_irrigation_region = 10 * squeeze(sum(IQwheat, 3)) .* Area_wheat_all;
        maize_irrigation_region = 10 * squeeze(sum(IQmaize, 3)) .* Area_maize_all;
        % 小麦/玉米总灌水量（m3）
        wheat_irrigation = squeeze(sum(wheat_irrigation_region, 2));
        maize_irrigation = squeeze(sum(maize_irrigation_region, 2));
        % 总灌水量
        irrigation = wheat_irrigation + maize_irrigation;
    end
end


