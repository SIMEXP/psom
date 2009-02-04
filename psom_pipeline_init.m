function file_pipeline = psom_pipeline_init(pipeline,opt)
%
% _________________________________________________________________________
% SUMMARY PSOM_PIPELINE_INIT
%
% Prepare the log folders of a pipeline before execution. 
%
% When the pipeline is executed for the first time, that means 
% initialize the dependency graph, store individual job description 
% in a matlab file, and initialize status and logs. 
%
% If the pipeline is restarted after some failures or update of some of the 
% jobs' parameters, the job status and logs are "refreshed" to make 
% everything ready before restart. See the notes at the end of the
% documentation for details.
%
% SYNTAX:
% FILE_PIPELINE = PSOM_PIPELINE_INIT(PIPELINE,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% * PIPELINE
%       (structure) a matlab structure which defines a pipeline.
%       Each field name <JOB_NAME> will be used to name the corresponding
%       job. The fields <JOB_NAME> are themselves structure, with
%       the following fields :
%
%       COMMAND
%           (string) the name of the command applied for this job.
%           This command can use the variables FILES_IN, FILES_OUT and OPT
%           associated with the job (see below).
%           Examples :
%               'niak_brick_something(files_in,files_out,opt);'
%               'my_function(opt)'
%
%       FILES_IN
%           (string, cell of strings, structure whose terminal nodes are
%           string or cell of strings)
%           The argument FILES_IN of the BRICK. Note that for properly
%           handling dependencies, this field needs to contain the exact
%           name of the file (full path, no wildcards, no '' for default
%           values).
%
%       FILES_OUT
%           (string, cell of strings, structure whose terminal nodes are
%           string or cell of strings) the argument FILES_OUT of
%           the BRICK. Note that for properly handling dependencies, this
%           field needs to contain the exact name of the file
%           (full path, no wildcards, no '' for default values).
%
%       OPT
%           (any matlab variable) options of the job. This field has no
%           impact on dependencies. OPT can for example be a structure,
%           where each field will be used as an argument of the command.
%
% * OPT
%       (structure) with the following fields :
%
%       PATH_LOGS
%           (string) The folder where the .mat files will be stored. That
%           folder needs to be empty, and left untouched during the whole
%           pipeline processing. Renaming or deleting files from the
%           PATH_LOGS may result in unrecoverable crash of the pipeline.
%
%       COMMAND_MATLAB
%           (string, default GB_PSOM_COMMAND_MATLAB or
%           GB_PSOM_COMMAND_OCTAVE depending on the current environment)
%           how to invoke Matlab (or Octave).
%           You may want to update that to add the full path of the command.
%           The defaut for this field can be set using the variable
%           GB_PSOM_COMMAND_MATLAB/OCTAVE in the file PSOM_GB_VARS.
%
%       RESTART
%           (cell of strings, default {}) any job whose name contains one 
%           of the strings in RESTART will be restarted, along with all of 
%           its children, and some of his parents whenever needed. See the
%           note 3 for more details.
%
%       FLAG_VERBOSE
%           (boolean, default true) if the flag is true, then the function 
%           prints some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% FILE_PIPELINE
%       (string) the file name of the .MAT file recapitulating all the
%       infos on the pipeline
%
% _________________________________________________________________________
% SEE ALSO:
%
% PSOM_PIPELINE_PROCESS, PSOM_PIPELINE_VISU, PSOM_DEMO_PIPELINE,
% PSOM_RUN_PIPELINE
%
% _________________________________________________________________________
% COMMENTS:
%
% The following notes describe the stages performed by PSOM_PIPELINE_INIT 
% in a chronological order.
%
% * STAGE 1:
%
%   The directory PATH_LOGS is created if necessary. A description of the
%   pipeline, its dependencies and the matlab environment are saved in the 
%   following file : 
%
%   <PATH_LOGS>/PIPE.mat
%       A .MAT file with the following variables:
%
%       OPT
%           The options used to initialize the pipeline
%
%       HISTORY
%           A string recapituling when and who created the pipeline, (and
%           on which machine).
%
%       DEPS, LIST_JOBS, FILES_IN, FILES_OUT, GRAPH_DEPS
%           See PSOM_BUILD_DEPENDENCIES for more info.
%
%       PATH_WORK
%           The matlab/octave search path
%
%   The dependency graph of the pipeline is defined as follows: job A 
%   depends on  job B if at least one of the input files of job A belongs 
%   to the list of output files of job B. See PSOM_BUILD_DEPENDENCIES and
%   PSOM_VISU_DEPENDENCIES for details.
%
%   Some viability checks are performed on the pipeline :
%
%       1. Check that the dependency graph of the pipeline is a directed 
%       acyclic graph, i.e. if job A depends on job B, job B cannot depend 
%       (even indirectly) on job A. 
%
%       2. Check that an output file is not created twice. Overwritting on 
%       files is regarded as a bug in a pipeline (forgetting to edit a 
%       copy-paste is a common mistake that leads to overwritting).
%
% * STAGE 2: 
%   
%   Some individual descriptions of the jobs are saved in the following 
%   file : 
%
%   <PATH_LOGS>/PIPE_jobs.mat
%       A .MAT file with the following variables:
%
%       <JOB_NAME>
%           One variable per job. It is identical to PIPELINE.<JOB_NAME>.
%
%   At this stage, some 'restart' flags are also generated : 
%
%       1. If a job was already processed during a previous execution of the 
%       pipeline, but anything changed in the job description (the 
%       command line, the options or the names of inputs/outputs), then the 
%       job will be marked as 'restart'. This operation is done by 
%       comparing the content of the variable <JOB_NAME> in PIPE_jobs.mat 
%       with the field PIPELINE.<JOB_NAME>.
%
%       2. All jobs whose name contains at least one of the strings listed 
%       in OPT.RESTART will be marked as 'restart'. 
%
%       3. All jobs that depend even indirectly on a job marked as 
%       'restart' (in the sense of the dependency graph) are themselves 
%       marked as 'restart'.
%
%       4. If a job is marked as 'restart' and is using input files that do
%       not exist but can be generated by another job, this other job is
%       also marked as 'restart'. This behavior is implemented recursively.
%
% * STAGE 3:
%
%   The logs and status of all the jobs are initialized and saved in the
%   two following files : 
%
%   <PATH_LOGS>/PIPE_status.mat
%       A .mat file with the following variable : 
%
%       JOB_STATUS
%           A structure. Each field corresponds to one job name and is a
%           string describing the current status of the job (upon
%           initialization, it is 'none', meaning that nothing has been
%           done with the job yet). See PSOM_JOB_STATUS and the following
%           notes for other status.
%
%   <PATH_LOGS>/PIPE_logs.mat
%       A .mat file with the following variable : 
%       
%       <JOB_NAME>
%           (string) the log of the job.
%
%   The following strategy is implemented to initialize the logs and job
%   status :
%
%       1. If a job is marked as 'none' but a log file and a 'finished' tag 
%       files can be found, then the job is marked as 'finished' and the 
%       log is saved in the log structure. (That behavior is usefull when 
%       the pipeline manager has crashed but some jobs completed after the 
%       crash in batch or qsub modes). 
%
%       2. Unless the job already has a 'finished' status and is not marked 
%       as 'restart', its status is set to 'none' and the log file is 
%       re-initialized as blank.
%
%       3. If a job was marked as 'finished' and is not marked as 
%       'restart', its status is left as 'finished' and the log file is 
%       also left "as is". Note that even if the outputs do not exist 
%       (because they have been deleted since the pipeline was last 
%       executed) the job will not be restarted. The easiest way to restart 
%       a pipeline if the outputs have been deleted by mistake would be to 
%       delete the log folder and restart the whole pipeline from scratch. 
%       It would also be possible to force the pipeline to restart from a 
%       given stage using OPT.RESTART.
%
%       3. If a job has a 'none' status, the system checks if all the 
%       inputs exist, apart from the files that will be generated by other 
%       jobs. If some files are missing, this is specified in the log and 
%       the job is marked as 'failed'. Note that if any job has failed 
%       this way, the pipeline initialization will pause to let the user 
%       the time to cancel the execution of the pipeline.
%
% * STAGE 4:
%
%   Every 'none' job goes through the following procedure :
%
%       1. The folders for outputs are created. 
%
%       2. Existing files with names similar to the outputs are deleted. 
%
%   Finally, existing tag/log/exit/qsub files in the logs folder are 
%   deleted, as well as the 'tmp' subfolder, if it exists.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : pipeline

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%%%%%%%%%%%%%%%%%%%%%
%% Checking inputs %%
%%%%%%%%%%%%%%%%%%%%%

psom_gb_vars

%% Syntax
if ~exist('pipeline','var')||~exist('opt','var')
    error('syntax: FILE_PIPELINE = PSOM_PIPELINE_INIT(PIPELINE,OPT).\n Type ''help psom_pipeline_init'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'restart','path_logs','command_matlab','flag_verbose'};
gb_list_defaults = {{},NaN,'',true};
psom_set_defaults
name_pipeline = 'PIPE';

if isempty(opt.command_matlab)
    if strcmp(gb_psom_language,'matlab')
        opt.command_matlab = gb_psom_command_matlab;
    else
        opt.command_matlab = gb_psom_command_octave;
    end
end

%% Misc variables
hat_qsub_o = sprintf('\n\n*****************\nOUTPUT QSUB\n*****************\n');
hat_qsub_e = sprintf('\n\n*****************\nERROR QSUB\n*****************\n');

%% Print a small banner for the initialization
msg_line1 = sprintf('The pipeline description is now being prepared for execution.');
msg_line2 = sprintf('The following folder will be used to store logs and status :');
msg_line3 = sprintf('%s',path_logs);
size_msg = max([size(msg_line1,2),size(msg_line2,2),size(msg_line3,2)]);
msg = sprintf('%s\n%s\n%s',msg_line1,msg_line2,msg_line3);
stars = repmat('*',[1 size_msg]);
fprintf('\n%s\n%s\n%s\n',stars,msg,stars);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stage 1: save the description of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Saving a description of the pipeline ...\n');
end

%% Generate file names 

file_pipeline = cat(2,path_logs,filesep,name_pipeline,'.mat');
file_jobs = cat(2,path_logs,filesep,name_pipeline,'_jobs.mat');
file_logs = cat(2,path_logs,filesep,name_pipeline,'_logs.mat');
file_status = cat(2,path_logs,filesep,name_pipeline,'_status.mat');
list_jobs = fieldnames(pipeline);
nb_jobs = length(list_jobs);

%% Test for the existence of an old pipeline 

flag_old_pipeline = exist(file_pipeline,'file');

%% Generate dependencies

if flag_verbose
    fprintf('    Generating dependencies ...\n');
end

[deps,list_jobs,files_in,files_out,graph_deps] = psom_build_dependencies(pipeline);

%% Check if some outputs were not generated twice
if flag_verbose
    fprintf('    Checking if some outputs were not generated twice ...\n');
end

[flag_ok,list_files_failed,list_jobs_failed] = psom_is_files_out_ok(files_out);

if ~flag_ok    
    for num_f = 1:length(list_files_failed)
        if num_f == 1
            str_files = list_files_failed{num_f};
        else
            str_files = [str_files ' ; '  list_files_failed{num_f}];
        end
    end
    
    for num_j = 1:length(list_jobs_failed)
        if num_j == 1
            str_jobs = list_jobs_failed{num_j};
        else
            str_jobs = [str_jobs ' ; ' list_jobs_failed{num_j}];
        end
    end

    error('The following output files are generated multiple times : %s.\nThe following jobs are responsible for that : %s',str_files,str_jobs);
end

%% Check for cycles

if flag_verbose
    fprintf('    Checking if the graph of dependencies is acyclic ...\n');
end

[flag_dag,list_vert_cycle] = psom_is_dag(graph_deps);

if ~flag_dag
    
    for num_f = 1:length(list_vert_cycle)
        if num_f == 1
            str_files = list_jobs{list_vert_cycle(num_f)};
        else
            str_files = [str_files ' ; '  list_jobs{list_vert_cycle(num_f)}];
        end
    end
    error('There are cycles in the dependency graph of the pipeline. The following jobs are involved in at least one cycle : %s',str_files);
end

%% Create logs folder

if ~exist(path_logs,'dir')
    if flag_verbose
        fprintf('    Creating the logs folder ...\n');
    end

    [succ,messg,messgid] = psom_mkdir(path_logs);

    if succ == 0
        warning(messgid,messg);
    end
end

%% Save the dependencies of the pipeline

if flag_verbose
    fprintf('    Saving the pipeline structure in %s...\n',file_pipeline);
end

if flag_old_pipeline
    load(file_pipeline,'history');
    history = char(history,[datestr(now) ' ' gb_psom_user ' on a ' gb_psom_OS ' system used PSOM v' gb_psom_version '>>>> The pipeline was restarted\n']);
else
    history = [datestr(now) ' ' gb_psom_user ' on a ' gb_psom_OS ' system used PSOM v' gb_psom_version '>>>> Created a pipeline !\n'];
end

path_work = path;
save(file_pipeline,'history','deps','graph_deps','list_jobs','files_in','files_out','path_work')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stage 2: initialize the jobs' description %%
%%          and set up the restart flags     %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\nCreating the individual ''jobs'' file %s ...\n',file_jobs);
end

flag_restart = false([1 nb_jobs]);

if flag_old_pipeline

    pipeline_old = load(file_jobs);

else

    pipeline_old = struct([]);

end

%% Loop over the jobs and save the individual descriptions. Use that
%% opportunity to set up the 'restart' flags

for num_j = 1:nb_jobs

    %% If an old pipeline exists, check if the job has been modified
    name_job = list_jobs{num_j};
    
    if isfield(pipeline_old,name_job)
        flag_same = psom_cmp_var(pipeline_old.(name_job),pipeline.(name_job));
        flag_restart(num_j) = flag_restart(num_j)||~flag_same;
    else
        flag_restart(num_j) = true;
        flag_same = false;
    end

     % If the job has been modified or did not exist, save a description
     if ~flag_same
         pipeline_update.(name_job) = pipeline.(name_job);
     end

    if flag_old_pipeline
        %% Check if the user did not force a restart on that job
        flag_restart(num_j) = flag_restart(num_j) || psom_find_str_cell(name_job,opt.restart);

        %% If the job is restarted, also restart all of its children
        if flag_restart(num_j)
            mask_child = sub_find_children(num_j,graph_deps);
            flag_restart(mask_child) = true;
        end
    end
end

% Update the description of the jobs that need to be updated
if exist('pipeline_update','var')
    if exist(file_jobs,'file')
        save(file_jobs,'-append','-struct','pipeline_update');
    else
        save(file_jobs,'-struct','pipeline_update');
    end
end


%% Restart the parents of 'restart' jobs that produce files that are
%% used by 'restart' jobs
if flag_old_pipeline
    flag_restart = flag_restart | sub_restart_parents(flag_restart,pipeline,list_jobs,deps,graph_deps);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stage 3: Creating logs and status %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\nCreating the ''logs'' and ''status'' files ...\n');
end

%% If an old pipeline exists, update the status of the jobs based on the
%% tag files that can be found

if flag_verbose
    fprintf('    Checking for left-overs tag files...\n');
end

if flag_old_pipeline

    if exist(file_status,'file')

        all_status_old = load(file_status);
        if exist(file_logs,'file')
            all_logs_old = load(file_logs);
        else
            all_logs_old = struct([]);
        end
        
        job_status = cell(size(list_jobs));
        
        for num_j = 1:length(list_jobs)
            name_job = list_jobs{num_j};
            if isfield(all_status_old,name_job)
                job_status{num_j} = all_status_old.(name_job);
            else
                job_status{num_j} = 'none';
            end
        end

        %% Update the job status using the tags that can be found in the log
        %% folder
        mask_inq = ismember(job_status,{'submitted','running'});
        list_num_inq = find(mask_inq);
        list_num_inq = list_num_inq(:)';
        list_jobs_inq = list_jobs(mask_inq);
        curr_status = psom_job_status(path_logs,list_jobs_inq,'session');

        %% Remove the dependencies on finished jobs
        mask_finished = ismember(curr_status,'finished');
        list_num_finished = list_num_inq(mask_finished);
        list_num_finished = list_num_finished(:)';

        for num_j = list_num_finished

            name_job = list_jobs{num_j};
            text_log = sub_read_txt([path_logs filesep name_job '.log']);
            text_qsub_o = sub_read_txt([path_logs filesep name_job '.oqsub']);
            text_qsub_e = sub_read_txt([path_logs filesep name_job '.eqsub']);

            if ~isempty(text_qsub_o)&isempty(text_qsub_e)
                text_log = [text_log hat_qsub_o text_qsub_o hat_qsub_e text_qsub_e];
            end
            
            all_logs.(name_job) = text_log;            
            job_status{num_j} = 'finished';
        end

        job_status_old = job_status;
    else
        job_status_old = repmat({'none'},[nb_jobs 1]);
    end

end

%% Initialize the status :
%% Everything goes to 'none', except jobs that have a 'finished' status and
%% no restart tag

if flag_verbose
    fprintf('    Initializing the new status (keeping finished jobs "as is")...\n');
end

job_status = repmat({'none'},[nb_jobs 1]);

if flag_old_pipeline        
    
    flag_finished = ismember(job_status_old,'finished');
    flag_finished = flag_finished(:)';
    flag_finished = flag_finished & ~flag_restart;
    
    job_status(flag_finished) = repmat({'finished'},[sum(flag_finished) 1]);
    
else
    
    flag_finished = false([nb_jobs 1]);
    
end

%% Check if all the files necessary to complete each job of the pipeline 
%% can be found

if flag_verbose
    fprintf('    Checking if all the files necessary to complete the pipeline can be found ...\n');
end

flag_ready = true;
mask_unfinished = ~flag_finished;
list_num_unfinished = find(mask_unfinished);
list_num_unfinished = list_num_unfinished(:)';

for num_j = list_num_unfinished

    name_job = list_jobs{num_j};
    list_files_needed = files_in.(name_job);
    list_files_tobe = psom_files2cell(deps.(name_job));
    list_files_necessary = list_files_needed(~ismember(list_files_needed,list_files_tobe));

    flag_job_OK = true;
    
    for num_f = 1:length(list_files_necessary)
        
        if ~exist(list_files_necessary{num_f},'file')&~isempty(list_files_necessary{num_f})&~strcmp(list_files_necessary{num_f},'gb_niak_omitted')

            if flag_job_OK
                msg_files = sprintf('        Job %s : the file %s is unfortunately missing.\n',name_job,list_files_necessary{num_f});
            else
                msg_files = char(msg_files,sprintf('        Job %s : the file %s is unfortunately missing.\n',name_job,list_files_necessary{num_f}));
            end
            flag_ready = false;
            flag_job_OK = false;

        end
    end
    
    if ~flag_job_OK
        job_status{num_j} = 'failed';
        all_logs.(name_job) = sprintf('%s\n\n%s',datestr(now),msg_files');
        fprintf('%s',msg_files');        
    end
    
end


%% Save the jobs' status

if flag_verbose
    fprintf('    Creating the ''status'' file %s ...\n',file_status);
end

flag_failed = ismember(job_status,'failed');
for num_j = 1:nb_jobs
    name_job = list_jobs{num_j};
    all_status.(name_job) = job_status{num_j};
end

if exist(file_status,'file')
    save(file_status,'-append','-struct','all_status');
else
    save(file_status,'-struct','all_status');
end

%% Initialize the log files

if flag_verbose
    fprintf('    Creating the ''logs'' file %s ...\n',file_logs);
end

for num_j = 1:nb_jobs
    
    name_job = list_jobs{num_j};
    
    if flag_finished(num_j)||flag_failed(num_j)
        
        if ~isfield('all_logs',name_job)
            if exist('all_logs_old','var')&&isfield(all_logs_old,name_job)
                all_logs.(name_job) = all_logs_old.(name_job);
            else
                all_logs.(name_job) = '';
            end
        end
        
    else
        
        all_logs.(name_job) = '';
        
    end
end

if exist(file_logs,'file')
    save(file_logs,'-append','-struct','all_logs');
else
    save(file_logs,'-struct','all_logs');
end

if ~flag_ready
    if flag_verbose
        fprintf('\nSome jobs were marked as failed because some inputs were missing.\nPress CTRL-C now if you do not wish to run the pipeline ...\n');
        pause
    else
        warning('\nSome inputs of jobs of the pipeline were missing. Those jobs were marked as ''failed'', see the logs for more details.');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stage 4: Generating output folders and cleaning old files %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Creating log folders and removing old outputs

if flag_verbose
    fprintf('\nCreating log folders and removing old outputs ...\n')
end

for num_j = 1:length(list_jobs)

    job_name = list_jobs{num_j};
    list_files = unique(files_out.(job_name));

    for num_f = 1:length(list_files)

        path_f = fileparts(list_files{num_f});

        if ~exist(path_f,'dir')

            [succ,messg,messgid] = psom_mkdir(path_f);

            if succ == 0
                warning(messgid,messg);
            end

        end
        
        if exist(list_files{num_f}) & ~flag_finished(num_j)
            
            delete(list_files{num_f});
            
        end

    end % for files

end % for jobs


%% Clean up the log folders from old tag and log files

if flag_verbose
    fprintf('\nCleaning up old tags and logs from the logs folders ...\n')
end

delete([path_logs filesep '*.running']);
delete([path_logs filesep '*.failed']);
delete([path_logs filesep '*.finished']);
delete([path_logs filesep '*.exit']);
delete([path_logs filesep '*.log']);
delete([path_logs filesep '*.oqsub']);
delete([path_logs filesep '*.eqsub']);

if exist([path_logs 'tmp'],'dir')
    rmdir([path_logs 'tmp'],'s');
end

%% Done !
if flag_verbose
    fprintf('\nThe pipeline has been successfully initialized !\n')
end

%%%%%%%%%%%%%%%%%%
%% Subfunctions %%
%%%%%%%%%%%%%%%%%%

%% Read a text file
function str_txt = sub_read_txt(file_name)

if exist(file_name,'file')
    hf = fopen(file_name,'r');
    str_txt = fread(hf,Inf,'uint8=>char')';
    fclose(hf);
else
    str_txt = '';
end

%% Recursively find all the jobs that depend on one job
function mask_child = sub_find_children(num_j,graph_deps)
% GRAPH_DEPS(J,K) == 1 if and only if JOB K depends on JOB J. GRAPH_DEPS =
% 0 otherwise. This (ugly but reasonably fast) recursive code will work
% only if the directed graph defined by GRAPH_DEPS is acyclic.

mask_child = graph_deps(num_j,:)>0;

list_num_child = find(mask_child);

if ~isempty(list_num_child)
    for num_c = list_num_child        
        mask_child = mask_child | sub_find_children(num_c,graph_deps);
    end
end

%% Recursively test if the inputs of some jobs are missing, and set restart
%% flags on the jobs that can produce those inputs.
function flag_parent = sub_restart_parents(flag_restart,pipeline,list_jobs,deps,graph_deps)

list_restart = find(flag_restart);

flag_parent = false(size(flag_restart));

for num_j = list_restart
    
    name_job = list_jobs{num_j};
    list_parent = fieldnames(deps.(name_job));
    list_num_parent = find(graph_deps(:,num_j));
    
    for num_l = list_num_parent'
        
        name_job2 = list_jobs{num_l};
        flag_OK = true;
        
        for num_f = 1:length(deps.(name_job).(name_job2))
            flag_OK = flag_OK & exist(deps.(name_job).(name_job2){num_f});
        end
        
        if ~flag_OK
            flag_parent(num_l) = true;
        end
    end
end

if max(flag_parent)>0
    flag_parent = flag_parent | sub_restart_parents(flag_parent,pipeline,list_jobs,deps,graph_deps);
end