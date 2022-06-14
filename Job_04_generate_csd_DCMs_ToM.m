% Create CSD for the Social Task
root_dir = '****\DCM_02_taskDCM'
data_dir = '****\HCP_data\SocialPre'

cd(data_dir)

subj=dir('1*')

matlabbatch{1}.cfg_basicio.run_ops.runjobs.jobs = {'*****\template_04_make_csd.mat'};
matlabbatch{1}.cfg_basicio.run_ops.runjobs.inputs = {};
matlabbatch{1}.cfg_basicio.run_ops.runjobs.save.dontsave = false;
matlabbatch{1}.cfg_basicio.run_ops.runjobs.missing = 'skip';

for i=1:length(subj)
    matlabbatch{1}.cfg_basicio.run_ops.runjobs.inputs{i}{1}.indir=cellstr(fullfile(data_dir,subj(i).name));
end

save(fullfile(root_dir,'job_make_csd_gen.mat'),'matlabbatch')

spm_jobman('run',matlabbatch)

%% Run PEB

cd(data_dir)

for i=1:length(subj)
    DCM_files_csd{i,1}=fullfile(data_dir,subj(i).name,'DCM_csd.mat');
end

DCM_HCP = spm_dcm_fit(DCM_files_csd);

save(fullfile(root_dir,'CSD','DCM_Social_CSD'),'DCM_HCP','DCM_files_csd')