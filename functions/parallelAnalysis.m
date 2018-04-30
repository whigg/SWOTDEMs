function [U,S,V,iSV,iSig] = parallelAnalysis(z,n,grp,p,plotOpt)
%% svdPA.m 
% Performs SVD on 'z' followed by factor analysis using Parallel Analysis
% with 'n' iterations.
%
% Optional 'grp' argument is groups of columns to be tested against
% eachother. Should be vector with length equal to number of columns in
% 'z'. Orbits should have the same value, order/values don't matter as long
% they are different. Each eigenvector in V is tested to see if any groups
% are different from the remaining values. Any eigenvectors that show this
% significace are interpreted as observational errors from radar geometry,
% removed from iSV, and recorded in iSig.
%
% plotOpt is a binary option to plot V vectors that were removed after
% parallel analysis.
%
% 4/12/18 Ted Langhorst
%%
if ~exist('n','var')
    error('Must enter number of iterations as second argument')
end

testGroup = 1;
if ~exist('grp','var')
    testGroup = 0;
    grp = 1;
elseif ~exist('p','var')
    p = 0.05; 
    warning('Using default p-value: 0.05')
end

if ~exist('plotOpt','var')
    plotOpt = 0;
end

%% Parallel Analysis
sigma = std(z,1,2);

for i = 1:n
    zRand = randn(size(z)) .* sigma;
    [~,St(:,:,i),~] = svd(zRand);
end

SPAt = diag(mean(St,3));
[U,S,V] = svd(z,0);

maskPA = diag(S) >= SPAt; %factors according to PA

%% Group Test
[groups,~,grpIDs] = unique(grp);
iSig = zeros(size(V,2),1);

if testGroup && numel(groups)>1
    for i = 2:size(V,2)
        for j = 1:max(grpIDs) %test all pairs
            grp1 = grpIDs == j;
            grp2 = ~grp1;
            if ranksum(V(grp1,i),V(grp2,i)) < p
                iSig(i) = 1;
                
                if plotOpt
                    figure
                    bar(find(grp1),V(grp1,i),'r')
                    hold on
                    bar(find(grp2),V(grp2,i),'k')
                    hold off
                end
                
                break
            end
        end
    end   
end

iSig = find(iSig);
maskPA(iSig) = 0;
iSV = find(maskPA); %passes PA but not significant by group

sVals = diag(S);

figure
bar(sVals,'FaceColor',[0.8 0.8 0.8])
hold on
% bar(sVals(find(maskPA)),'k')
plot(SPAt,'r--','Linewidth',2)
hold off


end

