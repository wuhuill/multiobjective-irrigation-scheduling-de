clear;
clc;
for i = 1:3
    for j = 1:3
        
        filePath1 = sprintf('result_%d_%d.mat', i, j);
        result = load(filePath1);
        
        [a_sorted, idx] = sort(result.paretoObjectives(:,1), 'descend');  % 按第一列降序排序
        result.paretoObjectives = result.paretoObjectives(idx, :);  % 重新排列 a
        result.paretoSolutions = result.paretoSolutions(idx);  % 重新排列 b
        
    end
end
