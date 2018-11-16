function [sigO, sigC, resSignal] = getSignal(data1, data2, realSpread, paraM)
%GETSIGNAL 根据realSpread的范围获取进出场信号

data1 = table(data1.date, data1.close);
data1.Properties.VariableNames = {'Date', 'CloseJ'};

data2 = table(data2.date, data2.close);
data2.Properties.VariableNames = {'Date', 'CloseJM'};
% nLag = evalin('base', 'nLag');

% 
% jicha.JichaJMA10 = MAx(jicha.JichaJ, 10); % 这个MA是包含自己在内的10天
% jicha.JichaJMMA10 = MAx(jicha.JichaJM, 10);
resSignal = outerjoin(data1, data2, 'type', 'left', 'MergeKeys', true);
% resSignal = outerjoin(resSignal, paraM.jyPrice, 'type', 'left', 'MergeKeys', true);
resSignal = outerjoin(resSignal, realSpread, 'type', 'left', 'MergeKeys', true);
% resSignal = outerjoin(resSignal, jicha, 'type', 'left', 'MergeKeys',
% true); % 这个基差数据都是主力合约的，但应该用的是各自合约从头到尾的，不应该只用主力部分
% 这里基差需要join上现货数据然后自己算，而不是直接join上之前用主力算的基差
% resSignal = outerjoin(resSignal, xianhuo, 'type', 'left', 'MergeKeys', true);
% resSignal.JichaJ = resSignal.PriceJ - resSignal.CloseJ;
% resSignal.JichaJM = resSignal.PriceJM - resSignal.CloseJM;
% resSignal.JichaDiff = resSignal.JichaJ - 1 / paraM.rate * resSignal.JichaJM;
% jichaDiffnLag = [nan(nLag, 1); resSignal.JichaDiff(1 : (end - nLag))];
% jichaDiffChg = resSignal.JichaDiff - jichaDiffnLag;
%  % 用过去nLag天的基差Diff变化作为接下来nLag天的变化
% resSignal.SpreadTheory = resSignal.YRealNLag - resSignal.JichaDiff + jichaDiffChg; % nLag天后的现货利润（暂用真实值） - 当天基差Diff + 基差Diff的变化（过去nLag天代替）

% 理论上的炼焦利润：
% J现 - 1.35*JM现 = J期 - 1.35 * JM期 + （J基差 - 1.35 * JM基差）
% 2018.11.7 在这构造Spread时候只能设计J和JM两个品种，不要加基差和焦油，因为你操作的时候只能操作这两个品种
% 这样的话Spread和理想中的吨焦利润之间其实天然就有差异：1、固定费用和副产品收入影响；2、基差的影响
% resSignal.Spread = resSignal.CloseJ - 1 / paraM.rate * resSignal.CloseJM + ...
%     resSignal.JichaJMA10 - 1 / paraM.rate * resSignal.JichaJMMA10 - ...
%     paraM.fixedExpense + paraM.jiaoyouRatio * resSignal.PriceJY;
% resSignal.Spread = resSignal.CloseJ - 1 / paraM.rate * resSignal.CloseJM - ...
%     paraM.fixedExpense + resSignal.JichaJMA10 - 1 / paraM.rate * resSignal.JichaJMMA10;
resSignal.Spread = resSignal.CloseJ - 1 / paraM.rate * resSignal.CloseJM - paraM.fixedExpense;

spreadMA = MAx(resSignal.Spread, paraM.xMA);
% resSignal.UnderlyingSpread = spreadMA * paraM.proportion + resSignal.YHat * (1 - paraM.proportion);
resSignal.UnderlyingSpread = spreadMA * paraM.proportion + resSignal.YHat * (1 - paraM.proportion);
% 2018.11.13 proportion * MA + (1 - proportion) * 回归拟合的nLag天后利润 作为真实价差曲线
resSignal.SpreadUp = resSignal.UnderlyingSpread + paraM.interval;
resSignal.SpreadDown = resSignal.UnderlyingSpread - paraM.interval;
% resSignal.SpreadUp = ones(size(resSignal.UnderlyingSpread, 1), 1) .* -50;
% resSignal.SpreadDown = ones(size(resSignal.UnderlyingSpread, 1), 1) .* -150;
% resSignal.UnderlyingSpread = ones(size(resSignal.UnderlyingSpread, 1), 1) .* -100;



% 到目前为止，resSignal中的Spread就是用于判断的价差曲线，YHat就是理论上的价差曲线，SpreadDown和SpreadUp置信带
% 置信带用90% 范围太大，改为60%
% 试试，当Spread向下突破SpreadUp时做空价差，Spread向上突破SpreadDown的时候做多价差
% 反向突破或者回归到YHat时平仓

spreadBF1 = [NaN; resSignal.Spread(1 : end - 1)];
spreadDownBF1 = [NaN; resSignal.SpreadDown(1 : end - 1)];
spreadUpBF1 = [NaN; resSignal.SpreadUp(1 : end - 1)];
underlyingSpreadBF1 = [NaN; resSignal.UnderlyingSpread(1 : end - 1)];

sigO = zeros(size(resSignal, 1), 1); 
sigC = zeros(size(resSignal, 1), 1);
% long signal
L = spreadBF1 < spreadDownBF1 & resSignal.Spread > resSignal.SpreadDown; % Spread向上突破SpreadDown
CL = (spreadBF1 > spreadDownBF1 & resSignal.Spread < resSignal.SpreadDown) | (...
    spreadBF1 < underlyingSpreadBF1 & resSignal.Spread > resSignal.UnderlyingSpread); % Spread反向下止损或者Spread向上突破yHat平仓
% short signal
S = spreadBF1 > spreadUpBF1 & resSignal.Spread < resSignal.SpreadUp; % Spread 向下突破SpreadUp
CS = (spreadBF1 < spreadUpBF1 & resSignal.Spread > resSignal.SpreadUp) | (...
    spreadBF1 > underlyingSpreadBF1 & resSignal.Spread < resSignal.UnderlyingSpread); % Spread反向上止损或者Spread向下突破YHat平仓

sigO(L) = 1;
sigO(S) = -1;

sigC(CL) = -1;
sigC(CS) = 1;

end

