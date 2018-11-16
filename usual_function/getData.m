function data = getData(dataPath,edDate)
% 导入合约数据，格式调整

load(dataPath)
data = TableData(TableData.date<=edDate,:);
data{:,{'open';'close';'high';'low'}} = fillmissing(data{:,{'open';'close';'high';'low'}},'previous');

