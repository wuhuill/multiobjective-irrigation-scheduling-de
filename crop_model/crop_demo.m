% crop_demo.m
% 单作物模型运行示例
% 使用模拟气象数据和简单灌溉方案，展示模型输出

clear; clc; close all;

%% 1. 设置模拟参数
GPL = 125;            % 生长季天数
t = (1:GPL)';         % 列向量

%% 2. 生成示例气象数据（全部使用列向量）
% 温度：春季到夏季逐渐升高再下降
Temp = 15 + 10 * sin(linspace(-pi/2, pi/2, GPL)') + 2*randn(GPL,1);
Temp = max(0, Temp);  % 不低于0

% 净辐射：类似温度趋势
RN = 8 + 5 * sin(linspace(-pi/2, pi/2, GPL)') + 2*randn(GPL,1);
RN = max(0, RN);

% 有效降水：偶尔有雨
EP = zeros(GPL,1);
rain_days = randi(GPL, 15, 1);  % 随机15天降雨
EP(rain_days) = 5 + 10*rand(size(rain_days));

% 参考蒸散：与温度辐射正相关
ET0 = 3 + 0.1 * Temp + 0.2 * RN + randn(GPL,1);
ET0 = max(0.5, ET0);

weather.Temp = Temp;
weather.RN   = RN;
weather.EP   = EP;
weather.ET0  = ET0;

%% 3. 简单灌溉方案
irrigation = zeros(GPL,1);
irrigation(50:10:70) = 30;   % 第50,60,70天各灌30mm

%% 4. 作物参数
params.Tb          = 2;      % 基温 ℃
params.PHU         = 1500;   % 热单元需求 ℃·d
params.TO          = 22;     % 最适温度 ℃
params.ab1         = 2;      % LAI 参数
params.ab2         = 20;
params.LAImax      = 5;
params.HUI0        = 0.5;
params.ad          = 0.75;
params.BE          = 40;     % 光能利用效率
params.HI          = 0.45;   % 收获指数

% 逐日作物系数 Kc（简单分段线性）
Kc = ones(GPL,1) * 0.4;
Kc(30:100) = linspace(0.4, 1.2, 71)';
Kc(101:125) = linspace(1.2, 0.6, 25)';
params.Kc = Kc;

% 根系参数
params.torigin     = 30;
params.tiending    = 125;
params.Rootorigin  = 0.2;
params.Rootending  = 0.9;

% 土壤参数
params.fieldcapacity = 0.32;
params.wilting       = 0.10;
params.theta0        = 0.2;   % 初始含水量

%% 5. 运行模型
results = run_crop_model(weather, irrigation, params);

%% 6. 绘图展示结果
figure('Position', [100 100 1000 800]);

subplot(3,2,1);
plot(t, Temp, 'r-', t, ET0, 'b--', 'LineWidth',1.5);
xlabel('Day'); ylabel('℃ / mm'); legend('Temp','ET0');
title('气象数据');

subplot(3,2,2);
plot(t, irrigation, 'g-', 'LineWidth',1.5);
xlabel('Day'); ylabel('mm'); title('灌溉量');

subplot(3,2,3);
plot(t, results.theta, 'b-', 'LineWidth',1.5);
hold on;
yline(params.fieldcapacity, 'k--', 'FC');
yline(params.wilting, 'r--', 'WP');
xlabel('Day'); ylabel('Soil moisture (cm^3/cm^3)'); title('土壤含水量');
legend('θ', 'FC', 'WP');

subplot(3,2,4);
plot(t, results.LAI, 'g-', 'LineWidth',1.5);
xlabel('Day'); ylabel('LAI'); title('叶面积指数');

subplot(3,2,5);
plot(t, results.ETa, 'b-', t, results.Ksw, 'r--', 'LineWidth',1.5);
xlabel('Day'); ylabel('mm / -'); legend('ETa', 'Ksw'); title('实际蒸散和水分胁迫');

subplot(3,2,6);
plot(t, results.Bio/1000, 'k-', 'LineWidth',1.8);
xlabel('Day'); ylabel('Biomass (t/ha)'); title('累积生物量');
text(GPL*0.7, max(results.Bio/1000)*0.8, ...
    sprintf('Yield = %.2f t/ha\nStraw = %.2f t/ha', results.Yield/1000, results.Straw/1000));
grid on;

sgtitle('作物生长模型模拟结果');