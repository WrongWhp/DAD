% script 3D alignment
% test synthetic + real data with same methods

%% (1) within subjects (iteration over different partitions of train/test sets)

% removedir = [0, 2, 7]; 
removedir = [0, 2, 7];  %%%% 0.5 with few fails
A = 180; %every 2 deg
Ts=.20; 
%psamp = 0:0.1:0.5;
psamp = 0.15;
numsteps = 9;
numsol = 5;
Niter = 1;

for outiter = 1:length(psamp)
    
    percent_samp = psamp(outiter); % amount for training
    
    if percent_samp==0
        numIter=1;
    else
        numIter=Niter;
    end

    if outiter == 1
        Data0 = prepare_superviseddata(Ts,'chewie1','mihi',[]);
        Data = prepare_superviseddata(Ts,'mihi','mihi',[],0);
    end

    [~,~,~,XtrC,~,~,~,~] = removedirdata(Data0,removedir);
    [Xtest,Ytest,Ttest,Xtrain,Ytrain,Ttrain,~,Ntrain] = removedirdata(Data,removedir);

    R2 = zeros(5+numsol,numIter,length(psamp));
%    R2C = zeros(6,numIter);
    R2MC = zeros(5+numsol,numIter,length(psamp));
    minVal = zeros(numIter,length(psamp));
    
    %Results = cell(numIter,1);
    %ResultsC = cell(numIter,1);
    %ResultsMC = cell(numIter,1);
    
    for nn = 1:numIter % random train/test split

            [Xtr,Ytr,Ttr,Xte0,Yte0,Tte0,trainid,testid] = splitdataset(Xtrain,Ytrain,Ttrain,Ntrain,percent_samp); 
            numte = size(Yte0,1);
            permzte = randperm(numte);
            
            for mm = 1:numsteps % loop over amount of test data
                
                numtest = ceil(0.1*(mm+1)*numte);
                Xte = Xte0(permzte(1:numtest),:);
                Yte = Yte0(permzte(1:numtest),:);
                Tte = Tte0(permzte(1:numtest),:);
                
                %%%% supervised & least-squares
                fldnum=10; lamnum=500;
                [Wsup, ~, ~, ~]= crossVaL(Ytr, Xtr, Yte, lamnum, fldnum);
                r2sup = evalR2(Xte,[Yte,ones(size(Yte,1),1)]*Wsup);     
                % least squares error (best 2 dim projection)
                warning off, Wls = (Yte\Xte); r2ls = evalR2(Xte,Yte*Wls); 
   
                % throw away neurons that dont fire
                id2 = find(sum(Yte)<20); 
                Yr = Yte; 
                Yr(:,id2)=[];

                % dimensionality reduction
                M1{1} = 'FA'; [Vr,Methods] = computeV(Yr,3,M1);
        
                X3D = mapX3D(Xtr); % split (training set + extra chewie training for DAD)
                [R2(1:3+numsol,nn), ~] = run3Ddad(X3D,Vr,Xte,A,Methods,numsol);
                R2(4+numsol,nn) = r2sup; R2(5+numsol,nn) = r2ls;
                
%                 Results.Yr = Yr;
%                 Results.Tte = Tte;
%                 Results.Xte = Xte;
%                 Results.Stats = computesplitstats(Xte,Xtr,Tte,Ttr);
%                 Results.trainid = trainid;
%                 Results.testid = testid;
%                 Results.Tte = Tte;
%                 Results.Xte = Xte;

                X3D = mapX3D([Xtr; XtrC]); % split (training set + extra chewie training for DAD)
                [R2MC(1:3+numsol,nn), ~] = run3Ddad(X3D,Vr,Xte,A,Methods,numsol);
                R2MC(4+numsol,nn) = r2sup; R2MC(5+numsol,nn) = r2ls;
            
                display(['Supervised decoder, R2 = ', num2str(r2sup,3)])    
                display(['Least-squares Projection, R2 = ', num2str(r2ls,3)])
                display(['Num test = ', int2str(numtest), ' Iter # ', int2str(nn)])
            end

    
%         if max(R2C(1:4,nn))<0.3
% 
%             figure; 
%             subplot(2,2,1); colorData2014(Xte,Tte); title('Ground truth')
%             subplot(2,2,2); colorData2014(Res{1}.V,Tte); title('2D projection after cone alignment')
%             subplot(2,2,3); colorData2014(Res{1}.Xrec,Tte); title('Final solution')
%             subplot(2,2,4); colorData2014(Res{1}.Vflip,Tte); title('Second best solution')
% 
%         end

    end
    
    save(['Results-2-3-2016-psamp-', int2str(100*percent_samp)])
    
end % end outer iteration (diff vals of psamp)

%     s = zeros(6,7);
%     for i=1:6; 
%         s(:,i) = computestats(R2(i,:)); 
%     end
%     s(:,7) = computestats(max(R2(1:4,:))); 
% 
%     sMC = zeros(6,7);
%     for i=1:6;
%     sMC(:,i) = computestats(R2MC(i,:));
%     end
%     sMC(:,7) = computestats(max(R2MC(1:4,:))); 
% 
%     sC = zeros(6,7);
%     for i=1:6;
%     sC(:,i) = computestats(R2C(i,:));
%     end
%     sC(:,7) = computestats(max(R2C(1:4,:))); 
% 
%     save(['Results-3D-within-train-0pt15-remove027-psamp-0pt',int2str(100*percent_samp),'.mat'], ...
%           'ResultsC','ResultsMC','Results','R2','R2MC','R2C','s','sMC','sC')
% 
% end % end outer iteration
% 
% figure; 
% for i=1:5
%     num = i*10;
%     load(['Results-3D-within-train-0pt15-remove027-psamp-0pt',int2str(num),'.mat'])
%     subplot(5,3,(i-1)*3 +1); hist(max(R2(1:4,:)),20) 
%     subplot(5,3,(i-1)*3 +2); hist(max(R2MC(1:4,:)),20) 
%     subplot(5,3,(i-1)*3 +3); hist(max(R2C(1:4,:)),20) 
% end
% 

    % bootstrap sampling to get standard error
    % r2boot = bootstrp(Nsamp,@median,R2');
    % l2boot = bootstrp(Nsamp,@median,L2err');
    % se = [std(r2boot)', std(l2boot)'];

    % save Results_3D_within_subject(1)

    % Results (w/ multiple restarts in conefit2.m)
    %%%%%%%%%%%%
    % numA = 180 , k = 9 , Method = PCA, R2 = 0.554
    % numA = 180 , k = 9 , Method = MDS, R2 = -0.149
    % numA = 180 , k = 9 , Method = GPLVM, R2 = -0.149
    % numA = 180 , k = 9 , Method = ProbPCA, R2 = -0.149
    % numA = 180 , k = 9 , Method = Isomap, R2 = -0.224
    % numA = 180 , k = 9 , Method = FA, R2 = 0.626
    % Supervised decoder, R2 = 0.666
    % Least-squares Projection, R2 = 0.856
    % Iterations left = 9
    %%%%%%%%%%%%
    % numA = 180 , k = 9 , Method = PCA, R2 = 0.0614
    % numA = 180 , k = 9 , Method = MDS, R2 = 0.0614
    % numA = 180 , k = 9 , Method = GPLVM, R2 = 0.0614
    % numA = 180 , k = 9 , Method = ProbPCA, R2 = -0.927
    % numA = 180 , k = 9 , Method = Isomap, R2 = -0.378
    % numA = 180 , k = 9 , Method = FA, R2 = 0.557
    % Supervised decoder, R2 = 0.691
    % Least-squares Projection, R2 = 0.858
    % Iterations left = 8
    %%%%%%%%%%%%
    % numA = 180 , k = 9 , Method = PCA, R2 = -0.166
    % numA = 180 , k = 9 , Method = MDS, R2 = -0.906
    % numA = 180 , k = 9 , Method = GPLVM, R2 = -0.91
    % numA = 180 , k = 9 , Method = ProbPCA, R2 = -0.912
    % numA = 180 , k = 9 , Method = Isomap, R2 = -0.447
    % numA = 180 , k = 9 , Method = FA, R2 = 0.664
    % Supervised decoder, R2 = 0.725
    % Least-squares Projection, R2 = 0.856
    % Iterations left = 7
    %%%%%%%%%%%%

