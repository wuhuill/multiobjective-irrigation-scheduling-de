function [Rooti] = Crop_Root(ti,tiorigin,tiending,Rootorigin,Rootending)
%根区随时间的发展
%   tiorigin 为根区开始发展时间，d
%   tiending 为根区发展停止时间，d
%   Rootorigin 为根区初始深度，m
%   Rootending 为根区最终深度，m
%   这些参数与作物类型有关
    if ti <= tiorigin %  
        Rooti = Rootorigin;  
        elseif ti > tiending
        Rooti = Rootending;  
    else
        Rooti = (Rootorigin + (Rootending - Rootorigin) / (tiending - tiorigin) * (ti - tiorigin)); %%计算各个时刻根部长度
    end    
end

