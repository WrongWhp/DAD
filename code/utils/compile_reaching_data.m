function [Y1,Y2,T,Pos,Vel,Acc,Force,N] = compile_reaching_data(trial_data,Ndelay,Nsamp,whichcue,removedir)

L = length(trial_data);
for i=1:L, 
    out(i) = trial_data(i).target_direction; 
end

id1 = find(~isnan(out));
whichdeg = unique(rad2deg(out(id1)));

if nargin>3
    whichdeg(removedir+1)=[];
end   

Y2 = []; Y1 = []; T =[]; N=[];
Pos = []; Vel = []; Acc = []; Force = [];
Ls = length(id1);
for i=1:Ls
    
    currT = find(whichdeg==rad2deg(trial_data(id1(i)).target_direction))-1;
    
    if ~isempty(currT)
       
        data1 = trial_data(id1(i)).M1_spikes;
        data2 = trial_data(id1(i)).PMd_spikes;
        
        if strcmp(whichcue,'target')
            Nstart = min(trial_data(id1(i)).idx_target_on+Ndelay, trial_data(id1(i)).idx_go_cue);
            Nend = min(trial_data(id1(i)).idx_go_cue-1,trial_data(id1(i)).idx_target_on+Ndelay+Nsamp);
        else
            Nstart = min(trial_data(id1(i)).idx_go_cue + Ndelay, trial_data(id1(i)).idx_trial_end);
            Nend = min(trial_data(id1(i)).idx_trial_end,trial_data(id1(i)).idx_go_cue+Ndelay+Nsamp);
        end
        
        if Nstart < Nend
            idx = Nstart:Nend;
            data1 = data1(idx,:);
            data2 = data2(idx,:);
            ntmp = ones(length(idx),1);
            ntmp(max(length(idx)-Nsamp,1):length(idx))=2;

            T = [T; currT*ones(length(idx),1)];
            N = [N; ntmp];
            Pos = [Pos; trial_data(id1(i)).pos(idx,:)];
            Vel = [Vel; trial_data(id1(i)).vel(idx,:)];
            Acc = [Acc; trial_data(id1(i)).acc(idx,:)];
            Force = [Force; trial_data(id1(i)).force(idx,:)];

            Y2 = [Y2; data2];
            Y1 = [Y1; data1];
        end
    end

end


end