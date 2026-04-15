function params = params_demo()

% =======================
% DE parameters
% =======================
params.popSize = 30;
params.maxGen  = 30;
params.F       = 0.5;
params.CR      = 0.9;

% =======================
% Decision variables
% =======================
params.GPL = 120;                     % 生长季天数
params.dim = params.GPL;              % 决策变量：逐日灌水量（mm/day）

params.irrigationLower = zeros(1, params.dim);
params.irrigationUpper = 20 * ones(1, params.dim);

% =======================
% Penalty thresholds
% =======================
params.maxTotalIrrigation = 1200;     % mm
params.maxDailyIrrigation = 20;       % mm/day
params.minYield = 0;                  % 可设为正值启用最低产量约束

% =======================
% Crop model parameters
% =======================
params.crop.Tb = 2;
params.crop.PHU = 1850;
params.crop.TO = 22;
params.crop.ab1 = 1.501;
params.crop.ab2 = 20.095;
params.crop.LAImax = 4.8;
params.crop.HUI0 = 0.51;
params.crop.ad = 0.75;
params.crop.BE = 37;
params.crop.HI = 0.45;

params.crop.Kc = [];                 % 为空时由 run_crop_model 内部处理
params.crop.torigin = 30;
params.crop.tiending = 130;
params.crop.Rootorigin = 0.2;
params.crop.Rootending = 0.9;
params.crop.fieldcapacity = 0.32;
params.crop.wilting = 0.10;
params.crop.theta0 = 0.168;

end