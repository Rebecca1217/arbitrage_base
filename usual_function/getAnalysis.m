function analysis = getAnalysis(rtn)

if size(rtn,2)>1
    rtn(:,1) = [];
end
analysis = zeros(6,size(rtn,2));
for f = 1:size(rtn,2)
    tmpR = rtn(:,f);
    st = find(~isnan(tmpR),1,'first');
    tmpR(1:st-1) = [];
    nv = ret2tick(tmpR);
    analysis(1,f) = nv(end);
    analysis(2,f) = mean(tmpR)*244;
    analysis(3,f) = std(tmpR)*sqrt(244);
    analysis(4,f) = maxdrawdown(nv);
    analysis(5,f) = analysis(2,f)/analysis(3,f);
    analysis(6,f) = analysis(2,f)/analysis(4,f);
end