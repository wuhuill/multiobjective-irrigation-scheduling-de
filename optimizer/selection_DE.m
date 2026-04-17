function [population, objectives] = selection_DE(population, trialPopulation, objectives, trialObjectives)
% SELECTION_DE
% Select the next generation using non-dominated sorting and crowding distance.
%
% INPUT
%   population       : current parent population
%   trialPopulation   : trial population
%   objectives       : objective matrix of parent population
%                      size = [N x 3]
%   trialObjectives  : objective matrix of trial population
%                      size = [N x 3]
%
% OUTPUT
%   population       : selected population for the next generation
%   objectives       : selected objective matrix
%
% NOTES
%   - All objectives are minimized.
%   - Pareto front ranking is based on non-dominated sorting.
%   - Crowding distance is used to preserve diversity..

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