clear;
clc;
all_paretoObjectives = [];
for i = 1:3
    for j = 1:3
        
        filePath1 = sprintf('result_%d_%d.mat', i, j);
        result = load(filePath1);
        
        [a_sorted, idx] = sort(result.paretoObjectives(:,1), 'descend');  % 按第一列降序排序
        paretoObjectives = result.paretoObjectives(idx, :);  % 重新排列 a
        paretoSolutions = result.paretoSolutions(idx);  % 重新排列 b
       
        filename = sprintf('reanalyze_result_%.d_%.d.mat', i, j);
        save(filename,'paretoObjectives', 'paretoSolutions' );
        
        maxRows = max(size(all_paretoObjectives,1), size(paretoObjectives,1));  % 计算最大行数
        
        % 用 NaN 填充较小的矩阵
        A_padded = padarray(all_paretoObjectives, [maxRows-size(all_paretoObjectives,1), 0], NaN, 'post');
        B_padded = padarray(paretoObjectives, [maxRows-size(paretoObjectives,1), 0], NaN, 'post');
        
        % 水平拼接
        all_paretoObjectives = [A_padded, B_padded];
        
    end
end


