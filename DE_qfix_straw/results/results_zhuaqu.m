clc;
clear;
for i = 1:3
    for j = 1:3
        filePath1 = sprintf('E:\\7-工作\\02-论文\\023-自己在写的论文2024\\0231-202408\\渠系输水优化\\我自己的模型\\DE_qfix_straw\\results\\4.1\\result_%d_%d.mat', i, j);
        filePath2 = sprintf('E:\\7-工作\\02-论文\\023-自己在写的论文2024\\0231-202408\\渠系输水优化\\我自己的模型\\DE_qfix_straw\\results\\3.28\\result_%d_%d.mat', i, j);
        filePath3 = sprintf('E:\\7-工作\\02-论文\\023-自己在写的论文2024\\0231-202408\\渠系输水优化\\我自己的模型\\DE_qfix_straw\\results\\2.9\\result_%d_%d.mat', i, j);
        optimalIndividual_1 = load(filePath1);
        optimalIndividual_2 = load(filePath2);
        optimalIndividual_3 = load(filePath3);
        
        max_val_1 = max(optimalIndividual_1.objectives(:, 1));
        max_val_2 = max(optimalIndividual_2.objectives(:, 1));
        max_val_3 = max(optimalIndividual_3.objectives(:, 1));
        
        min_val_1 = min(optimalIndividual_1.objectives(:, 1));
        min_val_2 = min(optimalIndividual_2.objectives(:, 1));
        min_val_3 = min(optimalIndividual_3.objectives(:, 1));
        
        max_idx_1 = find(optimalIndividual_1.objectives(:, 1) == max_val_1);
        max_idx_2 = find(optimalIndividual_2.objectives(:, 1) == max_val_2);
        max_idx_3 = find(optimalIndividual_3.objectives(:, 1) == max_val_3);
        
        min_idx_1 = find(optimalIndividual_1.objectives(:, 1) == min_val_1);
        min_idx_2 = find(optimalIndividual_2.objectives(:, 1) == min_val_2);
        min_idx_3 = find(optimalIndividual_3.objectives(:, 1) == min_val_3);
        
        max_val_content_1 = optimalIndividual_1.V1(max_idx_1);
        max_val_content_2 = optimalIndividual_2.V1(max_idx_2);
        max_val_content_3 = optimalIndividual_3.V1(max_idx_3);
        
        min_val_content_1 = optimalIndividual_1.V1(min_idx_1);
        min_val_content_2 = optimalIndividual_2.V1(min_idx_2);
        min_val_content_3 = optimalIndividual_3.V1(min_idx_3);
        
        % 初始化合并结构体数组
        mergedStruct = struct([]);

        % 需要合并的结构体集合
        structList = [max_val_content_1, max_val_content_2, max_val_content_3, ...
                      min_val_content_1, min_val_content_2, min_val_content_3];
                  
        V1 = structList;
        
        filename = sprintf('optimalIndividual_%d_%d.mat', i, j);
        save(filename, 'V1'); % 保存结果
    end
end
