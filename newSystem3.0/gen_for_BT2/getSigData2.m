function sigData = getSigData2(signal,tdDate)
% 每一个信号对应的开平仓所在行
% signal:单个品种对应的信号和日期
% 注：如果最后一个交易信号对应的平仓信号没有发出，则最后一个信号的平仓时间记为nan
% 20180710：大改动：平仓信号的行标是前一版行标+1

signal = signal(signal(:,1)>=tdDate(1) & signal(:,1)<=tdDate(end),:);
signal = signal(:,2);
% 分多空头分别处理
sigLong = signal;
sigLong(signal==-1) = 0;
sigShort = signal;
sigShort(signal==1) = 0;
sigShort(signal==-1) = 1;
if sum(sigLong)~=0
    sigLiLong = getSigLines(sigLong);
else
    sigLiLong = [];
end
if sum(sigShort)~=0
    sigLiShort = getSigLines(sigShort);
    sigLiShort(:,1) = -1;
else
    sigLiShort = [];
end
sigData = sortrows([sigLiLong;sigLiShort],2);

end



