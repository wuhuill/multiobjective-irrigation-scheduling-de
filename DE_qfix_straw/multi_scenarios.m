% hydrology = 1 2 3 Wet Normal Dry
% numturn = 1 2 3 为轮期 3 4 5
clc;
clear;
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
        
        %% 差分进化参数
        DE_params.num_obj = 5;                     num_obj = DE_params.num_obj;     % 目标函数的数量
        DE_params.NIND = 40 * DE_params.num_obj;   NIND = DE_params.NIND;           % 个体数目
        DE_params.Maxgen = 1000;                    Maxgen = DE_params.Maxgen;       % 最大遗传代数
        
        % 差分进化参数，F为动态调整因子，用于控制变异的程度， Cr为变异概率
        DE_params.F = 1;      DE_params.Cr = 0.75;
        
        % 加入单目标解以更好的搜索全局最优解
        filePath6 = sprintf('E:\\7-工作\\02-论文\\023-自己在写的论文2024\\0231-202408\\渠系输水优化\\我自己的模型\\DE_qfix_straw\\results\\optimalIndividual_%d_%d.mat', hydrology, numturn);
        optimalIndividual = load(filePath6);
        
        % 调用差分进化函数
        % [V1, paretoObjectives, paretoSolutions, objectives, single_objective, hypervolumeList, spreadList] = Pareto_DE(params, DE_params);
        [V1, paretoObjectives, paretoSolutions, objectives, single_objective, hypervolumeList, spreadList] = Pareto_DE(params, DE_params, optimalIndividual);
        
        % 绘制三维帕累托前沿
        figure; % 创建新的图形窗口
        scatter3(paretoObjectives(:, 1), paretoObjectives(:, 2), paretoObjectives(:, 3), 50, 'b', 'filled');
        xlabel('Objective 1');
        ylabel('Objective 2');
        zlabel('Objective 3');
        title(sprintf('Pareto Front (hydrology = %d, numturn = %d)', hydrology, numturn)); % 包含 hydrology 和 numturn 信息的标题
        grid on;
        
        % 定义要创建的文件夹名称
        folderName = '4.2';  % 你可以更改为需要的名称
        currentFolder = pwd;  % 获取当前工作目录
        newFolderPath = fullfile(currentFolder,'results', folderName);  % 组合完整路径
        
        % 检查是否存在该文件夹，如果不存在则创建
        if ~exist(newFolderPath, 'dir')
            mkdir(newFolderPath);
        end
        
        filename = sprintf('result_%d_%d.mat', hydrology, numturn);
        save(fullfile(newFolderPath, filename), 'V1', 'paretoObjectives', 'paretoSolutions', 'objectives', 'single_objective', 'hypervolumeList', 'spreadList'); % 保存结果
    end
end


