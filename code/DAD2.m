function Results = DAD2(Ytest,Xtrain,C,Xtest,Ttest,Ttrain)

% need Xtest to compute errors
Results=[];
if nargin<4
    Xtest = 0;
end

X0 = Xtrain;
Y0 = Ytest;

% (Step 1) Preprocessing 
[ Yter , idx1, idx2] = preprocess( Y0 , C.th1l , C.th1u , C.th2l , C.th2u, C.winsz);

C.dASz = size(X0,1);
C.ySz = size(Yter,2);
C.dSzE = size(Y0,1);
C.dszt = size(Yter,1);

[~,~, LP] = pca(Yter);

if length(idx1)>1 && length(idx2)>1 && min(LP)>C.EigRatio*max(LP)

% (Step 2) Dimensionality Reduction 
my=mean(Yter);
myV=ones(size(Yter,1),1)*my;
YterZ=Yter-myV;
[~,~,~,~,F]  = factoran(YterZ,2);

figure; subplot(1,2,1); colorData2014(normal(F),Ttest(idx2))

%%%%%%% Compute YLo
v1=ones(C.dszt,1);
v1L=ones(C.dSzE,1);
Yreg=[Y0(idx2,:),v1];
YteL=[Y0,v1L];     
lam=    2*norm(Yreg'*Yreg);
What=   pinv(Yreg'*Yreg+ lam*eye(size(Yreg,2)))*Yreg'*F;
YLoAll= YteL*What;
YLo2=   normal(YLoAll);

subplot(1,2,2); colorData2014(YLo2,Ttest)

% (Step 2) Correcting the rotation and scaling       %%%%%%%%%

% remove outliers from F
%dist2mn = pdist2(mean(F),F);
%idd =find(dist2mn>4); 
%idd2 = idx2; idd2(idd)=[];

%F2=F; F2(idd,:)=[]; 
%Ys2 = Ytest(idd2,idx1);
%W1 = pinv(Ys2)*F2;

%Xnm = normal(Xtrain);
%Fnm = normal(F2);
%Xscale = Xnm./repmat([max(abs(Fnm(:,1))),max(abs(Fnm(:,2)))],size(Xnm,1),1);

[YrKL, ~, KLD,~, ~,~,~] = minKL2(YLo2,normal(Xtrain),C);
Wcurr = pinv(YteL)*YrKL;

p_train = prob_grid(normal(Xtrain));
fKL = @(W)evalKLDiv_grid(W,YteL,p_train,50);

optionsKL= optimoptions('fminunc','Algorithm','quasi-newton','GradObj','off',...
                       'Display','iter-detailed', 'MaxFunEvals', 1.5e4);
[What, FVAL]= fminunc(fKL, Wcurr, optionsKL);


% figure; 
% subplot(2,3,1); colorData2014(F,Ttest(idx2)); title('F')
% subplot(2,3,2); colorData2014(YrKL,Ttest(idx2)); title('YrKLF')
% subplot(2,3,3); colorData2014(Ytest(idx2,idx1)*Htot,Ttest(idx2)); title('YLo2')
% subplot(2,3,4); colorData2014(YrKL,Ttest(idx2)); title('YrKL')
% subplot(2,3,5); colorData2014(Xtest,Ttest); title('Xtest')
% subplot(2,3,6); colorData2014(X0,Ttrain); title('Xtrain')

if Xtest~=0
    XteN = normal(Xtest); % ground truth (labels for Ytest)
    Results.sstot = sum( var( XteN ) );
    Results.ssKL = sum( mean(( XteN - YrKL ).^2) ); %XteN real kinematics
    Results.R2KL = 1- Results.ssKL/Results.sstot;
else
    % cant compute errors without labels
    Results.sstot = 0;
    Results.ssKL = 0;
end

Results.vKL = min(KLD);
Results.W0 = What; %predicted kinematics
Results.What = What; %predicted kinematics
Results.YrKLMat = YrKL; %predicted kinematics
Results.YLoMat = YLo2; % low -dimensional projection 
Results.idx1Mat = idx1; % rows used for training decoder
Results.idx2Mat = idx2; % cols used for training decoder
Results.Wcell = What; % decoding matrix
Results.mMat = my; % mean vector
Results.thMat = [C.th1l , C.th1u , C.th2l , C.th2u]; % thresholds used to preprocess data

end
