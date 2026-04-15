function distances = calculate_crowding_distance(objectives, num_objectives)
    % 计算拥挤度距离
    num_solutions = size(objectives, 1);
    distances = zeros(num_solutions, 1);

    if num_solutions <= 2
        distances(:) = Inf; % 边界解设为无穷大
        return;
    end

    for m = 1:num_objectives
        [~, sorted_idx] = sort(objectives(:, m)); % 按目标排序，最小值应该排在上方
        distances(sorted_idx(1)) = Inf; % 边界解设为无穷大
        distances(sorted_idx(end)) = Inf;

        % 归一化目标值
        norm_range = objectives(sorted_idx(end), m) - objectives(sorted_idx(1), m);
        if norm_range == 0
            norm_range = 1; % 避免除以零
        end

        for i = 2:num_solutions-1
            distances(sorted_idx(i)) = distances(sorted_idx(i)) + ...
                (objectives(sorted_idx(i+1), m) - objectives(sorted_idx(i-1), m)) / norm_range;
        end
    end
end
