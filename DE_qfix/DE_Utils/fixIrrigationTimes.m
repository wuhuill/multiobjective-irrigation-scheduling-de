function [start, end_] = fixIrrigationTimes(start, end_, minDuration)
    % 优化灌溉开始和结束时间修复
    if end_ - start + 1 < minDuration
        end_ = start + minDuration - 1;
    end
end

