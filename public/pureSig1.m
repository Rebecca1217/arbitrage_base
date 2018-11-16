function [sigLi] = pureSig1(sig)
%PURESIG1 信号处理第一步，从最原始的触发信号到第一版信号匹配结果
% tdList:持仓方向，开仓时点，开仓价差，平仓价差, 品种1手数，品种2手数，当日盈亏金额,累计资产
% 用开仓前一天的收盘价计算开仓手数
% c_edD是旧合约的最后一天，旧合约在平仓时，应该在下一日平仓

% 加入止损以后需要把这个再调整一下，在遇到平仓信号之前的开仓信号都不要越过去，保留比如38 42  40 42这样的嵌套配对
% @2018.09.27 调整信号，如果开仓日遇到跳价则排除本段信号
lines = evalin('base', 'lines');

% 开平仓信号
sigOp = sig(:,1);
sigCl = sig(:,2);
% 开平仓信号所在行
sigLi = zeros(length(sigOp),3); % 方向，开平信号所在行
c = 1;
for t = 1:size(sigLi,1)
    opL = find(sigOp(c:end)~=0,1,'first')+c-1;
    if isempty(opL) || opL==length(sigOp)
        break;
    else
        sigLi(t,1) = sigOp(opL);
        sigLi(t,2) = opL;
    end
    clL = find(sigCl(opL+1:end)==-sigOp(opL),1,'first')+opL;
    if isempty(clL)
        sigLi(t,3) = size(sigLi,1);
        break;
    else
        sigLi(t,3) = clL;
        c = clL;
    end
end
sigLi(sigLi(:,1)==0,:) = [];

% % @2018.09.27 下面这段新加，用于剔除开仓遇到跳价的信号段
% sigLi(:, size(sigLi, 2) + 1) = NaN; % 加一列是否排除的if_valid,1表示保留信号，0表示需排除的信号
% 
% for iRow = 1 : size(sigLi, 1)
%     if lines.SpreadDiff(sigLi(iRow, 2)) >= lines.PriceDiffBoundaryDown(sigLi(iRow, 2)) && ...
%             lines.SpreadDiff(sigLi(iRow, 2)) <= lines.PriceDiffBoundaryUp(sigLi(iRow, 2))
%         sigLi(iRow, size(sigLi, 2)) = 1;
%     else
%         sigLi(iRow, size(sigLi, 2)) = 0;
%     end
% end
% 
% sigLi(sigLi(:, size(sigLi, 2)) == 0, :) = []; 
% sigLi(:, size(sigLi, 2)) = [];

end

