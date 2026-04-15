function [thetaiafter,Di] = Soil_Water(thetai, EPi, IQi, ETai, Rooti, Rootbeforei, fieldcapacity, thetaorigin)
%function [IQi]= Soil_Water(thetaiafter,thetai,EPi,ETai,Rooti,Rootbeforei,thetaorigin)
%SOIL_WATER 土壤水动态
%   thetai 土壤体积含水率
%   EPi 有效降水量，mm
%   IQi 灌水量，mm
%   ETa 蒸散发，mm
thetaiafter = min(1000 * fieldcapacity * Rooti, 1000 * thetai * Rooti + 1000 * thetaorigin * (Rooti - Rootbeforei) + EPi + IQi - ETai) / (1000 * Rooti); % 24h终了的土壤含水率
Di = min(0,(1000 * thetai* Rooti + 1000 * thetaorigin * (Rooti - Rootbeforei) + EPi + IQi - ETai) - 1000 * fieldcapacity * Rooti);% 排水量
% IQi=1000*Rooti*thetaiafter-(1000*thetai*Rooti+1000*thetaorigin*(Rooti-Rootbeforei))-EPi+ETai;
end

