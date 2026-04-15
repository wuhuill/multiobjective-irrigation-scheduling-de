clc; clear; close all;
addpath(genpath(pwd));

params = params_demo();
load('demo_weather.mat', 'weather');

% 初始化
population = initialization(params.popSize, params);

% 初始评价
objectives = objective_wrapper(population, params, weather);

% 主循环
for gen = 1:params.maxGen
    [population, objectives] = DE_main(population, objectives, params, weather);

    [FrontNo, ~] = NDSort(objectives, inf);
    paretoSize = sum(FrontNo == 1);

    fprintf('Generation %d completed. Pareto size = %d\n', gen, paretoSize);
end

% 提取 Pareto 前沿
[FrontNo, ~] = NDSort(objectives, inf);
paretoIdx = (FrontNo == 1);
paretoSolutions = population(paretoIdx);
paretoObjectives = objectives(paretoIdx, :);

save('pareto_results.mat', 'population', 'objectives', 'paretoSolutions', 'paretoObjectives');

disp('Optimization finished. Results saved to pareto_results.mat');