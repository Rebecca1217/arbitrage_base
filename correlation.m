% regData.Profit是预测焦厂利润（日度）
% 读取钢联焦厂利润周度数据
% 用周度数据查看相关系数
JProfit = readtable('C:\Users\fengruiling\Desktop\JJMdata\JProfit_bck.xlsx');
JProfit.Properties.VariableNames = {'Date', 'JProfitData'};
JProfit.Date = datestr(JProfit.Date, 'yyyymmdd');
convertDate = table(JProfit.Date);
JProfit.Date = table2array(rowfun(@(x) str2double(x), convertDate));


projectedProfit = regData(:, 1:2);

res = outerjoin(JProfit, projectedProfit, 'type', 'left', 'MergeKeys', true);
res.Profit = fillmissing(res.Profit, 'previous');

% 未用到插补，仅看周度数据的相关性 仍然是非常高的
corr(res.JProfitData, res.Profit, 'Type', 'Pearson')
corr(res.JProfitData(1:25), res.Profit(1:25), 'Type', 'Spearman')
corr(res.JProfitData, res.Profit, 'Type', 'Kendall')





