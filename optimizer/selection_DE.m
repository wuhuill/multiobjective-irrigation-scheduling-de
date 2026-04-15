function [population, objectives] = selection_DE(population, trialPopulation, objectives, trialObjectives)
% Combine parent and trial populations, then keep the best N using
% non-dominated sorting + crowding distance.

combinedPopulation = [population; trialPopulation];
combinedObjectives = [objectives; trialObjectives];

N = numel(population);

[FrontNo, CrowdDis] = NDSort(combinedObjectives, inf);
selectedIdx = select_by_rank_crowding(FrontNo, CrowdDis, N);

population = combinedPopulation(selectedIdx);
objectives = combinedObjectives(selectedIdx, :);
end

function selectedIdx = select_by_rank_crowding(FrontNo, CrowdDis, N)
selectedIdx = [];
front = 1;

while numel(selectedIdx) + sum(FrontNo == front) <= N
    selectedIdx = [selectedIdx; find(FrontNo == front)]; %#ok<AGROW>
    front = front + 1;
end

remaining = find(FrontNo == front);
if ~isempty(remaining)
    [~, order] = sort(CrowdDis(remaining), 'descend');
    need = N - numel(selectedIdx);
    selectedIdx = [selectedIdx; remaining(order(1:min(need, numel(order))))];
end
end