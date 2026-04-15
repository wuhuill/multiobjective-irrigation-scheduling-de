function [subPopulation3, subPopulation4] = splitSubPopulations(population)
    % 按轮期划分种群
    subPopulation3 = population([population.numStages] == 3);
    subPopulation4 = population([population.numStages] == 4);
end