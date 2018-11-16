cd E:\Repository\arbitrage_base
addpath public newSystem3.0\gen_for_BT2 newSystem3.0 usual_function

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%2018.11.15
%%%%%%%%%%%regData.ProductionRatio��regData.GCProfitRatio������������regData.Profit�����ϵ���ܵͣ���������������������
% �ܶȿ�������չ���նȶ��ܵͣ�ProductionRatio��0.16, GCProfitRatio 0. 29
% productionRatio�ͽ�̿�ֻ��۸������0.37����˵productionRatioԽ�ߣ�����Խ�࣬Ӧ�ø���أ�



dateBegin = 20130302; % ѵ��
dateEnd = 20170929; % ѵ�� % c_edD�����ǽ����գ���Ȼtotaldate���涨λ����
% dateBegin = 20170701; % ��֤
% dateEnd = 20180330; % ��֤
% dateBegin = 20180101; % ����
% dateEnd = 20181029; % ����


% ���ײ���
paraM.rate = 1 / 1.35; %%���rateһ��Ҫע�⡣����Ҫ���ĳ�1.35���ĵĻ�calOpenHandsһ��Ҫ���Ÿģ���ÿ�ν��Ҫ���һ�������ȶԲ��ԣ���
JMRatio.Zhu = 0.35;
JMRatio.OneThird = 0.25;
JMRatio.Qi = 0.12;
JMRatio.Fei = 0.18;
JMRatio.Shou = 0.1;
paraM.fixedExpense = 150;

testRes = nan(13, 11);
testRegressR2 = nan(3, 50);
seq = 0:0.1:1;
for iTest = 1 
% paraM.jiaoyouRatio = 0.05; % ����һ�ֽ�̿��ͬʱ����0.05��ú���͸���Ʒ
% ú���ͼ۸�2900 - 4000 ������������Ӱ����145~200֮�䣬����150�ɣ��͹̶��ɱ��ϵ�һ��
%%%%%%%%%%%%%%%%3���ؼ�������%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
paraM.proportion = 0.98; % MA��Ԥ�������Ȩƽ����MA��ռ�ı���
paraM.xMA = 12; % MA����
paraM.interval =  60;
%%%%%%%%%%%%%%%%3���ؼ����� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lossRatio = 0.5; % ֹ������
% alpha = 0.35; % �ع�ϵ������������ 1 - ��

nLag= 10; % nLagȡ10���ϵĻ��ᵼ��realY������ǰ��Spread��9-10���Ҷ��߱Ƚ�ͬ��


%% ȡ�ز���ȫ��������

load Z:\baseData\Tdays\future\Tdays_dly.mat
totalDate = Tdays(Tdays(:, 1) >= dateBegin & Tdays(:, 1) <= dateEnd, 1);

%% ģ��ֳ���������
% ע����Ϊ�ò����������ݲ���Ҫģ��ֳ��������ݣ�����ģ�����ܲ����������ֱ���õ������ľͲ���Ҫģ���ˣ�10.31��

% ��̿�ֻ��۸񣺳����
w = windmatlab;
% �ݶ�ѡ��ɽ�����أ��ٷڡ����С�̫ԭ������ͷҪ����һ��Wind�ṩ���ݵ����е���ƽ��
% @2018.11.2֮ǰ�õ���һ��ұ�𽹣�Ӧ����׼һ�������������׼��ӽ���������
% ��̿�ֻ��۸���ʱ����
% Wind������������EDB��2016��ſ�ʼ��Ҫ�ô�����Ʒ���ݿ�����ݣ���2011�꿪ʼ����
%%%%%%%%%%%%%%%%%%%%%%ע�⣡��Wind������ʱ����������dateEnd�Ժ�����ݣ���֡�������%%%%%%%%%%%%%%%%%%%%%%%%%
[w_edb_data,~,~,w_edb_times,w_edb_errorid,~] = ...
    w.edb('S5120126,S5120127,S5120128','2011-01-01',dateEnd,'Fill=Previous');
w_edb_times = rowfun(@(x, f) datestr(x, 'yyyymmdd'), table(w_edb_times));
w_edb_times = table2array(rowfun(@str2double, w_edb_times));
ifErrorStop() % ifErrorStop����Ҫ�޸ģ�û��stop�����������
priceJ = mean(w_edb_data, 2); % ��̿�ֻ��۸�ȡɽ�����س����ƽ�� @2018.11.2û��Ҫ����ƽ�������ؼ�����ȫһ��
priceJ = table(w_edb_times, priceJ);
priceJ.Properties.VariableNames = {'Date', 'PriceJ'};
priceJ = priceJ(priceJ.Date >= dateBegin & priceJ.Date <= dateEnd, :);

% ��ú�ֻ��۸񣺳����
% 0.35 * ����ú + 0.25 * 1/3��ú + 0.12 * ��ú + 0.18 * ��ú + 0.1 * ��ú �ϳ��ֻ���ú�۸�
% ��ȡWindú�ֻ��۸� ע��S513��ͷ�Ķ���2016��1�²ſ�ʼ�����ݵģ���Ҫȡ��Щ
% ����ú���ӱ������������ɡ�ɽ���ĵ�ƽ��  ɽ����S5120097�г��۴��泵��� @2018.11.2���ɼ۸����������ز���ϴ󡣡�
% 1/3��ú��ɽ��S5120114���ӱ�S5120115������S5120123����ƽ�� @2018.11.2��������һ�£�ϸ�ڲ���ϴ����ɲ�����
% ��ú��������˳S5101924��ɽ������ƽ��S5101946���ܶȣ��ն�����ֻ��S513��֮�����ݣ���ʼ̫������û�б�Ҫ����Ϊ�仯��Ƶ�������ܶ�û�
% ��ú��ɽ���Ž�S5120108��ɽ������S5120109���ӱ�����S5120110���ӱ���ɽS5120111�ĵ�ƽ��
% ��ú��ɽ��̫ԭS0146209  �ܶ�����

[w_edb_data, ~, ~, w_edb_times, w_edb_errorid, ~] = ...
    w.edb('S5120098,S5120102,S5120106,S5120097,S5120114,S5120115,S5120123,S5101924,S5101946,S5120108,S5120109,S5120110,S5120111,S0146209','2011-01-01',dateEnd,'Fill=Previous');
w_edb_times = rowfun(@(x, f) datestr(x, 'yyyymmdd'), table(w_edb_times));
w_edb_times = table2array(rowfun(@str2double, w_edb_times));
ifErrorStop()
priceZhuJM = mean(w_edb_data(:, 4), 2); % ����ú�ֻ��۸�ȡ�ĵ�ƽ�� % �ų����� % �ų��ӱ��ͽ�������ۣ�ֻ��ɽ���г��ۣ���������
priceOneThird = mean(w_edb_data(:, 5 : 7), 2); % 1/3��ú�ֻ��۸�ȡ����ƽ�� % ֻȡɽ�����úܲΪʲô�أ�
priceQi = mean(w_edb_data(:, 8), 2); % ��ú�ֻ��۸�ȡ����ƽ�� ���ش�����һ����ϸ�ڲ���ͦ�� ֻ�õ�8��������˳
priceFei =mean(w_edb_data(:, [10, 12 : 13]), 2); % ��ú�ֻ��۸� @11.2�޳�ɽ�������Ǹ������̫��
priceShou = w_edb_data(:, 14); % ��ú�ֻ��۸�

priceJM = table(w_edb_times, priceZhuJM, priceOneThird, priceQi, priceFei, priceShou);
priceJM.Properties.VariableNames = {'Date', 'PriceZhuJM', 'PriceOneThird', 'PriceQi', 'PriceFei', 'PriceShou'};

% priceJM.PriceJM = priceJM.PriceZhuJM .* JMRatio.Zhu + priceJM.PriceOneThird .* JMRatio.OneThird + ...
%     priceJM.PriceQi .* JMRatio.Qi + priceJM.PriceFei .* JMRatio.Fei + priceJM.PriceShou .* JMRatio.Shou;
priceJM.PriceJM = priceJM.PriceZhuJM;
priceJM = priceJM(priceJM.Date >= dateBegin & priceJM.Date <= dateEnd, :);

[w_edb_data,~,~,w_edb_times,w_edb_errorid,~] = ...
    w.edb('S5470379','2011-01-01',dateEnd,'Fill=Previous');
w_edb_times = rowfun(@(x, f) datestr(x, 'yyyymmdd'), table(w_edb_times));
w_edb_times = table2array(rowfun(@str2double, w_edb_times));
ifErrorStop()
priceJY = table(w_edb_times, w_edb_data); % ú�����ֻ��۸�
priceJY.Properties.VariableNames = {'Date', 'PriceJY'};
priceJY = priceJY(priceJY.Date >= dateBegin & priceJY.Date <= dateEnd, :);

% merge data and get simulation profit as Y
price = outerjoin(priceJ, priceJM, 'type', 'left', 'MergeKeys', true);
price = outerjoin(price, priceJY, 'type', 'left', 'MergeKeys', true);
% ��price��ÿһ������fillmissing���ϲ���
price(:, 2:end) = varfun(@(x, y) fillmissing(x, 'previous'), price(:, 2:end));

% construct Y
% price.Profit = price.PriceJ - price.PriceJM ./ paraM.rate - paraM.fixedExpense + price.PriceJY .* paraM.jiaoyouRatio;
price.Profit = price.PriceJ - price.PriceJM ./ paraM.rate - paraM.fixedExpense; % ���� = �ֻ��۲�
% paraM.jyPrice ���ڹ���Spread
paraM.jyPrice = table(price.Date, price.PriceJY, 'VariableNames', {'Date', 'PriceJY'});


%% ��ȡ��ú��̿�������� �����������Լ�����ɡ���
xianhuo = table(price.Date, price.PriceJ, price.PriceJM, 'VariableNames', {'Date', 'PriceJ', 'PriceJM'});
xianhuo = xianhuo(all(~isnan(table2array(xianhuo)),2), :); % ȥ���Ժ���NaN����% ȥ��NaN
xianhuo = xianhuo(xianhuo.Date >= dateBegin, :);
% �����ڻ�������Լ�۸��Լ��������
load \\Cj-lmxue-dt\�ڻ�����2.0\dlyData\������Լ\J.mat
zhuliJ = table(futureData.Date, futureData.Close, 'VariableNames', {'Date', 'FutPriceJ'});
zhuliJ = zhuliJ(zhuliJ.Date >= dateBegin, :);
load \\Cj-lmxue-dt\�ڻ�����2.0\dlyData\������Լ\JM.mat
zhuliJM = table(futureData.Date, futureData.Close, 'VariableNames', {'Date', 'FutPriceJM'});
zhuliJM = zhuliJM(zhuliJM.Date >= dateBegin, :);
clear futureData

jicha = outerjoin(zhuliJ, zhuliJM, 'type', 'left', 'MergeKeys', true);
jicha = outerjoin(jicha, xianhuo, 'type', 'left', 'MergeKeys', true);
jicha.JichaJ = jicha.PriceJ - jicha.FutPriceJ;
jicha.JichaJM = jicha.PriceJM - jicha.FutPriceJM;
% �����������Wind��һ����Wind ��̿�ֻ�ȡ������ɽ����ұ�𽹣���ú�ֻ�ȡ����ɽ����������ú
jicha.JichaJ = fillmissing(jicha.JichaJ, 'previous');
jicha.JichaJM = fillmissing(jicha.JichaJM, 'previous');


%% �ֳ�������Ӱ�����ػع飬����Ԥ���ϵʽ
% ��ȡ�Ա������ݣ� @2018.10.25 ����ǰ��������
% ��� ������Դ��Wind
% ȫ����������������������  ������Դ���������ݿ�
% ���θֳ��ĸ�¯����������  ������Դ���������ݿ�  Wind������������
% ���θֳ�����ӯ���ʣ�
% �Ա�����Ҫ����׼�������޳����ع���������
% ��̿��桢�������������������ʡ����θֳ����������Ա�����Ч����̫�ã��ֳ���¯���������ʹ�����ǿ���޳���
% @2018.10.31�����Լ��뽹ú���

% 1.���
% ����ʹ�÷�ʽ���ۿڿ�桢������桢�ֳ���������ֿ������������Ϊһ���Ա�����������
% �ۿڿ��
[w_edb_data, ~, ~, w_edb_times, w_edb_errorid, ~] = w.edb('S5120058,S5116629,S5116630,S5136709','2011-01-01',dateEnd,'Fill=Previous');
ifErrorStop()
% �ൺ�۴�2014��ſ�ʼ�����ݣ��ݶ�����������Ƹۡ��������غϼƣ����Ʋ���û�м����ൺ��ô�󣬵�������ȫ��
w_edb_times = rowfun(@(x, f) datestr(x, 'yyyymmdd'), table(w_edb_times));
w_edb_times = table2array(rowfun(@str2double, w_edb_times));
storeHarbor = sum(w_edb_data(:, 1 : 3), 2);
storeHarbor = table(w_edb_times, storeHarbor);
storeHarbor.Properties.VariableNames = {'Date', 'StoreHarbor'};
storeHarbor = storeHarbor(storeHarbor.Date >= dateBegin & storeHarbor.Date <= dateEnd, :);

% �������͸ֳ���� ������Դ����������
% S5133852 �ֳ���̿��� S5133860 ���ڸֳ���110�ң���̿ƽ������������������Ӧ������Ժܸߣ���
% S5118225 �����͸ֳ���̿ƽ������������S513��ͷ�Ķ���2017��������ݣ��������á���
% �������͸ֳ����Windֻ��2017��4���Ժ���������������Ǵ�2011�꿪ʼ�ģ�2017��1��13֮ǰ����50���������ݻ���ģ�
% ע�⣺�ֳ�������ݴ�2017��1�¿�ʼ�������µģ�֮ǰ������2017��6�·�һ��������ϵ�
storeJCGC = readtable('C:\Users\fengruiling\Desktop\storeData.csv');

% �������ݸ�ʽ
storeJC = formatAdj(storeJCGC(:, 2:3));
storeJC.Properties.VariableNames = {'Date', 'StoreJC'};
storeJC = storeJC(storeJC.Date >= dateBegin & storeJC.Date <= dateEnd, :);
storeGC = formatAdj(storeJCGC(:, [2 5]));
storeGC.Properties.VariableNames = {'Date', 'StoreGC'};
storeGC = storeGC(storeGC.Date >= dateBegin & storeGC.Date <= dateEnd, :);

% 2.��������������������
productionRatio = readtable('C:\Users\fengruiling\Desktop\productionRatio.csv');
% ���и����⣬��������������������������ݺܶ඼�Ǻ��ڲ��ϵģ���ʵ���õ�δ�����ݣ�����ò�����п�ԭ��
% �������ݸ�ʽ
productionRatio = formatAdj(productionRatio(:, 2:3));
productionRatio.Properties.VariableNames = {'Date', 'ProductionRatio'};
productionRatio = productionRatio(productionRatio.Date >= dateBegin & productionRatio.Date <= dateEnd, :);

% 3.���θֳ���¯����������

gaoluRatio = readtable('C:\Users\fengruiling\Desktop\gaoluRatio.csv');
gaoluRatio = formatAdj(gaoluRatio(:, 2:3));
gaoluRatio.Properties.VariableNames = {'Date', 'GaoluRatio'};
gaoluRatio = gaoluRatio(gaoluRatio.Date >= dateBegin & gaoluRatio.Date <= dateEnd, :);

% 4.���θֳ�����ӯ���ʣ� �����Wind���ݣ������Ĵ�2018��3�²ſ�ʼ����
[w_edb_data, ~, ~, w_edb_times, w_edb_errorid, ~] = w.edb('S5708339','20130302',dateEnd,'Fill=Previous');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%dateBegin��ô���С���������������������%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ifErrorStop()
% �ൺ�۴�2014��ſ�ʼ�����ݣ��ݶ�����������Ƹۡ��������غϼƣ����Ʋ���û�м����ൺ��ô�󣬵�������ȫ��
w_edb_times = rowfun(@(x, f) datestr(x, 'yyyymmdd'), table(w_edb_times));
w_edb_times = table2array(rowfun(@str2double, w_edb_times));
gcProfitRatio = table(w_edb_times, w_edb_data);
gcProfitRatio.Properties.VariableNames = {'Date', 'GCProfitRatio'};
gcProfitRatio = gcProfitRatio(gcProfitRatio.Date >= dateBegin & gcProfitRatio.Date <= dateEnd, :);

% 5.��̿ƽ�����������������ڴ����͸ֳ���������ԴWind2011.8.13��ʼ �ܶ�����
[w_edb_data, ~, ~, w_edb_times, w_edb_errorid, ~] = w.edb('S5118225','20130302',dateEnd,'Fill=Previous');
ifErrorStop()
w_edb_times = rowfun(@(x, f) datestr(x, 'yyyymmdd'), table(w_edb_times));
w_edb_times = table2array(rowfun(@str2double, w_edb_times));
availableDayJ = table(w_edb_times, w_edb_data);
availableDayJ.Properties.VariableNames = {'Date', 'AvailableDayJ'};
availableDayJ = availableDayJ(availableDayJ.Date >= dateBegin & availableDayJ.Date <= dateEnd, :);

% 6. ����úƽ�������������� ���ڴ����͸ֳ���������ԴWind 2011.8.13��ʼ �ܶ����ݣ����ǽ�ú��濴�ֳ�������
[w_edb_data, ~, ~, w_edb_times, w_edb_errorid, ~] = w.edb('S5118223','20130302',dateEnd,'Fill=Previous');
ifErrorStop()
w_edb_times = rowfun(@(x, f) datestr(x, 'yyyymmdd'), table(w_edb_times));
w_edb_times = table2array(rowfun(@str2double, w_edb_times));
availableDayJM = table(w_edb_times, w_edb_data);
availableDayJM.Properties.VariableNames = {'Date', 'AvailableDayJM'};
availableDayJM = availableDayJM(availableDayJM.Date >= dateBegin & availableDayJM.Date <= dateEnd, :);


% 7. �Ա������Ͻ�̿�ֻ��۸����� priceJ
% ��ú�ͽ�̿���ֻ��۸�Spearman correlation 0.95�� ������̫ǿ��ֻ�ܼ�priceJ���Ա�������Ч��Ҳ���á���

% @2018.10.26
% ĿǰΪֹ7���Ա�������棨�ۿڡ��������ֳ����У����������������������ʡ��ֳ���¯�����ʡ��ֳ�ӯ���ʡ���̿��������������ú����������������̿�ֻ��۸�
regDate = table(totalDate, 'VariableNames', {'Date'});
regY = table(price.Date, price.Profit, 'VariableNames', {'Date', 'Profit'});
regData = outerjoin(regDate, regY, 'type', 'left', 'MergeKeys', true);
% attach X
regData = outerjoin(regData, storeHarbor, 'type', 'left', 'MergeKeys', true);
regData = outerjoin(regData, storeJC, 'type', 'left', 'MergeKeys', true);
regData = outerjoin(regData, storeGC, 'type', 'left', 'MergeKeys', true);
regData = outerjoin(regData, productionRatio, 'type', 'left', 'MergeKeys', true);
regData = outerjoin(regData, gaoluRatio, 'type', 'left', 'MergeKeys', true);
regData = outerjoin(regData, gcProfitRatio, 'type', 'left', 'Mergekeys', true);
regData = outerjoin(regData, availableDayJ, 'type', 'left', 'Mergekeys', true);
regData = outerjoin(regData, availableDayJM, 'type', 'left', 'Mergekeys', true);
% regData = outerjoin(regData, priceJ, 'type', 'left', 'MergeKeys', true);

regData.StoreJ = regData.StoreHarbor + regData.StoreJC + regData.StoreGC; % �ۿ�+ ����+ �ֳ����ϵ�һ��
regData(:, 3:5) = [];


% regData�Ա����岹NaN
regData(:, 2:end) = varfun(@(x, y) fillmissing(x, 'previous'), regData(:, 2 : end));
regData = regData(all(~isnan(table2array(regData)),2), :); % ȥ���Ժ���NaN����


% regData�����������ĿǰΪֹ�����Ա�����
% ����׼�������������Դ���


% corr(regData.ProductionRatio(5:end), regData.GaoluRatio(5:end))
[sValue,condIdx,VarDecomp] = collintest(regData(:, [3, 5:8]));
% @10.30 GaoluRatio����������ǿ�����޳�
% @10.31 ����ֳ������������Ժ�productionRatio �� gaoluRatio����ù����Ժܸߣ������޳�
% productionRatio, gaoluRatio, availableDayJ����֮������Զ���0.4���ϣ�
% ����productionRatio��profit���������ߣ��������������ߡ����о�����ֻ��productionRatio��һ�������Ϳ���
% �޳�gaoluRatio�Ժ��û�й�������
regData.GaoluRatio = [];


% �Ա�����׼�� ����ֵ���Ա�׼��
% regData(:, 3:end) = varfun(@(x) zStandard(x), regData(:, 3:end)); % ��������׼���ع��stats������û���
% �Ȳ�����׼������Ϊ������ûɶ���𣬷���Ӱ������������������X�����и����綼Ϊ����Ū��



%% Ԥ���ڻ��۸��������
% Y �� X��һ���ͺ����䣨�������ڣ�
% �ȼ���14����һ��
% ��yֵ���´�14�죬ͬһ�������ǵ����x��14��������y
% ����ط��е��Ѹ㡣����Ҫȷ�е�ʱ�����𣿻��ǲ�һ��Ҳ�У�

% nLagȡ10���ϵĻ��ᵼ��realY������ǰ��Spread��9-10���Ҷ��߱Ƚ�ͬ��
% ��N > 30 ��ʼ�ع飬ǰ30 + nLag�첻�����ź�


realSpread = nan(size(regData, 1), 4); % �ӵ� nLag + 30 �п�ʼ������ % ��2�м�¼YReal, ��3��YHAT
realSpread(:, 1) = table2array(regData(:, 1));
regressR2 = nan(size(regData, 1), 3);
projY = nan(size(regData, 1), 2);
for iDay = (30 + nLag) : size(regData, 1)
    
    regDataLagY = regData.Profit(nLag : iDay);
    regDataLagX = regData(1 : iDay - (nLag - 1), 3 : end);
    regDataLagX = [ones(size(regDataLagX, 1), 1) table2array(regDataLagX)];
    % ����ع�������1 : iDay - (nLag - 1)��X��nLag : iDay��Y�ع�õ��ķ��̣�
    % ��������̽��������iDay���X ���õ�iDay + nLag���Ԥ��Y����ΪiDay������ۼ۲�ֵ���м�iDay - nLag + 2:iDay - 1��ЩX����һ�����ȥ��û���ã�
    
    % �������������������������̫�����ᵼ����ϵ�Y̫ƽ��Ҳ����������������û��������������ʱ�����û�п̻��������ȼ�С����������
    % ���ǰ�˵��Ӧ�ã����ģ���㹻�õĻ�����Ӧ��������Խ��Ч�����������ˣ�˵����������仯�ˣ�������û���ǵ�
%         if size(regDataLagY, 1) > 300
%             regDataLagY = regDataLagY(size(regDataLagY, 1) - 300 + 1 : end, :);
%             regDataLagX = regDataLagX(size(regDataLagX, 1) - 300 + 1 : end, :);
%         end
    
    [b, ~, r, ~, stats] = regress(regDataLagY, regDataLagX);
    % ����R��
    adjR2 = 1 - (1 - stats(1)) * (size(regDataLagY, 1) - 1) / (size(regDataLagY, 1) - size(regDataLagX, 2) - 2);
    % �˴�R������������������󣬵�������ΪN�����Ӱ�죬adjustedR2Ҳ�ڱ��?
    % TSS ͳ����
    %     TSS = sum((regDataLagY - sum((b' .* regDataLagX), 2)) .^ 2); % ���˴��ˣ����ǲв�ƽ����
%     residual = regDataLagY - sum((b' .* regDataLagX), 2);
    SSE = sum(r .^ 2);
    SST = SSE / (1 - stats(1));
    % PRESSͳ����
    %     pr = nan(size(regDataLagY, 1), 1);
    %     for i = 1 : size(regDataLagY, 1)
    %         xi = regDataLagX([1 : (i - 1), (i + 1) : end], :);
    %         yi = regDataLagY([1 : (i - 1), (i + 1) : end], :);
    %         [bi, ~, ~, ~, ~] = regress(yi, xi);
    %         yiHat =  sum(bi .* regDataLagX(i, :)');
    %         pr(i) = (yiHat - regDataLagY(i)) ^ 2;
    %     end
    %     PRESS = sum(pr);
    hatMatrix = regDataLagX * inv(regDataLagX' * regDataLagX) * regDataLagX';
    hat = diag(hatMatrix);
    pr = r ./ ( 1 - hat);
    PRESS = sum(pr .^ 2);
    preR2 = 1 - PRESS / SST;
    regressR2(iDay, 1) = stats(1);
    regressR2(iDay, 2) = adjR2; % ��¼ÿ���ع鷽�̵�����Ŷ�
    regressR2(iDay, 3) = preR2;
    
%     yHatDown = bint(1, 1) + sum(bint(2:end, 1) .* table2array(regData(iDay, 3:end))'); % iDay���Ա�����Ԥ�����iDay + nLag�����������Ӧ����iDay��Spread
%     yHatUp = bint(1, 2) + sum(bint(2:end, 2) .* table2array(regData(iDay, 3:end))');
    yHat = b(1) + sum(b(2:end) .* table2array(regData(iDay, 3:end))');
    
    if iDay + nLag <= size(regData, 1)
%     yHat = regData.Profit(iDay + nLag - 1);
    realSpread(iDay, 2) = regData.Profit(iDay); % YReal ֻ��size(regData) - nLag��realY,�����µľͲ�֪��realY��
%     realSpread(iDay, 2) = regData.Profit(iDay + nLag - 1); % YReal ֻ��size(regData) - nLag��realY,�����µľͲ�֪��realY��
% ע�� realY���������iDay��ʱ�򲢲�֪����д������ֻ��Ϊ�˻�ͼ��   
% 11.9 ��һ����
    realSpread(iDay, 4) = regData.Profit(iDay + nLag - 1); % nLag������ʵ����
   
    end
    realSpread(iDay, 3) = yHat; % ��ô������ÿ�λع�õ�һ����ǰֵ����Ϊ�˲���δ����Ϣ
%     realSpread(iDay, 4) = yHat - interval;
%     realSpread(iDay, 5) = yHat + interval;


    % ��iDay = 45����Ϊ����X��������֪��45��Ȼ����1��36��X ��10��45��Y����һ���ع鷽�̣���������̴���45�յ�X
    % ȥԤ��45 + nLag - 1�յ�Y����Ϊ45�յ���ʵ����spread����������37-44��X���ܿգ���û���õ�δ������
    
    % yHatԤ�����뽹��ʵ�����󣨸������ݣ��ԱȽ��
    % �������ݣ��ֽ�ӯ���������2017��6�¿�ʼ��������������Ͳ��Ƚ��ˣ���yHat�����Excel����Ƚϰ�
    if iDay + nLag - 1 <= size(regData, 1)
        projY(iDay + nLag - 1, 1) = regData.Date(iDay + nLag - 1);
        projY(iDay + nLag - 1, 2) = yHat;
        % projY�����ڣ���Ԥ��Ķֽ�����һһ��Ӧ
    end
    
    
    %%%%%%%%%%%%%%%% �в�r������Ϣû�ó�������Ҫ���Ż��ع鷽��%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %     yHat = b(1) + b(2) * regDataLagX(:, 2) + b(3) * regDataLagX(:, 3)  + b(4) * regDataLagX(:, 4);
    % ����yHat�����ͺ�nLag����ʵ�۸����ߣ��ǰ�yHat��ǰŲnLag����ǵ�ǰ����ʵ�۸�
    %     yHatDown = bint(1, 1) + bint(2, 1) * regDataLagX(:, 2) + bint(3, 1) * regDataLagX(:, 3) + bint(4, 1) * regDataLagX(:, 4);
    %     yHatUp = bint(1, 2) + bint(2, 2) * regDataLagX(:, 2) + bint(3, 2) * regDataLagX(:, 3) + bint(4, 2) * regDataLagX(:, 4);
    
    %     plot(regDataLagY)
    %     hold on
    %     plot(yHat)
    %     plot(yHatDown)
    %     plot(yHatUp)
    
end

realSpread = array2table(realSpread);
% realSpread.Properties.VariableNames = {'Date', 'YReal', 'YHat', 'SpreadDown', 'SpreadUp', 'YRealNLag'};
realSpread.Properties.VariableNames = {'Date', 'YReal', 'YHat', 'YRealNLag'};

% ��2��YReal�ǵ���ʵ�ʵ��ֻ����󣻵�3��YHat��Ԥ��NLag����ʵ�����󣻵�6(4)��YReal��nLag����ʵ�����󣬵�3�����6��Խ����ع�Ԥ��Խ��

% @11.7 ��ĿǰΪֹ��realSpread����Spread�������󣬽������û���͸���Ʒ�ֻ��۸����Ϊ��Spread

% jicha.JichaJMA10 = ((movmax(jicha.JichaJ, [10, 0]) * 11) - jicha.JichaJ) / 10; % ��ôд���У���Ϊ��ǰ�治��10����Щ����ֱ�ӳ���11
% jicha.JichaJMA10 = MAx(jicha.JichaJ, 10); % ���MA�ǰ����Լ����ڵ�10��
% jicha.JichaJMMA10 = MAx(jicha.JichaJM, 10);
% realSpread = outerjoin(realSpread, paraM.jyPrice, 'type', 'left', 'MergeKeys', true);
% realSpread = outerjoin(realSpread, xianhuo, 'type', 'left', 'MergeKeys', true);

% adjValue = - realSpread.JichaJMA10 + 1 / paraM.rate * realSpread.JichaJMMA10;
% adjValue = paraM.fixedExpense - paraM.jiaoyouRatio * realSpread.PriceJY - realSpread.JichaJMA10 + 1 / paraM.rate * realSpread.JichaJMMA10;
% ���ۻ����MA10���ù̶�ֵ����
% adjValue = 0;
% realSpread(:, 2:5) = array2table(table2array(realSpread(:, 2:5)) + adjValue);
% realSpread = realSpread(:, 1:6);
% clear adjValue

%% �������̼��뵱����ʵ�۸�Ƚ�

% ��ȡ�ڻ��۸�����
% Ʒ��
fut_variety = {'J','JM'};
% �ź����
signalName = 'CTA1';
signalID = 101;

% paraM.jy
Cost.fix = 0; %�̶��ɱ�
Cost.float = 2; %����
tradeP = 'open'; %���׼۸�
oriAsset = 10000000; %��ʼ���


% �������
stDate = 0;
edDate = dateEnd; % �����ǽ�����
load Z:\baseData\Tdays\future\Tdays_dly.mat
totaldate = Tdays(Tdays(:,1)>=stDate & Tdays(:,1)<=edDate,1);
sigDPath = '\\Cj-lmxue-dt\�ڻ�����2.0\pairData';
% ���·��
addpath(['gen_function\',signalName]);
% ��������
load \\Cj-lmxue-dt\�ڻ�����2.0\usualData\minTickInfo.mat %Ʒ����С�䶯��λ
trade_unit = minTickInfo;
load(['\\Cj-lmxue-dt\�ڻ�����2.0\usualData\PunitInfo\',num2str(totaldate(end)),'.mat']) %��Լ����
cont_multi = infoData;

proAsset = oriAsset;


for i_pair = 1:size(fut_variety,1)
    pFut1 = fut_variety{i_pair,1};
    pFut2 = fut_variety{i_pair,2};
    dataPath = [sigDPath,'\',pFut1,'_',pFut2];
    % ��Լ����
    contM1 = cont_multi{ismember(cont_multi(:,1),pFut1),2};
    contM2 = cont_multi{ismember(cont_multi(:,1),pFut2),2};
    % ����
    %     pName = fieldnames(paraM);
    %     for p = 1:length(pName)
    %         str = ['para.',pName{p},'=paraM.',pName{p},'(i_pair);'];
    %         eval(str)
    %     end
    
    % ���뻻��������
    load(['\\Cj-lmxue-dt\�ڻ�����2.0\code2.0\data20_pair_data\chgInfo\',pFut1,'_',pFut2,'.mat'])
    chgInfo = chgInfo(chgInfo.date>stDate & chgInfo.date<=edDate,:);
    
    % �����ź�-����Լѭ��
    res = totaldate(totaldate >= chgInfo.date(1));
    res = res(1 : (end - 1)); %��Ȼ���һ���ǿ�ֵ
    res = array2table([res, NaN(size(res, 1), 5)], 'VariableNames', {'Date', 'PosLabel', 'Hands1', 'Hands2', 'Cont1', 'Cont2'});
    res.Cont1 = num2cell(res.Cont1);
    res.Cont2 = num2cell(res.Cont2);
    tstData = table();
    
    for c = 1:height(chgInfo)
        c_stD = chgInfo.date(c); %�ú�Լ��ʼ��Ϊ����������
        if c~=height(chgInfo)
            c_edD = totaldate(find(totaldate==chgInfo.date(c+1),1)-1); %�ú�Լ��Ϊ�����Ľ�������
        else %���һ��
            c_edD = totaldate(find(totaldate==edDate)-1);
        end
        cont1 = regexp(chgInfo{c,2}{1},'\w*(?=\.)','match');
        cont2 = regexp(chgInfo{c,3}{1},'\w*(?=\.)','match');
        % ��������
        data1 = getData([dataPath,'\',pFut1,'\',cont1{1},'.mat'],edDate);
        data2 = getData([dataPath,'\',pFut2,'\',cont2{1},'.mat'],edDate);
        [sigOpen, sigClose, resSignal] = getSignal(data1, data2, realSpread, paraM);
        sig = [sigOpen,sigClose];
        tstData = vertcat(tstData, resSignal(resSignal.Date >= c_stD & resSignal.Date <= c_edD, :));
        
        subplot(5, 4, c)
        plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.Spread) % ʵ���ڻ��۲�:����       
        hold on
%         %         plot(lines.trend)
% 
        plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.SpreadUp)
        plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.SpreadDown)
%         plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.YHat) % ���Y
        plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.YReal) % ��ʵY�������ֻ�-�ֻ��� ����
%        
% %         plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.YReal + interval)
% %         plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.YReal - interval)
% %         plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.JichaDiff) % ����
% %          plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.SpreadTheory) % nLag������ʵ���� + ����Ĳ�����е�����:���ߣ�
        datetick('x', 'yyyymmdd', 'keepticks', 'keeplimits')
        
        
        % ����Ϊֹ�𲿷�
        % �������Ϊ��pureSig��һ����������Ҫֹ��Ĳ��־�ֱ�Ӱѳֲ��źź�������Ϊ0�����ѳ������첻���ֶ���Ϊ0���ɣ���û����
        if strcmpi(tradeP,'open')
            tddata = [data1.open,data2.open];
        end
        tddata = [tddata,data1.close,data2.close];
        Cost.unit1 = trade_unit{ismember(trade_unit(:,1),pFut1),2};
        Cost.unit2 = trade_unit{ismember(trade_unit(:,1),pFut2),2};
        Cost.contM1 = contM1;
        Cost.contM2 = contM2;
        % pure_signal��Ϊ3���׶Σ��ڶ��׶�Ϊֹ���޸�ƽ���źţ���������pureSig�Ѿ���ֹ�����ź�
        pureSig = pure_signal(sig, data1.date, tddata, c_stD, c_edD, oriAsset, data1, data2, paraM.rate*ones(size(sig,1),1), contM1, contM2, lossRatio, Cost);
        
        resI = array2table(pureSig, 'VariableNames', {'Date', 'PosLabel', 'Hands1', 'Hands2'});
        resI.Cont1 = repmat(cont1, size(pureSig, 1), 1);
        resI.Cont2 = repmat(cont2, size(pureSig, 1), 1);
        fromIdx = find(res.Date == c_stD);
        endIdx = find(res.Date == c_edD);
        res((fromIdx : endIdx), :) = resI(resI.Date >= c_stD & resI.Date <= c_edD, :);
    end
    
end


targetPortfolio = num2cell(NaN(size(res, 1), 2));   %�����ڴ�
for iDate = 1:size(res, 1)
    hands = {char(res(iDate, :).Cont1), res(iDate, :).Hands1;...
        char(res(iDate, :).Cont2), res(iDate, :).Hands2};
    targetPortfolio{iDate, 1} = hands;
    targetPortfolio{iDate, 2} = res.Date(iDate);
end

% getholdinghands���ֲ��漰�����գ���Ϊ��ÿ��ѭ���ģ���������û�к�Լ����
% ���Ǻ�Լ������Ҫ��������ز�ƽ̨���ݲ���adjFactor



% TradePara��������ز�ƽ̨
TradePara.futDataPath = '\\Cj-lmxue-dt\�ڻ�����2.0\dlyData\������Լ'; %�ڻ�������Լ����·��
TradePara.futUnitPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\minTickInfo.mat'; %�ڻ���С�䶯��λ
TradePara.futMultiPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\PunitInfo'; %�ڻ���Լ����
TradePara.futLiquidPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\liquidityInfo'; %�ڻ�Ʒ�����������ݣ�����ɸѡ����ԾƷ�֣��޳�����ԾƷ��
TradePara.futSectorPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\SectorInfo.mat'; %�ڻ����������ݣ�����ȷ����������Ӧ��Ʒ��
TradePara.futMainContPath = '\\Cj-lmxue-dt\�ڻ�����2.0\��Ʒ�ڻ�������Լ����'; %������Լ����
% TradePara.usualPath = '..\data\usualData';%����ͨ������ �����ַ�����
TradePara.usualPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData';
TradePara.fixC = 0.0000; %�̶��ɱ�
TradePara.slip = 2; %����
TradePara.PType = 'open'; %���׼۸�һ����open�����̼ۣ�����avg(�վ��ۣ�


[BacktestResult,err] = CTABacktest_GeneralPlatform_3(targetPortfolio,TradePara);

figure
% ��ֵ����
dn = datenum(num2str(BacktestResult.nv(:, 1)), 'yyyymmdd');
plot(dn, (oriAsset + BacktestResult.nv(:, 2)) ./ oriAsset)
datetick('x', 'yyyymmdd', 'keeplimits')

BacktestAnalysis = CTAAnalysis_GeneralPlatform_2(BacktestResult);
testRes(:, iTest) = cellfun(@(x) double(x), BacktestAnalysis(:, 2));
testRegressR2(:, iTest) = mean(regressR2, 'omitnan')';
end
% plot(datenum(num2str(tstData.Date), 'yyyymmdd'), tstData.Spread - 150) % ��ʵY�������ֻ�-�ֻ��� ����
% hold on
% plot(datenum(num2str(tstData.Date), 'yyyymmdd'), tstData.YReal) % ��ʵY�������ֻ�-�ֻ��� ����
% datetick('x', 'yyyymmdd', 'keepticks', 'keeplimits')
