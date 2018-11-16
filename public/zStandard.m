function res = zStandard(inputSeries)
%ZSTANDARD z值标准化，减均值除以标准差

mu = mean(inputSeries, 'omitnan');
sigma = std(inputSeries, 'omitnan');

res = (inputSeries - mu) ./ sigma;

end

