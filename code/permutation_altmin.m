%function permutation_altmin(linkfn,Data)

Ttest = Data.Ttest;
Ttrain = Data.Ttrain;
Ytest = Data.Ytest;
Xtest = Data.Xtest;

NumIter = 10;
display = 1;
tol = 1e-5;
linkfn = 'poisson';
%linkfn = 'normal';

%% Define X (Initialization) and Y (Data)

% define Y
% throw away points with low firing (will make W blow up)
Y = Ytest;
id = find(sum(Ytest)<50);
Y=Ytest; Y(:,id)=[];


% 3D model
%Vdir = atan2(Xtest(:,2),Xtest(:,1));
%Vmag = norms(Xtest')';
%Xtest2 = [Xtest, Vmag, log(Vmag).*cos(Vdir), log(Vmag).*sin(Vdir), log(Vmag)]; 
%Xtest2 = [log(Vmag).*cos(Vdir), log(Vmag).*sin(Vdir), log(Vmag)]; Xnew = Xtest2;
%Xnew = Xtest2 + randn(size(Xtest2))*10;

% permuted starting point
%permz = randperm(T);
%Xnew = Xtest2(permz,:);

% supervised solution
Xnew = Xtest;

% initialize with expPCA
%[V, ~, ~] = ExpFamPCA(Y,2);
%Xnew = normal(V);


%%
[T,N] = size(Y);
dev = zeros(N,NumIter);
R2val = zeros(NumIter,1);
Dev = zeros(NumIter,1);

for j=1:NumIter
    
    Wcurr = zeros(size(Xnew,2)+1,N);
    for i=1:N
        [Wcurr(:,i),dev(i,j),~] = glmfit(Xnew,Y(:,i),linkfn); 
    end
    Dev(j) = sum(dev(:,j)); % record deviance of fit
    
    if display==1
        close all,
        figure; subplot(1,3,1); colorData2014(Xtest,Ttest); 
        subplot(1,3,2); colorData2014(Xnew(:,1:min(3,size(Xnew,2))),Ttest); 
        title(num2str(evalR2(Xtest,Xnew(:,1:2)),3));
    end

    Xcurr = zeros(T,size(Xnew,2));
    for i=1:T
        Xcurr(i,:) = glmfit(Wcurr(2:end,:)',Y(i,:),linkfn,'offset',Wcurr(1,:)','constant','off')'; 
    end
    
    Xnew = Xcurr;
    
    if display==1
        subplot(1,3,3); hold off; colorData2014(Xnew(:,1:min(3,size(Xnew,2))),Ttest); 
        title(num2str(evalR2(Xtest,Xnew(:,1:2)),3));
        pause,
    end
    R2val(j) = evalR2(Xtest,Xnew(:,1:2));
    
    if j>1
        convcrit = abs(Dev(j)-Dev(j-1))/Dev(j);
        if convcrit<tol
            return
        end
    end
    % end test
    
end

%end % end function
