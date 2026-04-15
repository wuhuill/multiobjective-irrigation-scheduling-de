function params = params_demo()
% PARAMS_DEMO
% Create the parameter structure for the irrigation optimization demo.
%
% UNITS AND PARAMETER DESCRIPTION
%
% 1) DE optimizer parameters
%    - popSize : population size (unitless)
%    - maxGen  : maximum number of generations (unitless)
%    - F       : differential weight in DE mutation (unitless)
%    - CR      : crossover rate in DE crossover (unitless)
%
% 2) Decision variable settings
%    - GPL             : growing season length (days)
%    - dim             : number of decision variables (unitless)
%    - irrigationLower : lower bound of daily irrigation depth (mm/day)
%    - irrigationUpper : upper bound of daily irrigation depth (mm/day)
%
% 3) Penalty thresholds
%    - maxTotalIrrigation : maximum seasonal irrigation (mm)
%    - maxDailyIrrigation : maximum irrigation depth per day (mm/day)
%    - minYield           : minimum yield threshold (kg/ha)
%
% 4) Crop model parameters
%    These parameters are passed to run_crop_model and control crop growth,
%    soil water balance, LAI development, biomass accumulation, and yield.
%    - Tb         : base temperature (°C)
%    - PHU        : total required heat units (°C·day)
%    - TO         : optimum temperature (°C)
%    - ab1        : LAI development parameter (unitless)
%    - ab2        : LAI development parameter (unitless)
%    - LAImax     : maximum leaf area index (unitless)
%    - HUI0       : heat unit index threshold for LAI decline (unitless)
%    - ad         : LAI decline shape parameter (unitless)
%    - BE         : biomass conversion coefficient
%                   [kg/ha per (MJ/m^2)] or equivalently kg/ha/(MJ/m^2)
%    - HI         : harvest index (unitless)
%    - Kc         : daily crop coefficient (unitless)
%    - torigin    : day when root growth starts (days)
%    - tiending   : day when root growth stops (days)
%    - Rootorigin : initial root depth (m)
%    - Rootending : maximum root depth (m)
%    - fieldcapacity : soil field capacity (cm^3/cm^3)
%    - wilting       : soil wilting point (cm^3/cm^3)
%    - theta0        : initial soil water content (cm^3/cm^3)

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
params.GPL = 120;
params.dim = params.GPL;

params.irrigationLower = zeros(1, params.dim);
params.irrigationUpper = 20 * ones(1, params.dim);

% =======================
% Penalty thresholds
% =======================
params.maxTotalIrrigation = 1200;
params.maxDailyIrrigation = 20;
params.minYield = 0;

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

params.crop.Kc = [];
params.crop.torigin = 30;
params.crop.tiending = 130;
params.crop.Rootorigin = 0.2;
params.crop.Rootending = 0.9;
params.crop.fieldcapacity = 0.32;
params.crop.wilting = 0.10;
params.crop.theta0 = 0.168;

end