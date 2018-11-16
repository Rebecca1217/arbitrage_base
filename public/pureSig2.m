function sigLi = pureSig2(sigLi, date, oriAsset, c_stD, c_edD, sig)
%PURESIG2 
% pure_signal的最后阶段，剔除掉多余的信号

% 开平仓信号根据合约做主力的时间进行调整

stL = find(date==c_stD,1);
edL = find(date==c_edD,1);
% 开始
stS = find(and(sigLi(:,2)<=stL,sigLi(:,3)>=stL),1,'first'); %这个合约作为主力合约之时的第一个开仓信号，主力之前就开仓，主力后才平仓的情况
if isempty(stS) %第一个合约可能有这个问题，因为是从某个品种的上市日开始的
    stS = find(and(sigLi(:,2)>=stL,sigLi(:,2)<=edL),1,'first'); % 如果没有上述情况，就找第一个主力后才开仓的信号
    if isempty(stS) %在这个合约作为主力合约期间，没有发出开仓信号
        tdList = [date,zeros(length(sig),8)];
        tdList(:,end) = oriAsset;
        sigAdj = zeros(size(sig));
        sigLi(1:stS-1,:) = []; %把该合约还没作为主力合约时候的开仓信号去掉
        return;
    end
elseif stS>1
    sigLi(1:stS-1,:) = []; %把该合约还没作为主力合约时候的开仓信号去掉
    sigLi(1,2) = stL-1;  % 有开仓未平的话改为换月第一天发出开仓信号
end

% 结束
edS = find(and(sigLi(:,2)<=edL,sigLi(:,3)>=edL),1,'last'); %这个合约作为主力合约之后的最后一个开仓信号
if isempty(edS) %如果找不到这种信号：在这个时点之前平仓了，但是没有新的开仓信号
    edS = find(sigLi(:,3)<=edL,1,'last'); %在这个时点之前最后一个平仓信号所在行
    sigLi(edS+1:end,:) = [];
else
    sigLi(edS+1:end,:) = [];
    sigLi(end,3) = edL; % 这里开仓未平的话是要平的

end

end

