% CROP_DEMO
% Standalone demo for the preserved crop growth model.
%
% PURPOSE
% This script runs the crop growth simulator independently, without the
% optimization framework, to verify that the crop model works correctly.
%
% INPUTS
% - weather.Temp : daily mean temperature (°C)
% - weather.RN   : daily net radiation (MJ/m^2/day)
% - weather.EP   : daily effective precipitation (mm/day)
% - weather.ET0  : daily reference evapotranspiration (mm/day)
% - irrigation   : daily irrigation depth (mm/day)
%
% OUTPUTS
% - results.theta : daily soil water content (cm^3/cm^3)
% - results.ETa   : daily actual evapotranspiration (mm/day)
% - results.Bio   : cumulative biomass (kg/ha)
% - results.Yield : final yield (kg/ha)
% - results.Straw : final straw biomass (kg/ha)
% - results.Ksw   : daily water stress coefficient (unitless)
% - results.LAI   : daily leaf area index (unitless)
%
% NOTE
% This demo uses simulated weather data and a simple irrigation schedule.

clear; clc; close all;

%% 1. Set simulation length
GPL = 125;                 % growing season length (days)
t = (1:GPL)';              % time vector

%% 2. Generate synthetic weather data
% Temperature: increases from spring to summer and then decreases
Temp = 15 + 10 * sin(linspace(-pi/2, pi/2, GPL)') + 2*randn(GPL,1);
Temp = max(0, Temp);       % non-negative temperature

% Net radiation: similar seasonal trend
RN = 8 + 5 * sin(linspace(-pi/2, pi/2, GPL)') + 2*randn(GPL,1);
RN = max(0, RN);           % non-negative radiation

% Effective precipitation: random rainfall events
EP = zeros(GPL,1);
rain_days = randi(GPL, 15, 1);
EP(rain_days) = 5 + 10*rand(size(rain_days));

% Reference evapotranspiration: positively related to temperature and radiation
ET0 = 3 + 0.1 * Temp + 0.2 * RN + randn(GPL,1);
ET0 = max(0.5, ET0);       % keep a realistic lower bound

weather.Temp = Temp;
weather.RN   = RN;
weather.EP   = EP;
weather.ET0  = ET0;

%% 3. Simple irrigation schedule
irrigation = zeros(GPL,1);
irrigation(50:10:70) = 30;   % irrigation at days 50, 60, and 70 (mm)

%% 4. Crop parameters
params.Tb     = 2;       % base temperature (°C)
params.PHU    = 1500;    % required heat units (°C·day)
params.TO     = 22;      % optimum temperature (°C)

params.ab1    = 2;       % LAI development parameter (unitless)
params.ab2    = 20;      % LAI development parameter (unitless)
params.LAImax = 5;       % maximum LAI (unitless)
params.HUI0   = 0.5;     % heat unit index threshold for LAI decline (unitless)
params.ad     = 0.75;    % LAI decline shape parameter (unitless)
params.BE     = 40;      % biomass conversion coefficient [kg/ha per (MJ/m^2)]
params.HI     = 0.45;    % harvest index (unitless)

% Daily crop coefficient (unitless)
Kc = ones(GPL,1) * 0.4;
Kc(30:100) = linspace(0.4, 1.2, 71)';
Kc(101:125) = linspace(1.2, 0.6, 25)';
params.Kc = Kc;

% Root growth parameters
params.torigin    = 30;   % root growth start day (days)
params.tiending   = 125;  % root growth end day (days)
params.Rootorigin = 0.2;  % initial root depth (m)
params.Rootending = 0.9;  % maximum root depth (m)

% Soil parameters
params.fieldcapacity = 0.32;  % soil field capacity (cm^3/cm^3)
params.wilting       = 0.10;  % soil wilting point (cm^3/cm^3)
params.theta0        = 0.2;   % initial soil water content (cm^3/cm^3)

%% 5. Run crop model
results = run_crop_model(weather, irrigation, params);

%% 6. Plot results
figure('Position', [100 100 1000 800]);

subplot(3,2,1);
plot(t, Temp, 'r-', t, ET0, 'b--', 'LineWidth', 1.5);
xlabel('Day'); ylabel('°C / mm'); legend('Temp', 'ET0');
title('Weather Data');

subplot(3,2,2);
plot(t, irrigation, 'g-', 'LineWidth', 1.5);
xlabel('Day'); ylabel('mm'); title('Irrigation');

subplot(3,2,3);
plot(t, results.theta, 'b-', 'LineWidth', 1.5);
hold on;
yline(params.fieldcapacity, 'k--', 'FC');
yline(params.wilting, 'r--', 'WP');
xlabel('Day'); ylabel('Soil moisture (cm^3/cm^3)');
title('Soil Water Content');
legend('\theta', 'FC', 'WP');

subplot(3,2,4);
plot(t, results.LAI, 'g-', 'LineWidth', 1.5);
xlabel('Day'); ylabel('LAI'); title('Leaf Area Index');

subplot(3,2,5);
plot(t, results.ETa, 'b-', t, results.Ksw, 'r--', 'LineWidth', 1.5);
xlabel('Day'); ylabel('mm / -');
legend('ETa', 'Ksw');
title('Actual Evapotranspiration and Water Stress');

subplot(3,2,6);
plot(t, results.Bio/1000, 'k-', 'LineWidth', 1.8);
xlabel('Day'); ylabel('Biomass (t/ha)');
title('Cumulative Biomass');
text(GPL*0.7, max(results.Bio/1000)*0.8, ...
    sprintf('Yield = %.2f t/ha\nStraw = %.2f t/ha', results.Yield/1000, results.Straw/1000));
grid on;

sgtitle('Crop Growth Model Simulation Results');