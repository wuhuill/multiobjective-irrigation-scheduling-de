% 示例数据（你需要替换为真实数据）
% 读取文件
filename = 'water_threshold';
data = readtable(filename);

% 提取第一列作为用水量指标
waterUsage = data{:, 1};

% 提取后三列作为三个指标值
indicator1 = data{:, 2};
indicator2 = data{:, 3};
indicator3 = data{:, 4};

% 合并所有数据
data = [waterUsage, indicator1, indicator2, indicator3];

% 设定簇的数量
numClusters = 5;

% 进行 K - 均值聚类
[idx, ~] = kmeans(data, numClusters);

% 查找聚类标签变化的位置
changePoints = find(diff(idx) ~= 0);

% 绘制用水量数据和突变点
figure;
plot(waterUsage);
hold on;
plot(changePoints + 1, waterUsage(changePoints + 1), 'ro', 'MarkerFaceColor', 'r');
xlabel('时间');
ylabel('用水量');
title('基于 K - 均值聚类的突变点检测');
legend('用水量', '突变点');