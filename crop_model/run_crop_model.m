function [results] = run_crop_model(weather, irrigation, params)
% RUN_CROP_MODEL
% Single-season crop growth simulation with soil water balance,
% biomass accumulation, yield formation, and LAI dynamics.
%
% INPUTS
% - weather.Temp : daily mean temperature (°C)
% - weather.RN   : daily net radiation (MJ/m^2/day)
% - weather.EP   : daily effective precipitation (mm/day)
% - weather.ET0  : daily reference evapotranspiration (mm/day)
% - irrigation   : daily irrigation depth (mm/day)
% - params       : crop model parameter structure
%
% PARAMETER UNITS
% - Tb           : base temperature (°C)
% - PHU          : required heat units (°C·day)
% - TO           : optimum temperature (°C)
% - ab1, ab2     : LAI development parameters (unitless)
% - LAImax       : maximum leaf area index (unitless)
% - HUI0         : heat unit index threshold for LAI decline (unitless)
% - ad           : LAI decline shape parameter (unitless)
% - BE           : biomass conversion coefficient [kg/ha per (MJ/m^2)]
% - HI           : harvest index (unitless)
% - Kc           : daily crop coefficient (unitless)
% - torigin      : day when root growth starts (days)
% - tiending     : day when root growth stops (days)
% - Rootorigin   : initial root depth (m)
% - Rootending   : maximum root depth (m)
% - fieldcapacity: soil field capacity (cm^3/cm^3)
% - wilting      : soil wilting point (cm^3/cm^3)
% - theta0       : initial soil water content (cm^3/cm^3)
%
% OUTPUTS
% - results.theta : daily soil water content (cm^3/cm^3)
% - results.ETa   : daily actual evapotranspiration (mm/day)
% - results.Bio   : cumulative biomass (kg/ha)
% - results.Yield : final yield (kg/ha)
% - results.Straw : final straw biomass (kg/ha)
% - results.Ksw   : daily water stress coefficient (unitless)
% - results.LAI   : daily leaf area index (unitless)


    %% ��ȡ��������
    Temp = weather.Temp(:);
    RN   = weather.RN(:);
    EP   = weather.EP(:);
    ET0  = weather.ET0(:);
    IQ   = irrigation(:);
    GPL  = length(Temp);

    %% Ԥ����
    theta = zeros(GPL,1);
    ETa   = zeros(GPL,1);
    Ksw   = zeros(GPL,1);
    LAI   = zeros(GPL,1);
    Bio   = zeros(GPL,1);

    %% ����
    Root = zeros(GPL,1);
    for t = 1:GPL
        Root(t) = Crop_Root(t, params.torigin, params.tiending, ...
                            params.Rootorigin, params.Rootending);
    end

    %% �ȵ�Ԫָ�� HUI�����Ʋ�����1��
    HU = max(0, Temp - params.Tb);
    HUI = cumsum(HU) / params.PHU;
    HUI = min(HUI, 1);   % �ؼ����������Ϊ1

    %% ����ѭ��
    for t = 1:GPL
        % ˮ��в��ϵ��
        if t == 1
            theta_prev = params.theta0;
        else
            theta_prev = theta(t-1);
        end
        Ksw(t) = Crop_Ksw(params.fieldcapacity, params.wilting, theta_prev);

        % �¶�в��ϵ��
        KTS = max(0, sin(pi/2 * (Temp(t) - params.Tb) / (params.TO - params.Tb)));
        REG = min(KTS, Ksw(t));
        REG = max(0, REG);   % ȷ���Ǹ�

        % Ҷ���ָ�� LAI
        HUF = max(0, HUI(t) / (HUI(t) + exp(params.ab1 - params.ab2 * HUI(t))));
        if t == 1
            delta_HUF = HUF;
            LAI(t) = delta_HUF * params.LAImax * (1 - exp(-5 * params.LAImax)) * sqrt(REG);
            LAI(t) = max(0, min(params.LAImax, LAI(t)));   % ���Ʒ�Χ
            LAI_max_act = LAI(t);
        else
            delta_HUF = max(0, HUF - HUF_prev);
            if HUI(t) < params.HUI0
                % �����׶Σ���ֹ�������¸���
                LAI_prev = min(LAI(t-1), params.LAImax);   % ����ǰһʱ�̲�����LAImax
                exp_term = exp(5 * (LAI_prev - params.LAImax));
                inc = delta_HUF * params.LAImax * (1 - exp_term) * sqrt(REG);
                LAI(t) = LAI(t-1) + inc;
                LAI(t) = max(0, min(params.LAImax, LAI(t)));
                LAI_max_act = max(LAI_max_act, LAI(t));
            else
                % �½��׶Σ���ֹ����Ϊ��
                ratio = (1 - HUI(t)) / (1 - params.HUI0);
                ratio = max(0, ratio);   % �ؼ���ȷ���Ǹ�
                LAI(t) = LAI_max_act * (ratio ^ params.ad);
                LAI(t) = max(0, min(params.LAImax, LAI(t)));
            end
        end
        HUF_prev = HUF;

        % �����Ч���� PAR ������������
        PAR = 0.5 * RN(t) * (1 - exp(-0.65 * LAI(t)));
        delta_Bio = params.BE * PAR * REG;
        if t == 1
            Bio(t) = delta_Bio;
        else
            Bio(t) = Bio(t-1) + delta_Bio;
        end

        % ʵ����ɢ��
        if isempty(params.Kc)
            Kc_t = 1.0;
        else
            Kc_t = params.Kc(min(t, numel(params.Kc)));
        end
        ETa(t) = Kc_t * Ksw(t) * ET0(t);

        % ����ˮ��ƽ��
        if t == 1
            [theta(t), ~] = Soil_Water(theta_prev, EP(t), IQ(t), ETa(t), ...
                Root(t), Root(t), params.fieldcapacity, params.theta0);
        else
            [theta(t), ~] = Soil_Water(theta_prev, EP(t), IQ(t), ETa(t), ...
                Root(t), Root(t-1), params.fieldcapacity, params.theta0);
        end
    end

    %% ���ղ����ͽո�
    Yield = params.HI * Bio(end);
    Straw = 0.9 * (Bio(end) - Yield);

    %% ������
    results.theta = theta;
    results.ETa   = ETa;
    results.Bio   = Bio;
    results.Yield = Yield;
    results.Straw = Straw;
    results.Ksw   = Ksw;
    results.LAI   = LAI;
end

% -------------------------------------------------------------------------
% �Ӻ�����Crop_Ksw, Crop_Root, Soil_Water ��ԭ��ͬ���ԣ�
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