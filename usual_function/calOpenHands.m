function hands = calOpenHands(closedata,ratio,asset,contM1,contM2)
% 计算两个品种的开仓手数

close1 = closedata(:,1)*contM1;
close2 = closedata(:,2);

% ratio = 1;
h1 = round(asset / (close1 + close2 * contM1 / ratio));
h2 = round(h1 / ratio * (contM1 / contM2));

% 计算是否超出了总市值
% totalAsset = h2 .* close2 .* contM2 + h1 .* close1;
% if totalAsset>asset %超过了总市值
%     h1 = h2-1;
% end
hands = [h1,h2];
