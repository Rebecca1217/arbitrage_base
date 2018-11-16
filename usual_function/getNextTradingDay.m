function nextTradingDay = getNextTradingDay(currentDay)
%GETNEXTTRADINGDAY 

Tdays = load('Z:\baseData\Tdays\future\Tdays_dly.mat');
Tdays = Tdays.Tdays;
idx = find(Tdays == currentDay, 1, 'first');
nextTradingDay = Tdays(idx + 1);

end

