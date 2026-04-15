function Vnext = tournamentSelection(VsubTrial1, V1, f1_Trial, f1_parent, tournament_size)
    NIND = size(V1, 2);  % 个体数
    Vnext = V1;  % 初始化下一代种群
    
    % **合并上一代和试验个体**
    V_all = [V1, VsubTrial1];  
    f_all = [f1_parent, f1_Trial];  
    
    for i = 1:NIND
        % 随机选择 tournament_size 个个体
        idx = randperm(2 * NIND, tournament_size);  
        
        % 选出适应度最好的个体
        [~, best_idx] = min(f_all(idx));  
        
        % 选择该个体更新到下一代
        Vnext(:, i) = V_all(:, idx(best_idx));  
    end
end

