%%
% List of open inputs

Scans        = 'REST2_LR';
frames       = 1:290;

TemplateFile = ['prep_config_' num2str(max(frames)) 'frames']; % Both DMN and DMN, CEN, SN
TemplateVer  = '03';

DCMVer = '01';

switch computer, case 'GLNXA64'
    root_dir = '/****/HCP_data/'
    otherwise
        root_dir     = '****\HCP_data\'; % Use the local disk
end


dcm_dir      = fullfile(root_dir,'DCM'); % Where the DCM results will be saved
batch_dir    = fullfile(root_dir,'Batch_Jobs'); % Where the template batch is
data_dir     = fullfile(root_dir,'RS_2'); % Temporal data folder

missing = 1;
job_template{1} = cellstr(fullfile(batch_dir,['template_' TemplateVer '_hcp_dcm_' TemplateFile '.mat']));
job_template{2} = cellstr(fullfile(batch_dir,['template_' TemplateVer '_hcp_dcm_' TemplateFile '_nosmooth.mat']));

%% What to do

recover    = 'no'  % Hopefully, we are done with that- other cases "unpack"
prep_conf  = 'no' % Run smoothing, SPMs and extract VOIs
create_GCM = 'yes' % Creates a GCM from all subjects
est_GCM    = 'yes' % Estimates the GCM


%% Selection of Subjects
cd(data_dir)

Subj = dir('1*')

nsub = length(Subj);

%% Start the parallel processing

%parpool(10) % 10 cores
spm('defaults', 'FMRI');

%% Recover files - fix previous batch error or unzip data

switch recover, 
    
    case 'unpack'
        parfor crun =1:nsub
            cd(fullfile(data_dir,Subj(crun).name))
            switch computer, case 'GLNXA64'
                try
                    system(['gunzip rfMRI_REST2_LR.nii.gz'])
                end
                otherwise
                    system(['"C:\Program Files\7-Zip\7z.exe" e rfMRI_REST2_LR.nii.gz'])
            end
        end
        

end



%% Prepare and configure the individual DCMs
%---------------

switch prep_conf, case 'yes'
    
    % Create an error-log file
    fid = fopen(fullfile(batch_dir,['error_log_' date]));
    fid = fopen(fullfile(batch_dir,['completed_log_' date]));
    
    cd(data_dir)
    
    %jobs = repmat(jobfile, 1, nrun);
    %inputs = cell(2, nrun);
    
    
    for crun = 1:nrun
        
        disp(['Working on: ' Subj(crun).name ';  ' Scans ])
        
        % Start the processing
        %-----------------------
        subj_dir = fullfile(data_dir,Subj(crun).name)
        result_dir=fullfile(subj_dir,'SPM');
        mkdir(result_dir)
        
        
        % Scans & right job
        cd(subj_dir)
        scans=dir('*.nii');
        if length(scans)==2
            if scans(1).bytes==scans(2).bytes && strcmp(scans(2).name(1),'s')
                fMRIScans      = cellstr(spm_select('ExtFPList',subj_dir,['^srfMRI_' Scans '*.\.nii$'],frames)); % Smoothed images
                jobfile = job_template{2};
            else
                fMRIScans      = cellstr(spm_select('ExtFPList',subj_dir,['^rfMRI_' Scans '*.\.nii$'],frames)); % Unsmoothed
                jobfile = job_template{1};
            end
        else
            fMRIScans      = cellstr(spm_select('ExtFPList',subj_dir,['^rfMRI_' Scans '*.\.nii$'],frames)); % Unsmoothed
            jobfile = job_template{1};
        end
        
        
        % Movement Parameter
        %-------------------
        %MovementPara   = cellstr(spm_select('FPList',subj_dir,'Movement_Regressors.txt')); % Run Batch Jobs: Any Files - cfg_files
        RP = load(spm_select('FPList',subj_dir,'Movement_Regressors.txt')); % Run Batch Jobs: Any Files - cfg_files
        R = RP(frames,:);
        RP_file = fullfile(subj_dir,['Movement_Regressors_' num2str(max(frames)) '.mat']);
        save(RP_file,'R');
        
        ResultsRootDir = cellstr(result_dir);
        
        % Copy the dummy file to the traget folder
        DCMFile    = fullfile(result_dir,['DCM_' DCMVer '.mat']);
        copyfile(fullfile(batch_dir,['DCM_' DCMVer '_dummy.mat']),DCMFile);
        
        
        
        inputs=[{fMRIScans}, {cellstr(RP_file)}, {ResultsRootDir}, {cellstr(DCMFile)} ];
        if isempty(spm_select('FPList',fullfile(subj_dir,'SPM','SPM_01_WM_CSF'),'RPV.nii'))
            
            try % Note: There are subject with incomplete data
                spm_jobman('run', jobfile, inputs{:});
                
                fid = fopen(fullfile(batch_dir,['completed_log_' date]),'a');
                fprintf(fid,'%s\n',['Analysis completed: ' Subj(crun).name ';  ' Scans ]);
                fclose(fid);
                
            catch
                fid = fopen(fullfile(batch_dir,['error_log_' date]),'a');
                fprintf(fid,'%s\n',['Not analysed: ' Subj(crun).name ';  ' Scans ]);
                fclose(fid);
                
            end
        end
    end
    %save(fullfile(batch_dir,['job_' TemplateVer '_input_dcm_' DCMver '_' date]),'inputs')
    
end

%% Create a GCM at the end

switch create_GCM, case 'yes'
    
    for crun = 1:nrun
        load(fullfile(data_dir,Subj(crun).name,'SPM',['DCM_' DCMVer '.mat']));
        GCM{crun,1}=DCM;
    end
    
end

GCM_Dir = fullfile(root_dir,'DCM',['DCM_' DCMVer]);
mkdir(GCM_Dir)

save(fullfile(GCM_Dir,['GCM_1st_' DCMVer '.mat']),'GCM');


%% Estimate the GCM

switch est_GCM, case 'yes'
    
    GCM_Dir = fullfile(root_dir,'DCM',['DCM_' DCMVer]);  
    cd(GCM_Dir)
    
    load(['GCM_1st_' DCMVer '.mat'])

    M.X = ones(nsub,1);
    %[GCM_1st, PEB_1st, M_1st, HCM_1st]= spm_dcm_peb_fit(GCM)%,M,{'A'});
    GCM_1st = spm_dcm_fit(GCM);
      
    save(fullfile(GCM_Dir,'GCM_01_PEB_fit_1stLevel_defaults'),'GCM_1st')%,'M_1st','PEB_1st','HCM_1st','nsub')

    [GCM_1st_2, PEB_1st, M_1st, HCM_1st]= spm_dcm_peb_fit(GCM_1st,M,{'A'})
    
    save(fullfile(GCM_Dir,'GCM_01_PEB_fit_1stLevel'),'GCM_1st','GCM_1st_2','M_1st','PEB_1st','HCM_1st','nsub')

end

