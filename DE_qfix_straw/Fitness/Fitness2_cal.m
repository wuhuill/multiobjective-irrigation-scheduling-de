% 所有目标适应度计算，不能在主程序里单独计算每个目标的适应度
function Fitness = Fitness2_cal(v, params)

start_time_wheat=params.start_time_wheat ; end_time_wheat=params.end_time_wheat ; % 小麦生育期开始时间与结束时间
start_time_maize=params.start_time_maize ; end_time_maize=params.end_time_maize ; % 玉米生育期开始时间与结束时间
GPL= max(end_time_wheat,end_time_maize);

%渠系参数
I=params.I;% 支渠条数
A=params.A; m_canal=params.m_canal; l=params.l;% 计算支渠流量损失的参数
qd=params.qd;% 支渠的设计流量，m3/s
Qgd=params.Qgd;% 干渠的设计流量，m3/s
Ag=params.Ag; lg=params.lg; mg=params.mg; % 计算干渠流量损失的参数
W=params.W;  %可用水量 m3
% 每条渠的小麦/玉米的控制面积，单位为ha
Area_wheat = params.Area_wheat; 
Area_maize = params.Area_maize; 


% 每条渠的小麦/玉米的灌水量，由遗传算法主程序随机生成，并将其转化为三维矩阵
IQwheat = v(:, 1:I*(end_time_wheat-start_time_wheat+1));%单位为mm
IQwheat = reshape(IQwheat, [size(v, 1),end_time_wheat-start_time_wheat+1, I]);
IQwheat = permute(IQwheat,[1,3,2]);
IQmaize = v(:, I*(end_time_wheat-start_time_wheat+1)+1:end);%单位为mm
IQmaize = reshape(IQmaize, [size(v, 1),end_time_maize-start_time_maize+1, I]);
IQmaize = permute(IQmaize,[1,3,2]);
IQwheat_all = zeros(size(v, 1), I, GPL); 
IQmaize_all = zeros(size(v, 1), I, GPL);
IQwheat_all (:, :, start_time_wheat:end_time_wheat) = IQwheat;
IQmaize_all (:, :, start_time_maize:end_time_maize) = IQmaize;

% 支渠流量
    Wz = 10 * IQwheat_all.* reshape(Area_wheat, [1, I, 1]) + 10 * IQmaize_all.* reshape(Area_maize, [1, I, 1])/(0.9 * 0.6);
    qz = Wz / 86400; % 每条支渠每天的净流量 [size(v, 1), I, GPL]      
    m_canal_expanded = reshape(m_canal, [1, I, 1]); % 确保 m_canal 的维度与 qz 匹配
    qzs = (reshape(A,[1,I,1]) .* reshape(l,[1,I,1])) .* (qz.^ (1 - m_canal_expanded)) / 100;
    qzm = qz + qzs; % [size(v, 1), I, GPL]  计算每条支渠每天的毛流量
% 干渠流量
    Qg = squeeze(sum(qzm, 2)); % [size(v, 1), GPL]  计算干渠的净流量（所有支渠毛流量之和）
    Qgs = Ag*lg*Qg.^(1-mg)/100;
    Qgm = Qgs + Qg; 
% 总水量
    Wgm =sum(Qgm*86400,2);    
    qd_all = repmat(qd', [size(v,1), 1, GPL]);
    Qgd_all = 1.2 * Qgd * ones(size(v,1), GPL);
    W_all = W * ones(size(v,1),1);
    
    f2=newobj2(v,params); 
    
for j = 1:size(v, 1)
    if any(qzm(j,:,:) > 1.2 * qd_all(j,:,:)) |any(Qgm(j,:) > 1.2 * Qgd_all(j,:)) | any(Wgm(j) > W_all(j))
        penalty = 10^7*10^3; % 罚函数的强度，可以根据需要调整
        f2(j) = f2(j) + penalty;
    else
        f2(j) = f2(j);
    end
end
% 适应度
Fitness=ranking(f2);

end
