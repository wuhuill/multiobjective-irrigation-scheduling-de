function [Yield_HI, Straw_end, theta] = Crop_Yield(IQ,Temp,RN,EP,ET0,start_time,end_time,Tb,PHU,TO,ab1,ab2,LAImax,HUI0,ad,BE,HI,Kc,tiorigin,tiending,Rootorigin,Rootending,thetaorgion,fieldcapacity,wilting)  
%YIELD 计算作物产量
%  需要给出模型参数（气象、生理、土壤、初始条件参数）
%Tb, PHU, TO, ab1, ab2, LAImax, HUI0, ad, BE, HI

%中间变量
    GPL = end_time - start_time + 1;
    Root = zeros(1, GPL);     Ksw = zeros(1, GPL);     ETa = zeros(1, GPL);    HU = zeros(1, GPL);
    HUI = zeros(1, GPL);    KTS = zeros(1, GPL);    REG = zeros(1, GPL);    HUF = zeros(1, GPL);
    delta_HUF = zeros(1, GPL);    LAI = zeros(1, GPL);    PAR = zeros(1, GPL);    delta_Bio = zeros(1, GPL);
    Bio = zeros(1, GPL);    theta = zeros(1, GPL);
    HIA = zeros(1, GPL);    delta_Yield = zeros(1, GPL); Yield = zeros(1, GPL);

%根长
for t=1:GPL
    Root(t) = Crop_Root(t,tiorigin,tiending,Rootorigin,Rootending); %根区深度
end
% 积温与积温指数
for t=1:GPL
    HU(t)=max(0, Temp(t) - Tb);
end
HUI = cumsum(HU);
HUI = HUI / PHU;
% 产量计算
for t=1:GPL
    if t==1
        Ksw(t) = Crop_Ksw(fieldcapacity, wilting, thetaorgion);%水分胁迫模块
    else
        Ksw(t) = Crop_Ksw(fieldcapacity, wilting, theta(t-1));%水分胁迫模块
    end
    % 温度胁迫模块
    KTS(t) = max(0, sin(pi/2 * (Temp(t) - Tb) / (TO - Tb)));
    % 胁迫系数
    REG(t) = min(KTS(t), Ksw(t));
    
    %LAI模块
    HUF(t) =max(0, HUI(t)/(HUI(t) + exp(ab1 - ab2*HUI(t))));
    if t == 1
        delta_HUF(t) = HUF(t);
    else
        delta_HUF(t) = max(0, HUF(t) - HUF(t-1));
    end
    
    if HUI(t) < HUI0 % HUI与HUI0的计算
        if t==1
            LAI(t) = delta_HUF(t) * LAImax * (1 - exp((-5) * LAImax)) * real(sqrt(REG(t)));% LAI上升阶段       
            LAI_max_act = LAI(t);
        else
            LAI(t) = LAI(t-1) + delta_HUF(t) * LAImax * (1 - exp(5 * (LAI(t - 1) - LAImax))) * real(sqrt(REG(t)));% LAI上升阶段            
            LAI_max_act = LAI(t);
        end
        if LAI(t) > LAI_max_act
            LAI_max_act = LAI(t);
        end
    else
        LAI(t) = max(0, LAI_max_act * real(((1 - HUI(t))/(1 - HUI0))^ad)); %  LAI下降阶段
    end
    
    % 生物量模块
    PAR(t) = 0.5 * RN(t) * (1 - exp(-0.65 * LAI(t))); 
    delta_Bio(t) = BE * PAR(t) * REG(t);   
    if t == 1
        Bio(t) = delta_Bio(t);
    else
        Bio(t)=Bio(t-1) + delta_Bio(t);
    end
   
    %蒸散发
    ETa(t) = Crop_ET(Kc(t),ET0(t),Ksw(t)); 
    
    % 土壤水分平衡模块 
    if t == 1
        [theta(t),D(t)] = Soil_Water(thetaorgion, EP(t), IQ(t), ETa(t), Root(t), Rootorigin, fieldcapacity, thetaorgion);
    else
        [theta(t),D(t)] = Soil_Water(theta(t - 1), EP(t), IQ(t), ETa(t), Root(t), Root(t - 1), fieldcapacity, thetaorgion);
    end
    
    % 产量模块
%     % HI的计算
%     HIA(t) = HI * (100 * HUI(t))/(100 * HUI(t) + exp(11.1 - 10 * HUI(t)));
%     % delta_Yield(t) = HIA(t) * delta_Bio(t);    
%     delta_Yield(t) = HIA(t) * Bio(t);
%     if t == 1
%         Yield(t) = delta_Yield(t);
%     else
%         Yield(t) = Yield(t-1) + delta_Yield(t);
%     end
    
%     if HUI(t) < HUI0
%         % 生长初期，Pgrain 接近 0
%         Pgrain(t) = 0.1 * (HUI(t) / HUI0) * Ksw(t);
%     else
%         % 生长后期，Pgrain 按 Logistic 函数变化，受水分胁迫调节
%         Pgrain(t) = HI * (HUI(t)^2 / (HUI(t)^2 + (1 - HUI(t))^2)) * Ksw(t);
%     end
%     % 确保 Pgrain 在合理范围 [0, 1]
%     Pgrain(t) = max(0, min(1, Pgrain(t)));
% 
%     % 计算每日产量与秸秆增量
%     delta_Yield(t) = Pgrain(t) * delta_Bio(t);  % 籽粒干物质
%     delta_Straw(t) = (1 - Pgrain(t)) * delta_Bio(t);  % 秸秆干物质
% 
%     % 累积计算总产量与秸秆量
%     if t == 1
%         Yield(t) = delta_Yield(t);
%         Straw(t) = delta_Straw(t);
%     else
%         Yield(t) = Yield(t-1) + delta_Yield(t);
%         Straw(t) = Straw(t-1) + delta_Straw(t);
%     end
    
end
Yield_HI = HI *  Bio(GPL);
Straw_end = 0.9 * (Bio(GPL) - Yield_HI);

% Yield_HI = Yield(GPL);
% Straw_end = Straw(GPL);
% Yield_end =  Yield(GPL);
% Bio_end = Bio(GPL);
% Straw_end = Bio_end - Yield_end;

end


