function res = formatAdj(inputTable)
%FORMATADJ 专门用于Python存储的CSV文件数据格式调整，调整yyyy-mm-dd格式日期， 调整字符型为数值

inputTable.Properties.VariableNames = {'Date', 'Value'};
% 将 yyyy-mm-dd datetime格式日期改为MATLAB yyyymmdd数值格式日期
colDate = table(inputTable.Date);

% 改字符串格式的yyyy-mm-dd代码：
% idx = strfind(vDate, '-');
% y = zeros(length(vDate), 1);
% m = zeros(length(vDate), 1);
% d = zeros(length(vDate), 1);
% for i = 1 : length(vDate)
% y(i) = str2double(vDate{i}(1 : (idx{i}(1) - 1)));
% m(i) = str2double(vDate{i}((idx{i}(1) + 1) : (idx{i}(2) - 1)));
% d(i) = str2double(vDate{i}((idx{i}(2) + 1) : end));
% end
% vDate = y .* 10000 + m .* 100 + d;
colDate = rowfun(@(x, y) datestr(x, 'yyyymmdd'), colDate);
colDate = rowfun(@(x) str2double(x), colDate);

% convert value from char to double
colValue = inputTable.Value;
colValue = cellfun(@(x, y, z) ifelse(strcmp(x, '-'), y, z), ...
    colValue, repmat({NaN}, size(inputTable, 1), 1), colValue, 'UniformOutput', false);
colValue = str2double(colValue);

res = table(colDate.Var1, colValue);
res.Properties.VariableNames = {'Date', 'Value'};

end

