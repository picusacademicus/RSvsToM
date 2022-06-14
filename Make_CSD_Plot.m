%load('S:\Project\ReState\HCP_data\DCMs\DCM\RS_2\DCM_01\GCM_4_BDC.mat')
load('S:\Project\ReState\HCP_data\DCMs\DCM\SocialPre\DCM_01\GCM_4_BDC.mat')

Hz   = GCM{1}.Hz;                 % frequencies
name = {GCM{1}.xY.name};          % names
ns   = size(GCM{1}.a,1);

Hs=zeros(length(Hz),ns)

for s=1:length(GCM)
    % number of regions
    
    for i=1:ns
        %Hs_gcm{s}(:,i) = abs(GCM{s}.Hs(:,i,i));
        Hs(:,i)= Hs(:,i)+abs(GCM{s}.Hs(:,i,i));
    end
    
    
end

Hs=Hs/ns

figure
plot(Hz,Hs), hold on
title({'Spectral density (neural)'},'FontSize',16)
xlabel('frequency (Hz)')
ylabel('abs(CSD)')
axis square, spm_axis tight
legend(name),legend('boxoff')
