% 所有目标适应度计算，不能在主程序里单独计算每个目标的适应度
function Fitness1 = Fitness1_cal(v, params)
    % 提取参数
    start_time_wheat = params.start_time_wheat;
    end_time_wheat = params.end_time_wheat;
    start_time_maize = params.start_time_maize;
    end_time_maize = params.end_time_maize;
    GPL = max(end_time_wheat, end_time_maize);

    % 渠系参数
    I = params.I;
    A = params.A;
    m_canal = params.m_canal;
    l = params.l;
    qd = params.qd;
    Qgd = params.Qgd;
    Ag = params.Ag;
    lg = params.lg;
    mg = params.mg;
    W = params.W;
    Area_wheat = params.Area_wheat;
    Area_maize = params.Area_maize;

    % 每条渠的小麦/玉米的灌水量
    IQwheat = v(:, 1:I*(end_time_wheat-start_time_wheat+1)); % 单位为mm
    IQwheat = reshape(IQwheat, [size(v, 1), end_time_wheat-start_time_wheat+1, I]);
    IQwheat = permute(IQwheat, [1, 3, 2]);
    IQmaize = v(:, I*(end_time_wheat-start_time_wheat+1)+1:end); % 单位为mm
    IQmaize = reshape(IQmaize, [size(v, 1), end_time_maize-start_time_maize+1, I]);
    IQmaize = permute(IQmaize, [1, 3, 2]);
    IQwheat_all = zeros(size(v, 1), I, GPL);
    IQmaize_all = zeros(size(v, 1), I, GPL);
    IQwheat_all(:, :, start_time_wheat:end_time_wheat) = IQwheat;
    IQmaize_all(:, :, start_time_maize:end_time_maize) = IQmaize;

    % 支渠流量
    Wz = (10 * IQwheat_all.* reshape(Area_wheat, [1, I, 1]) + 10 * IQmaize_all.* reshape(Area_maize, [1, I, 1]))/(0.9 * 0.6 * 0.8); % 田间水利用效率 ET占比 斗渠和农渠输水效率
    qz = Wz / 86400; % 每条支渠每天的净流量 [size(v, 1), I, GPL]
    m_canal_expanded = reshape(m_canal, [1, I, 1]); % 确保 m_canal 的维度与 qz 匹配
    qzs = (reshape(A, [1, I, 1]) .* reshape(l, [1, I, 1])) .* (qz .^ (1 - m_canal_expanded)) / 100;
    qzm = qz + qzs; % [size(v, 1), I, GPL] 计算每条支渠每天的毛流量

    % 干渠流量
    Qg = squeeze(sum(qzm, 2)); % [size(v, 1), GPL] 计算干渠的净流量（所有支渠毛流量之和）
    Qgs = Ag * lg * Qg .^ (1 - mg) / 100;
    Qgm = Qgs + Qg;

    % 总水量
    Wgm = sum(Qgm * 86400, 2);
    qd_all = repmat(qd', [size(v,1), 1, GPL]);
    Qgd_all = 1.2 * Qgd * ones(size(v,1), GPL);
    W_all = W * ones(size(v,1),1);
    
    % 目标函数值
    f1 = newobj1(v, params);
    
    % 罚函数
    for j = 1:size(v, 1)
        if any(qzm(j,:,:) > 1.2 * qd_all(j,:,:)) | any(Qgm(j,:) > Qgd_all(j,:)) | any(Wgm(j) > W_all(j))
            % fitnessaaa=1
            penalty= 100000; % 罚函数的强度，可以根据需要调整        
            f1(j) = f1(j) + penalty;
        else
            f1(j) = f1(j);
        end
    end
    
    % 适应度
    Fitness1 = ranking(f1);
end
