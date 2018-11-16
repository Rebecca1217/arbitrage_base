function outputMAPrice = MAx(priceSeries, x)
%MAx input priceSeries and x, output is the x-day avg price
% leave the first (x-1) day NaN
narginchk(2,2); 
if x > length(priceSeries)
    error('x is too large for priceSeries!')
end

iDay = 1;
res = NaN(length(priceSeries), x);
while iDay <= x
    addColumn = [NaN(iDay - 1, 1); priceSeries(1 : (end - iDay + 1))];
    res(:, iDay) = addColumn;
    iDay = iDay + 1;
end

outputMAPrice = sum(res, 2) / x;

end

