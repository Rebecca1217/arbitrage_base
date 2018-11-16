function [sigO, sigC, resSignal] = getSignal(data1, data2, realSpread, paraM)
%GETSIGNAL ����realSpread�ķ�Χ��ȡ�������ź�

data1 = table(data1.date, data1.close);
data1.Properties.VariableNames = {'Date', 'CloseJ'};

data2 = table(data2.date, data2.close);
data2.Properties.VariableNames = {'Date', 'CloseJM'};
% nLag = evalin('base', 'nLag');

% 
% jicha.JichaJMA10 = MAx(jicha.JichaJ, 10); % ���MA�ǰ����Լ����ڵ�10��
% jicha.JichaJMMA10 = MAx(jicha.JichaJM, 10);
resSignal = outerjoin(data1, data2, 'type', 'left', 'MergeKeys', true);
% resSignal = outerjoin(resSignal, paraM.jyPrice, 'type', 'left', 'MergeKeys', true);
resSignal = outerjoin(resSignal, realSpread, 'type', 'left', 'MergeKeys', true);
% resSignal = outerjoin(resSignal, jicha, 'type', 'left', 'MergeKeys',
% true); % ����������ݶ���������Լ�ģ���Ӧ���õ��Ǹ��Ժ�Լ��ͷ��β�ģ���Ӧ��ֻ����������
% ���������Ҫjoin���ֻ�����Ȼ���Լ��㣬������ֱ��join��֮ǰ��������Ļ���
% resSignal = outerjoin(resSignal, xianhuo, 'type', 'left', 'MergeKeys', true);
% resSignal.JichaJ = resSignal.PriceJ - resSignal.CloseJ;
% resSignal.JichaJM = resSignal.PriceJM - resSignal.CloseJM;
% resSignal.JichaDiff = resSignal.JichaJ - 1 / paraM.rate * resSignal.JichaJM;
% jichaDiffnLag = [nan(nLag, 1); resSignal.JichaDiff(1 : (end - nLag))];
% jichaDiffChg = resSignal.JichaDiff - jichaDiffnLag;
%  % �ù�ȥnLag��Ļ���Diff�仯��Ϊ������nLag��ı仯
% resSignal.SpreadTheory = resSignal.YRealNLag - resSignal.JichaDiff + jichaDiffChg; % nLag�����ֻ�����������ʵֵ�� - �������Diff + ����Diff�ı仯����ȥnLag����棩

% �����ϵ���������
% J�� - 1.35*JM�� = J�� - 1.35 * JM�� + ��J���� - 1.35 * JM���
% 2018.11.7 ���⹹��Spreadʱ��ֻ�����J��JM����Ʒ�֣���Ҫ�ӻ���ͽ��ͣ���Ϊ�������ʱ��ֻ�ܲ���������Ʒ��
% �����Ļ�Spread�������еĶֽ�����֮����ʵ��Ȼ���в��죺1���̶����ú͸���Ʒ����Ӱ�죻2�������Ӱ��
% resSignal.Spread = resSignal.CloseJ - 1 / paraM.rate * resSignal.CloseJM + ...
%     resSignal.JichaJMA10 - 1 / paraM.rate * resSignal.JichaJMMA10 - ...
%     paraM.fixedExpense + paraM.jiaoyouRatio * resSignal.PriceJY;
% resSignal.Spread = resSignal.CloseJ - 1 / paraM.rate * resSignal.CloseJM - ...
%     paraM.fixedExpense + resSignal.JichaJMA10 - 1 / paraM.rate * resSignal.JichaJMMA10;
resSignal.Spread = resSignal.CloseJ - 1 / paraM.rate * resSignal.CloseJM - paraM.fixedExpense;

spreadMA = MAx(resSignal.Spread, paraM.xMA);
% resSignal.UnderlyingSpread = spreadMA * paraM.proportion + resSignal.YHat * (1 - paraM.proportion);
resSignal.UnderlyingSpread = spreadMA * paraM.proportion + resSignal.YHat * (1 - paraM.proportion);
% 2018.11.13 proportion * MA + (1 - proportion) * �ع���ϵ�nLag������� ��Ϊ��ʵ�۲�����
resSignal.SpreadUp = resSignal.UnderlyingSpread + paraM.interval;
resSignal.SpreadDown = resSignal.UnderlyingSpread - paraM.interval;
% resSignal.SpreadUp = ones(size(resSignal.UnderlyingSpread, 1), 1) .* -50;
% resSignal.SpreadDown = ones(size(resSignal.UnderlyingSpread, 1), 1) .* -150;
% resSignal.UnderlyingSpread = ones(size(resSignal.UnderlyingSpread, 1), 1) .* -100;



% ��ĿǰΪֹ��resSignal�е�Spread���������жϵļ۲����ߣ�YHat���������ϵļ۲����ߣ�SpreadDown��SpreadUp���Ŵ�
% ���Ŵ���90% ��Χ̫�󣬸�Ϊ60%
% ���ԣ���Spread����ͻ��SpreadUpʱ���ռ۲Spread����ͻ��SpreadDown��ʱ������۲�
% ����ͻ�ƻ��߻ع鵽YHatʱƽ��

spreadBF1 = [NaN; resSignal.Spread(1 : end - 1)];
spreadDownBF1 = [NaN; resSignal.SpreadDown(1 : end - 1)];
spreadUpBF1 = [NaN; resSignal.SpreadUp(1 : end - 1)];
underlyingSpreadBF1 = [NaN; resSignal.UnderlyingSpread(1 : end - 1)];

sigO = zeros(size(resSignal, 1), 1); 
sigC = zeros(size(resSignal, 1), 1);
% long signal
L = spreadBF1 < spreadDownBF1 & resSignal.Spread > resSignal.SpreadDown; % Spread����ͻ��SpreadDown
CL = (spreadBF1 > spreadDownBF1 & resSignal.Spread < resSignal.SpreadDown) | (...
    spreadBF1 < underlyingSpreadBF1 & resSignal.Spread > resSignal.UnderlyingSpread); % Spread������ֹ�����Spread����ͻ��yHatƽ��
% short signal
S = spreadBF1 > spreadUpBF1 & resSignal.Spread < resSignal.SpreadUp; % Spread ����ͻ��SpreadUp
CS = (spreadBF1 < spreadUpBF1 & resSignal.Spread > resSignal.SpreadUp) | (...
    spreadBF1 > underlyingSpreadBF1 & resSignal.Spread < resSignal.UnderlyingSpread); % Spread������ֹ�����Spread����ͻ��YHatƽ��

sigO(L) = 1;
sigO(S) = -1;

sigC(CL) = -1;
sigC(CS) = 1;

end
