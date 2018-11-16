function sigLi = getSigLines(sigDirect) 
% 忽略了第一行就发出信号的情况
% 方向、信号发出所在行、信号结束所在行


difSig = [sigDirect(1);diff(sigDirect)];
locs = find(difSig==1); %信号发出所在行

sigLi = zeros(length(locs),3);
sigLi(:,1) = 1;
sigLi(:,2) = locs; %发出信号所在行
for l = 1:length(locs)
    edL = find(difSig(locs(l):end)==-1,1,'first')+locs(l)-1;
    if isempty(edL)
        sigLi(l,3) = nan;
    else
        sigLi(l,3) = edL;
    end
end

end