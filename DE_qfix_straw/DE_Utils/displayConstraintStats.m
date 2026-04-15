function displayConstraintStats(stats3, stats4)
    % 显示约束满足率统计信息
    fprintf('--- Constraint Statistics ---\n');
    fprintf('3-stage population: %d total, %d violations (%.2f%%)\n', ...
            stats3.total, stats3.violations, 100 * stats3.violations / stats3.total);
    fprintf('4-stage population: %d total, %d violations (%.2f%%)\n', ...
            stats4.total, stats4.violations, 100 * stats4.violations / stats4.total);
end