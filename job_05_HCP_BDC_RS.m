DCMver = '01';

switch computer, case 'GLNXA64'
    root_dir     = '/****/HCP_data'; % Use the local disk
    
    case 'PCWIN64'
    root_dir     = '*****HCP_data\'; % Use the local disk
end     


dcm_dir      = fullfile(root_dir,'DCMs','DCM'); % Where the DCM results will be saved
batch_dir    = fullfile(root_dir,'Batch_Jobs'); % Where the template batch is
ynames = {'RS_2', 'SocialPre'};

for i=1:length(ynames)
    data_dir{i}     = fullfile(dcm_dir,ynames{i},['DCM_' DCMver]); % Temporal data folder
end
%% Get DCMs

for i=1:2
    load(spm_select('FPListRec',data_dir{i},['GCM_' DCMver '_PEB_fit_1stLevel.mat']))
    GCM = GCM_1st;
    %save(fullfile(data_dir{i},['GCM_4_BDC']),'GCM');
    GCMs{i} = fullfile(data_dir{i},['GCM_4_BDC.mat']);
end


%%


%% Run BDC


M.bmr = false
 [d,BMA,PEBs] = spm_dcm_bdc(cellstr(GCMs),{'A'},M,ynames)
 save(fullfile(dcm_dir,['BDC_01']),'d','BMA','PEBs')

 [d_BOLD,BMA_BOLD,PEBs_BOLD] = spm_dcm_bdc(cellstr(GCMs),{'transit','decay','epsilon','a'},M,ynames)
 save(fullfile(dcm_dir,['BDC_01_BOLD']),'d_BOLD','BMA_BOLD','PEBs_BOLD')

 [d_CSD,BMA_CSD,PEBs_CSD] = spm_dcm_bdc(cellstr(GCMs),{'a'},M,ynames)
 save(fullfile(dcm_dir,['BDC_01_CSD']),'d_CSD','BMA_CSD','PEBs_CSD')

