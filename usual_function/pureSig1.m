function [sigLi] = pureSig1(sig)
%PURESIG1 信号处理第一步，从最原始的触发信号到第一版信号匹配结果
% tdList:持仓方向，开仓时点，开仓价差，平仓价差, 品种1手数，品种2手数，当日盈亏金额,累计资产
% 用开仓前一天的收盘价计算开仓手数
% c_edD是旧合约的最后一天，旧合约在平仓时，应该在下一日平仓

% 加入止损以后需要把这个再调整一下，在遇到平仓信号之前的开仓信号都不要越过去，保留比如38 42  40 42这样的嵌套配对

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
        %         c = clL;
        c = c + 1; % 2018.10.12修改，38 42 40 42配对
    end
end
sigLi(sigLi(:,1)==0,:) = [];


end

