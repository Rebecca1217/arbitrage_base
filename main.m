cd E:\Repository\arbitrage_base
addpath public newSystem3.0\gen_for_BT2 newSystem3.0 usual_function

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%2018.11.15
%%%%%%%%%%%regData.ProductionRatio和regData.GCProfitRatio这两个数据与regData.Profit的相关系数很低，可能是数据质量的问题
% 周度看，和扩展成日度都很低，ProductionRatio才0.16, GCProfitRatio 0. 29
% productionRatio和焦炭现货价格相关性0.37，按说productionRatio越高，供给越多，应该负相关？



dateBegin = 20130302; % 训练
dateEnd = 20170929; % 训练 % c_edD必须是交易日，不然totaldate里面定位不到
% dateBegin = 20170701; % 验证
% dateEnd = 20180330; % 验证
% dateBegin = 20180101; % 测试
% dateEnd = 20181029; % 测试


% 交易参数
paraM.rate = 1 / 1.35; %%这个rate一定要注意。。不要随便改成1.35！改的话calOpenHands一定要跟着改！！每次结果要检查一下手数比对不对！！
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
% paraM.jiaoyouRatio = 0.05; % 产出一吨焦炭可同时产出0.05吨煤焦油副产品
% 煤焦油价格2900 - 4000 波动，产生的影响在145~200之间，假设150吧，和固定成本合到一起，
%%%%%%%%%%%%%%%%3个关键参数：%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
paraM.proportion = 0.98; % MA与预测利润加权平均，MA所占的比例
paraM.xMA = 12; % MA天数
paraM.interval =  60;
%%%%%%%%%%%%%%%%3个关键参数 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lossRatio = 0.5; % 止损上限
% alpha = 0.35; % 回归系数的置信区间 1 - α

nLag= 10; % nLag取10以上的话会导致realY明显提前于Spread，9-10左右二者比较同步


%% 取回测期全部交易日

load Z:\baseData\Tdays\future\Tdays_dly.mat
totalDate = Tdays(Tdays(:, 1) >= dateBegin & Tdays(:, 1) <= dateEnd, 1);

%% 模拟钢厂利润数据
% 注：因为拿不到钢联数据才需要模拟钢厂利润数据，好在模拟结果很不错；但如果能直接拿到钢联的就不需要模拟了（10.31）

% 焦炭现货价格：车板价
w = windmatlab;
% 暂定选了山西三地（临汾、晋中、太原），回头要尝试一下Wind提供数据的所有地区平均
% @2018.11.2之前用的是一级冶金焦，应该用准一级焦（跟交割标准最接近）？？？
% 焦炭现货价格暂时不变
% Wind这三个数据在EDB是2016年才开始，要用大宗商品数据库的数据，从2011年开始。。
%%%%%%%%%%%%%%%%%%%%%%注意！！Wind读数的时候会读出几个dateEnd以后的数据，奇怪。。。。%%%%%%%%%%%%%%%%%%%%%%%%%
[w_edb_data,~,~,w_edb_times,w_edb_errorid,~] = ...
    w.edb('S5120126,S5120127,S5120128','2011-01-01',dateEnd,'Fill=Previous');
w_edb_times = rowfun(@(x, f) datestr(x, 'yyyymmdd'), table(w_edb_times));
w_edb_times = table2array(rowfun(@str2double, w_edb_times));
ifErrorStop() % ifErrorStop函数要修改，没有stop这个函数。。
priceJ = mean(w_edb_data, 2); % 焦炭现货价格取山西三地车板价平均 @2018.11.2没必要三地平均，三地几乎完全一样
priceJ = table(w_edb_times, priceJ);
priceJ.Properties.VariableNames = {'Date', 'PriceJ'};
priceJ = priceJ(priceJ.Date >= dateBegin & priceJ.Date <= dateEnd, :);

% 焦煤现货价格：车板价
% 0.35 * 主焦煤 + 0.25 * 1/3焦煤 + 0.12 * 气煤 + 0.18 * 肥煤 + 0.1 * 瘦煤 合成现货焦煤价格
% 读取Wind煤现货价格 注意S513打头的都是2016年1月才开始有数据的，不要取这些
% 主焦煤：河北、江西、内蒙、山西四地平均  山西是S5120097市场价代替车板价 @2018.11.2内蒙价格与其他三地差异较大。。
% 1/3焦煤：山西S5120114、河北S5120115、内蒙S5120123三地平均 @2018.11.2三地走势一致，细节差异较大，内蒙差的最大
% 气煤：辽宁抚顺S5101924、山东临沂平均S5101946（周度，日度数据只有S513钢之家数据，起始太晚，而且没有必要，因为变化不频繁，和周度没差）
% 肥煤：山西古交S5120108、山西霍州S5120109、河北邯郸S5120110、河北唐山S5120111四地平均
% 瘦煤：山西太原S0146209  周度数据

[w_edb_data, ~, ~, w_edb_times, w_edb_errorid, ~] = ...
    w.edb('S5120098,S5120102,S5120106,S5120097,S5120114,S5120115,S5120123,S5101924,S5101946,S5120108,S5120109,S5120110,S5120111,S0146209','2011-01-01',dateEnd,'Fill=Previous');
w_edb_times = rowfun(@(x, f) datestr(x, 'yyyymmdd'), table(w_edb_times));
w_edb_times = table2array(rowfun(@str2double, w_edb_times));
ifErrorStop()
priceZhuJM = mean(w_edb_data(:, 4), 2); % 主焦煤现货价格取四地平均 % 排除内蒙 % 排除河北和江西车板价，只用山西市场价，波动更大
priceOneThird = mean(w_edb_data(:, 5 : 7), 2); % 1/3焦煤现货价格取三地平均 % 只取山西会变得很差，为什么呢？
priceQi = mean(w_edb_data(:, 8), 2); % 气煤现货价格取两地平均 两地大走势一样，细节差异挺大， 只用第8列辽宁抚顺
priceFei =mean(w_edb_data(:, [10, 12 : 13]), 2); % 肥煤现货价格 @11.2剔除山西霍州那个，规格太低
priceShou = w_edb_data(:, 14); % 瘦煤现货价格

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
priceJY = table(w_edb_times, w_edb_data); % 煤焦油现货价格
priceJY.Properties.VariableNames = {'Date', 'PriceJY'};
priceJY = priceJY(priceJY.Date >= dateBegin & priceJY.Date <= dateEnd, :);

% merge data and get simulation profit as Y
price = outerjoin(priceJ, priceJM, 'type', 'left', 'MergeKeys', true);
price = outerjoin(price, priceJY, 'type', 'left', 'MergeKeys', true);
% 对price对每一列数，fillmissing向上补齐
price(:, 2:end) = varfun(@(x, y) fillmissing(x, 'previous'), price(:, 2:end));

% construct Y
% price.Profit = price.PriceJ - price.PriceJM ./ paraM.rate - paraM.fixedExpense + price.PriceJY .* paraM.jiaoyouRatio;
price.Profit = price.PriceJ - price.PriceJM ./ paraM.rate - paraM.fixedExpense; % 利润 = 现货价差
% paraM.jyPrice 用于构造Spread
paraM.jyPrice = table(price.Date, price.PriceJY, 'VariableNames', {'Date', 'PriceJY'});


%% 读取焦煤焦炭基差数据 读不出来，自己构造吧。。
xianhuo = table(price.Date, price.PriceJ, price.PriceJM, 'VariableNames', {'Date', 'PriceJ', 'PriceJM'});
xianhuo = xianhuo(all(~isnan(table2array(xianhuo)),2), :); % 去除仍含有NaN的行% 去掉NaN
xianhuo = xianhuo(xianhuo.Date >= dateBegin, :);
% 加入期货主力合约价格，自己计算基差
load \\Cj-lmxue-dt\期货数据2.0\dlyData\主力合约\J.mat
zhuliJ = table(futureData.Date, futureData.Close, 'VariableNames', {'Date', 'FutPriceJ'});
zhuliJ = zhuliJ(zhuliJ.Date >= dateBegin, :);
load \\Cj-lmxue-dt\期货数据2.0\dlyData\主力合约\JM.mat
zhuliJM = table(futureData.Date, futureData.Close, 'VariableNames', {'Date', 'FutPriceJM'});
zhuliJM = zhuliJM(zhuliJM.Date >= dateBegin, :);
clear futureData

jicha = outerjoin(zhuliJ, zhuliJM, 'type', 'left', 'MergeKeys', true);
jicha = outerjoin(jicha, xianhuo, 'type', 'left', 'MergeKeys', true);
jicha.JichaJ = jicha.PriceJ - jicha.FutPriceJ;
jicha.JichaJM = jicha.PriceJM - jicha.FutPriceJM;
% 这个基差结果与Wind不一样，Wind 焦炭现货取的是唐山二级冶金焦，焦煤现货取的是山西吕梁主焦煤
jicha.JichaJ = fillmissing(jicha.JichaJ, 'previous');
jicha.JichaJM = fillmissing(jicha.JichaJM, 'previous');


%% 钢厂利润与影响因素回归，构建预测关系式
% 获取自变量数据： @2018.10.25 先用前两个试试
% 库存 数据来源：Wind
% 全国独立焦化厂产能利用率  数据来源：钢联数据库
% 下游钢厂的高炉产能利用率  数据来源：钢联数据库  Wind数据质量不好
% 下游钢厂利润（盈利率）
% 自变量需要做标准化处理，剔除多重共线性问题
% 焦炭库存、独立焦化厂产能利用率、下游钢厂利润，三个自变量，效果不太好（钢厂高炉产能利用率共线性强已剔除）
% @2018.10.31，尝试加入焦煤库存

% 1.库存
% 两种使用方式：港口库存、焦厂库存、钢厂库存三个分开，或者相加作为一个自变量，都试试
% 港口库存
[w_edb_data, ~, ~, w_edb_times, w_edb_errorid, ~] = w.edb('S5120058,S5116629,S5116630,S5136709','2011-01-01',dateEnd,'Fill=Previous');
ifErrorStop()
% 青岛港从2014年才开始有数据，暂定先用天津、连云港、日照三地合计，趋势波动没有加上青岛那么大，但是日期全啊
w_edb_times = rowfun(@(x, f) datestr(x, 'yyyymmdd'), table(w_edb_times));
w_edb_times = table2array(rowfun(@str2double, w_edb_times));
storeHarbor = sum(w_edb_data(:, 1 : 3), 2);
storeHarbor = table(w_edb_times, storeHarbor);
storeHarbor.Properties.VariableNames = {'Date', 'StoreHarbor'};
storeHarbor = storeHarbor(storeHarbor.Date >= dateBegin & storeHarbor.Date <= dateEnd, :);

% 焦厂库存和钢厂库存 数据来源：钢联数据
% S5133852 钢厂焦炭库存 S5133860 国内钢厂（110家）焦炭平均可用天数（这两个应该相关性很高？）
% S5118225 大中型钢厂焦炭平均可用天数，S513打头的都是2017年才有数据，都不能用。。
% 焦厂库存和钢厂库存Wind只有2017年4月以后的数，钢联数据是从2011年开始的（2017年1月13之前是用50家样本数据换算的）
% 注意：钢厂库存数据从2017年1月开始正常更新的，之前的数是2017年6月份一次性添加上的
storeJCGC = readtable('C:\Users\fengruiling\Desktop\storeData.csv');

% 调整数据格式
storeJC = formatAdj(storeJCGC(:, 2:3));
storeJC.Properties.VariableNames = {'Date', 'StoreJC'};
storeJC = storeJC(storeJC.Date >= dateBegin & storeJC.Date <= dateEnd, :);
storeGC = formatAdj(storeJCGC(:, [2 5]));
storeGC.Properties.VariableNames = {'Date', 'StoreGC'};
storeGC = storeGC(storeGC.Date >= dateBegin & storeGC.Date <= dateEnd, :);

% 2.独立焦化厂产能利用率
productionRatio = readtable('C:\Users\fengruiling\Desktop\productionRatio.csv');
% 这有个问题，独立焦化厂产能利用率这个数据很多都是后期补上的，其实是用到未来数据，但是貌似情有可原？
% 调整数据格式
productionRatio = formatAdj(productionRatio(:, 2:3));
productionRatio.Properties.VariableNames = {'Date', 'ProductionRatio'};
productionRatio = productionRatio(productionRatio.Date >= dateBegin & productionRatio.Date <= dateEnd, :);

% 3.下游钢厂高炉产能利用率

gaoluRatio = readtable('C:\Users\fengruiling\Desktop\gaoluRatio.csv');
gaoluRatio = formatAdj(gaoluRatio(:, 2:3));
gaoluRatio.Properties.VariableNames = {'Date', 'GaoluRatio'};
gaoluRatio = gaoluRatio(gaoluRatio.Date >= dateBegin & gaoluRatio.Date <= dateEnd, :);

% 4.下游钢厂利润（盈利率） 这个用Wind数据，钢联的从2018年3月才开始有数
[w_edb_data, ~, ~, w_edb_times, w_edb_errorid, ~] = w.edb('S5708339','20130302',dateEnd,'Fill=Previous');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%dateBegin怎么不行。。。。。。。。。。。%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ifErrorStop()
% 青岛港从2014年才开始有数据，暂定先用天津、连云港、日照三地合计，趋势波动没有加上青岛那么大，但是日期全啊
w_edb_times = rowfun(@(x, f) datestr(x, 'yyyymmdd'), table(w_edb_times));
w_edb_times = table2array(rowfun(@str2double, w_edb_times));
gcProfitRatio = table(w_edb_times, w_edb_data);
gcProfitRatio.Properties.VariableNames = {'Date', 'GCProfitRatio'};
gcProfitRatio = gcProfitRatio(gcProfitRatio.Date >= dateBegin & gcProfitRatio.Date <= dateEnd, :);

% 5.焦炭平均库存可用天数：国内大中型钢厂，数据来源Wind2011.8.13起始 周度数据
[w_edb_data, ~, ~, w_edb_times, w_edb_errorid, ~] = w.edb('S5118225','20130302',dateEnd,'Fill=Previous');
ifErrorStop()
w_edb_times = rowfun(@(x, f) datestr(x, 'yyyymmdd'), table(w_edb_times));
w_edb_times = table2array(rowfun(@str2double, w_edb_times));
availableDayJ = table(w_edb_times, w_edb_data);
availableDayJ.Properties.VariableNames = {'Date', 'AvailableDayJ'};
availableDayJ = availableDayJ(availableDayJ.Date >= dateBegin & availableDayJ.Date <= dateEnd, :);

% 6. 炼焦煤平均库存可用天数： 国内大中型钢厂，数据来源Wind 2011.8.13起始 周度数据（但是焦煤库存看钢厂有用吗）
[w_edb_data, ~, ~, w_edb_times, w_edb_errorid, ~] = w.edb('S5118223','20130302',dateEnd,'Fill=Previous');
ifErrorStop()
w_edb_times = rowfun(@(x, f) datestr(x, 'yyyymmdd'), table(w_edb_times));
w_edb_times = table2array(rowfun(@str2double, w_edb_times));
availableDayJM = table(w_edb_times, w_edb_data);
availableDayJM.Properties.VariableNames = {'Date', 'AvailableDayJM'};
availableDayJM = availableDayJM(availableDayJM.Date >= dateBegin & availableDayJM.Date <= dateEnd, :);


% 7. 自变量加上焦炭现货价格数据 priceJ
% 焦煤和焦炭的现货价格Spearman correlation 0.95， 共线性太强，只能加priceJ进自变量，但效果也不好。。

% @2018.10.26
% 目前为止7个自变量，库存（港口、焦厂、钢厂三列）、独立焦化厂产能利用率、钢厂高炉利用率、钢厂盈利率、焦炭库存可用天数、焦煤库粗年可用天数、焦炭现货价格
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

regData.StoreJ = regData.StoreHarbor + regData.StoreJC + regData.StoreGC; % 港口+ 焦厂+ 钢厂库存合到一起
regData(:, 3:5) = [];


% regData自变量插补NaN
regData(:, 2:end) = varfun(@(x, y) fillmissing(x, 'previous'), regData(:, 2 : end));
regData = regData(all(~isnan(table2array(regData)),2), :); % 去除仍含有NaN的行


% regData包含因变量和目前为止所有自变量；
% 做标准化和消除共线性处理


% corr(regData.ProductionRatio(5:end), regData.GaoluRatio(5:end))
[sValue,condIdx,VarDecomp] = collintest(regData(:, [3, 5:8]));
% @10.30 GaoluRatio变量共线性强，先剔除
% @10.31 加入钢厂库存可用天数以后，productionRatio 和 gaoluRatio都变得共线性很高，都先剔除
% productionRatio, gaoluRatio, availableDayJ互相之间相关性都在0.4以上；
% 但是productionRatio和profit的相关性最高，其他两个都不高。。感觉还是只有productionRatio这一个变量就可以
% 剔除gaoluRatio以后就没有共线性了
regData.GaoluRatio = [];


% 自变量标准化 减均值除以标准差
% regData(:, 3:end) = varfun(@(x) zStandard(x), regData(:, 3:end)); % 做不做标准化回归的stats在这里没差别
% 先不做标准化，因为做完结果没啥区别，反而影响后面的置信区间结果（X有正有负不如都为正好弄）



%% 预测期货价格合理区间
% Y 比 X有一个滞后区间（生产周期）
% 先假设14天试一下
% 将y值向下错开14天，同一行上面是当天的x与14天后的利润y
% 这个地方有点难搞。。需要确切的时间差不变吗？还是差一点也行？

% nLag取10以上的话会导致realY明显提前于Spread，9-10左右二者比较同步
% 从N > 30 开始回归，前30 + nLag天不发出信号


realSpread = nan(size(regData, 1), 4); % 从第 nLag + 30 行开始有数据 % 第2列记录YReal, 第3列YHAT
realSpread(:, 1) = table2array(regData(:, 1));
regressR2 = nan(size(regData, 1), 3);
projY = nan(size(regData, 1), 2);
for iDay = (30 + nLag) : size(regData, 1)
    
    regDataLagY = regData.Profit(nLag : iDay);
    regDataLagX = regData(1 : iDay - (nLag - 1), 3 : end);
    regDataLagX = [ones(size(regDataLagX, 1), 1) table2array(regDataLagX)];
    % 这个回归结果是用1 : iDay - (nLag - 1)的X与nLag : iDay的Y回归得到的方程；
    % 用这个方程结果，输入iDay天的X ，得到iDay + nLag天的预测Y，作为iDay天的理论价差值（中间iDay - nLag + 2:iDay - 1这些X在这一步错过去，没有用）
    
    % 调整样本量，如果样本区间拉太长，会导致拟合的Y太平；也可能是有其他因素没纳入进来，波动率本身变大没有刻画出来。先减小样本量试试
    % 但是按说不应该，如果模型足够好的话，不应该样本量越大，效果反而不好了，说明你规则发生变化了，有因素没考虑到
%         if size(regDataLagY, 1) > 300
%             regDataLagY = regDataLagY(size(regDataLagY, 1) - 300 + 1 : end, :);
%             regDataLagX = regDataLagX(size(regDataLagX, 1) - 300 + 1 : end, :);
%         end
    
    [b, ~, r, ~, stats] = regress(regDataLagY, regDataLagX);
    % 调整R方
    adjR2 = 1 - (1 - stats(1)) * (size(regDataLagY, 1) - 1) / (size(regDataLagY, 1) - size(regDataLagX, 2) - 2);
    % 此处R方会随样本量变大而变大，但不是因为N本身的影响，adjustedR2也在变大?
    % TSS 统计量
    %     TSS = sum((regDataLagY - sum((b' .* regDataLagX), 2)) .^ 2); % 错了错了，这是残差平方和
%     residual = regDataLagY - sum((b' .* regDataLagX), 2);
    SSE = sum(r .^ 2);
    SST = SSE / (1 - stats(1));
    % PRESS统计量
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
    regressR2(iDay, 2) = adjR2; % 记录每个回归方程的拟合优度
    regressR2(iDay, 3) = preR2;
    
%     yHatDown = bint(1, 1) + sum(bint(2:end, 1) .* table2array(regData(iDay, 3:end))'); % iDay的自变量，预测的是iDay + nLag的因变量，对应的是iDay的Spread
%     yHatUp = bint(1, 2) + sum(bint(2:end, 2) .* table2array(regData(iDay, 3:end))');
    yHat = b(1) + sum(b(2:end) .* table2array(regData(iDay, 3:end))');
    
    if iDay + nLag <= size(regData, 1)
%     yHat = regData.Profit(iDay + nLag - 1);
    realSpread(iDay, 2) = regData.Profit(iDay); % YReal 只有size(regData) - nLag有realY,再往下的就不知道realY了
%     realSpread(iDay, 2) = regData.Profit(iDay + nLag - 1); % YReal 只有size(regData) - nLag有realY,再往下的就不知道realY了
% 注： realY这个数你在iDay的时候并不知道，写在这里只是为了画图看   
% 11.9 加一条线
    realSpread(iDay, 4) = regData.Profit(iDay + nLag - 1); % nLag天后的真实利润
   
    end
    realSpread(iDay, 3) = yHat; % 这么操作（每次回归得到一个当前值）是为了不用未来信息
%     realSpread(iDay, 4) = yHat - interval;
%     realSpread(iDay, 5) = yHat + interval;


    % 以iDay = 45这天为例，X的数据已知到45，然后用1：36的X 和10：45的Y构建一个回归方程，用这个方程代入45日的X
    % 去预测45 + nLag - 1日的Y，作为45日的真实隐含spread，整个过程37-44的X被架空，并没有用到未来数据
    
    % yHat预测结果与焦厂实际利润（钢联数据）对比结果
    % 钢联数据，吨焦盈利这个数据2017年6月开始才有数。。这里就不比较了，把yHat输出到Excel里面比较吧
    if iDay + nLag - 1 <= size(regData, 1)
        projY(iDay + nLag - 1, 1) = regData.Date(iDay + nLag - 1);
        projY(iDay + nLag - 1, 2) = yHat;
        % projY的日期，与预测的吨焦利润一一对应
    end
    
    
    %%%%%%%%%%%%%%%% 残差r还有信息没拿出来，需要再优化回归方程%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %     yHat = b(1) + b(2) * regDataLagX(:, 2) + b(3) * regDataLagX(:, 3)  + b(4) * regDataLagX(:, 4);
    % 假设yHat就是滞后nLag的真实价格曲线，那把yHat往前挪nLag天就是当前的真实价格
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

% 第2列YReal是当天实际的现货利润；第3列YHat是预测NLag天后的实际利润；第6(4)列YReal是nLag天后的实际利润，第3列与第6列越相近回归预测越好

% @11.7 到目前为止的realSpread里面Spread都是利润，接下来用基差和副产品现货价格调整为纯Spread

% jicha.JichaJMA10 = ((movmax(jicha.JichaJ, [10, 0]) * 11) - jicha.JichaJ) / 10; % 这么写不行，因为最前面不到10的那些不能直接乘以11
% jicha.JichaJMA10 = MAx(jicha.JichaJ, 10); % 这个MA是包含自己在内的10天
% jicha.JichaJMMA10 = MAx(jicha.JichaJM, 10);
% realSpread = outerjoin(realSpread, paraM.jyPrice, 'type', 'left', 'MergeKeys', true);
% realSpread = outerjoin(realSpread, xianhuo, 'type', 'left', 'MergeKeys', true);

% adjValue = - realSpread.JichaJMA10 + 1 / paraM.rate * realSpread.JichaJMMA10;
% adjValue = paraM.fixedExpense - paraM.jiaoyouRatio * realSpread.PriceJY - realSpread.JichaJMA10 + 1 / paraM.rate * realSpread.JichaJMMA10;
% 理论基差不用MA10，用固定值试试
% adjValue = 0;
% realSpread(:, 2:5) = array2table(table2array(realSpread(:, 2:5)) + adjValue);
% realSpread = realSpread(:, 1:6);
% clear adjValue

%% 当天收盘价与当天真实价格比较

% 获取期货价格数据
% 品种
fut_variety = {'J','JM'};
% 信号相关
signalName = 'CTA1';
signalID = 101;

% paraM.jy
Cost.fix = 0; %固定成本
Cost.float = 2; %滑点
tradeP = 'open'; %交易价格
oriAsset = 10000000; %初始金额


% 数据相关
stDate = 0;
edDate = dateEnd; % 必须是交易日
load Z:\baseData\Tdays\future\Tdays_dly.mat
totaldate = Tdays(Tdays(:,1)>=stDate & Tdays(:,1)<=edDate,1);
sigDPath = '\\Cj-lmxue-dt\期货数据2.0\pairData';
% 添加路径
addpath(['gen_function\',signalName]);
% 导入数据
load \\Cj-lmxue-dt\期货数据2.0\usualData\minTickInfo.mat %品种最小变动价位
trade_unit = minTickInfo;
load(['\\Cj-lmxue-dt\期货数据2.0\usualData\PunitInfo\',num2str(totaldate(end)),'.mat']) %合约乘数
cont_multi = infoData;

proAsset = oriAsset;


for i_pair = 1:size(fut_variety,1)
    pFut1 = fut_variety{i_pair,1};
    pFut2 = fut_variety{i_pair,2};
    dataPath = [sigDPath,'\',pFut1,'_',pFut2];
    % 合约乘数
    contM1 = cont_multi{ismember(cont_multi(:,1),pFut1),2};
    contM2 = cont_multi{ismember(cont_multi(:,1),pFut2),2};
    % 参数
    %     pName = fieldnames(paraM);
    %     for p = 1:length(pName)
    %         str = ['para.',pName{p},'=paraM.',pName{p},'(i_pair);'];
    %         eval(str)
    %     end
    
    % 导入换月日数据
    load(['\\Cj-lmxue-dt\期货数据2.0\code2.0\data20_pair_data\chgInfo\',pFut1,'_',pFut2,'.mat'])
    chgInfo = chgInfo(chgInfo.date>stDate & chgInfo.date<=edDate,:);
    
    % 生成信号-按合约循环
    res = totaldate(totaldate >= chgInfo.date(1));
    res = res(1 : (end - 1)); %不然最后一行是空值
    res = array2table([res, NaN(size(res, 1), 5)], 'VariableNames', {'Date', 'PosLabel', 'Hands1', 'Hands2', 'Cont1', 'Cont2'});
    res.Cont1 = num2cell(res.Cont1);
    res.Cont2 = num2cell(res.Cont2);
    tstData = table();
    
    for c = 1:height(chgInfo)
        c_stD = chgInfo.date(c); %该合约开始作为主力的日期
        if c~=height(chgInfo)
            c_edD = totaldate(find(totaldate==chgInfo.date(c+1),1)-1); %该合约作为主力的结束日期
        else %最后一段
            c_edD = totaldate(find(totaldate==edDate)-1);
        end
        cont1 = regexp(chgInfo{c,2}{1},'\w*(?=\.)','match');
        cont2 = regexp(chgInfo{c,3}{1},'\w*(?=\.)','match');
        % 导入数据
        data1 = getData([dataPath,'\',pFut1,'\',cont1{1},'.mat'],edDate);
        data2 = getData([dataPath,'\',pFut2,'\',cont2{1},'.mat'],edDate);
        [sigOpen, sigClose, resSignal] = getSignal(data1, data2, realSpread, paraM);
        sig = [sigOpen,sigClose];
        tstData = vertcat(tstData, resSignal(resSignal.Date >= c_stD & resSignal.Date <= c_edD, :));
        
        subplot(5, 4, c)
        plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.Spread) % 实际期货价差:蓝线       
        hold on
%         %         plot(lines.trend)
% 
        plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.SpreadUp)
        plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.SpreadDown)
%         plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.YHat) % 拟合Y
        plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.YReal) % 真实Y，利润，现货-现货， 红线
%        
% %         plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.YReal + interval)
% %         plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.YReal - interval)
% %         plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.JichaDiff) % 黄线
% %          plot(datenum(num2str(resSignal.Date), 'yyyymmdd'), resSignal.SpreadTheory) % nLag天后的真实利润 + 基差的差（理想中的蓝线:紫线）
        datetick('x', 'yyyymmdd', 'keepticks', 'keeplimits')
        
        
        % 以下为止损部分
        % 可以理解为对pureSig的一个修正，需要止损的部分就直接把持仓信号和手数改为0，并把持续几天不开仓都改为0即可（先没动）
        if strcmpi(tradeP,'open')
            tddata = [data1.open,data2.open];
        end
        tddata = [tddata,data1.close,data2.close];
        Cost.unit1 = trade_unit{ismember(trade_unit(:,1),pFut1),2};
        Cost.unit2 = trade_unit{ismember(trade_unit(:,1),pFut2),2};
        Cost.contM1 = contM1;
        Cost.contM2 = contM2;
        % pure_signal分为3个阶段，第二阶段为止损修改平仓信号，最后输出的pureSig已经是止损后的信号
        pureSig = pure_signal(sig, data1.date, tddata, c_stD, c_edD, oriAsset, data1, data2, paraM.rate*ones(size(sig,1),1), contM1, contM2, lossRatio, Cost);
        
        resI = array2table(pureSig, 'VariableNames', {'Date', 'PosLabel', 'Hands1', 'Hands2'});
        resI.Cont1 = repmat(cont1, size(pureSig, 1), 1);
        resI.Cont2 = repmat(cont2, size(pureSig, 1), 1);
        fromIdx = find(res.Date == c_stD);
        endIdx = find(res.Date == c_edD);
        res((fromIdx : endIdx), :) = resI(resI.Date >= c_stD & resI.Date <= c_edD, :);
    end
    
end


targetPortfolio = num2cell(NaN(size(res, 1), 2));   %分配内存
for iDate = 1:size(res, 1)
    hands = {char(res(iDate, :).Cont1), res(iDate, :).Hands1;...
        char(res(iDate, :).Cont2), res(iDate, :).Hands2};
    targetPortfolio{iDate, 1} = hands;
    targetPortfolio{iDate, 2} = res.Date(iDate);
end

% getholdinghands部分不涉及换月日，因为是每段循环的，本部分内没有合约换月
% 但是合约换月日要用于输入回测平台数据部分adjFactor



% TradePara用于输入回测平台
TradePara.futDataPath = '\\Cj-lmxue-dt\期货数据2.0\dlyData\主力合约'; %期货主力合约数据路径
TradePara.futUnitPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\minTickInfo.mat'; %期货最小变动单位
TradePara.futMultiPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\PunitInfo'; %期货合约乘数
TradePara.futLiquidPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\liquidityInfo'; %期货品种流动性数据，用来筛选出活跃品种，剔除不活跃品种
TradePara.futSectorPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\SectorInfo.mat'; %期货样本池数据，用来确定样本集对应的品种
TradePara.futMainContPath = '\\Cj-lmxue-dt\期货数据2.0\商品期货主力合约代码'; %主力合约代码
% TradePara.usualPath = '..\data\usualData';%基础通用数据 这个地址是哪里？
TradePara.usualPath = '\\Cj-lmxue-dt\期货数据2.0\usualData';
TradePara.fixC = 0.0000; %固定成本
TradePara.slip = 2; %滑点
TradePara.PType = 'open'; %交易价格，一般用open（开盘价）或者avg(日均价）


[BacktestResult,err] = CTABacktest_GeneralPlatform_3(targetPortfolio,TradePara);

figure
% 净值曲线
dn = datenum(num2str(BacktestResult.nv(:, 1)), 'yyyymmdd');
plot(dn, (oriAsset + BacktestResult.nv(:, 2)) ./ oriAsset)
datetick('x', 'yyyymmdd', 'keeplimits')

BacktestAnalysis = CTAAnalysis_GeneralPlatform_2(BacktestResult);
testRes(:, iTest) = cellfun(@(x) double(x), BacktestAnalysis(:, 2));
testRegressR2(:, iTest) = mean(regressR2, 'omitnan')';
end
% plot(datenum(num2str(tstData.Date), 'yyyymmdd'), tstData.Spread - 150) % 真实Y，利润，现货-现货， 红线
% hold on
% plot(datenum(num2str(tstData.Date), 'yyyymmdd'), tstData.YReal) % 真实Y，利润，现货-现货， 红线
% datetick('x', 'yyyymmdd', 'keepticks', 'keeplimits')
