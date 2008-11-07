function [] = psom_pipeline_manage(file_pipeline,opt)
%
% _________________________________________________________________________
% SUMMARY OF PSOM_PIPELINE_MANAGE
%
% Run or reset a pipeline that has previously been initialized.
%
% SYNTAX:
% [] = PSOM_PIPELINE_MANAGE(FILE_PIPELINE,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_PIPELINE
%       (string) The file name of a .MAT file generated using
%       PSOM_PIPELINE_INIT.
%
% OPT
%       (structure) with the following fields :
%
%       MODE
%           (string, default 'session') how to execute the jobs :
%
%           'session'
%               the pipeline is executed within the current session. The
%               current path will be used instead of the one that was
%               active when initializing the pipeline. There will be no log
%               files for jobs.
%
%           'batch'
%               Start the pipeline manager and each job in independent
%               matlab sessions. Note that more than one session can be
%               started at the same time to take advantage of
%               muli-processors machine. Moreover, the pipeline will run in
%               the background, you can continue to work, close matlab or
%               even unlog from your machine on a linux system without
%               interrupting it. The matlab path will be the same as the
%               one that was active when the pipeline was initialized. Log
%               files will be created for all jobs.
%
%           'qsub'
%               Use the qsub system (sge or pbs) to process the jobs. The
%               pipeline runs in the background.
%
%       FLAG_BATCH
%           (boolean, default 1) how to execute the pipeline :
%
%           If FLAG_BATCH == 0, the pipeline is executed within the session.
%               Interrupting the pipeline with CTRL-C will result in
%               interrupting the pipeline (you can always do a 'restart'
%               latter). There will be no log file for the pipeline itself
%               in this mode, but rather a verbose in the command window.
%
%           If FLAG_BATCH == 1, the pipeline manager is started as a
%               separate process in its own Matlab or Octave session using
%               the 'at' system command. The pipeline will thus run in the
%               background, you can continue to work, close matlab or
%               even unlog from your machine on a linux system without
%               interrupting it. A log file of the pipeline manager
%               activity is created. You can access it using the action
%               'monitor' of PSOM_PIPELINE_VISU.
%
%       MAX_QUEUED
%           (integer, default 1 'batch' modes, Inf in 'session',
%           'sge' and 'pbs' modes)
%           The maximum number of jobs that can be processed
%           simultaneously. Some qsub systems actually put restrictions
%           on that. Contact your local system administrator for more info.
%
%       QSUB_OPTIONS
%           (string)
%           This field can be used to pass any argument when submitting a
%           job with qsub. For example, '-q all.q@yeatman,all.q@zeus' will
%           force qsub to only use the yeatman and zeus workstations in the
%           all.q queue. It can also be used to put restrictions on the
%           minimum avalaible memory, etc.
%
% _________________________________________________________________________
% OUTPUTS:
%
% _________________________________________________________________________
% SEE ALSO:
%
% PSOM_PIPELINE_INIT, PSOM_PIPELINE_VISU, PSOM_DEMO_PIPELINE,
% PSOM_RUN_PIPELINE.
%
% _________________________________________________________________________
% COMMENTS:
%
% Existing 'running' or 'failed' tags will be removed. Make sure the
% pipeline is not already running if the background if you do that. That
% behavior is useful to restart a pipeline that has somehow crashed.
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

psom_gb_vars

%% SYNTAX
if ~exist('file_pipeline','opt')
    error('SYNTAX: [] = PSOM_PIPELINE_MANAGE(FILE_PIPELINE,OPT). Type ''help psom_pipeline_manage'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'mode','max_queued','qsub_options'};
gb_list_defaults = {'session',0,''};
psom_set_defaults

if max_queued == 0

    switch action

        case {'batch'}
            opt.max_queued = 1;
            max_queued = 1;
        case {'session','sge','pbs'}
            opt.max_queued = Inf;
            max_queued = Inf;

    end % switch action

end % default of max_queued

%% TAG TODO !!
%% Add here a block of code to run the pipeline in batch mode ...

try

    %% Hard-coded parameters
    time_between_checks = 10;
    nb_checks_per_point = 6;

    %% Generating file names

    [path_logs,name_pipeline,ext_pl] = fileparts(file_pipeline);

    file_pipe_running = cat(2,path_logs,filesep,name_pipeline,'.running');
    file_pipe_log = cat(2,path_logs,filesep,name_pipeline,'.log');
    file_pipe_path = cat(2,path_logs,filesep,name_pipeline,'.path_def.mat');

    %% Check for the status of the pipeline
    if ~exist(file_pipeline,'file') % Does the pipeline exist ?
        error('Could not find the pipeline file %s. You need to initialize the pipeline using PSOM_PIPELINE_INIT !',file_pipeline);
    end

    if exist(file_pipe_running,'file') % Is the pipeline running ?
        fprintf('psom:pipeline: A running tag has been found on the pipeline ! This means the pipeline was either running or crashed.\n I will assume it crashed and restart the pipeline.\n')
        delete(file_running);
    end

    load(file_pipeline);

    %% Check if all the files necessary to complete the pipeline can be found
    flag_ready = true;

    for num_j = 1:length(list_jobs)

        name_job = list_jobs{num_j};
        list_files_needed = files_in.(name_job);
        list_files_tobe = niak_files2cell(deps.(name_job));
        list_files_necessary = list_files_needed(~ismember(list_files_needed,list_files_tobe));

        for num_f = 1:length(list_files_necessary)
            if ~exist(list_files_necessary{num_f})
                fprintf('The file %s is necessary to run the pipeline, but is unfortunately missing.\n',list_files_necessary{num_f})
                flag_ready = false
            end
        end
    end

    if ~flag_ready
        error('Some files are missing, sorry dude I must quit ...')
    end

    %% Clean up left-over 'running' tags
    curr_status = psom_job_status(path_logs,list_jobs);
    mask_running = ismember(curr_status,'running'); % running jobs

    if max(mask_running)>0
        fprintf('Some running tags were found on some jobs, even though the pipeline itseld had no running tags. That''s not supposed to happen, I reseted all tags to ''unfinished''\n');
        list_jobs_running = list_jobs(mask_running);
        for num_f = 1:length(list_jobs_running)
            file_running = [path_logs filesep list_jobs_running{num_f} '.running'];
            delete(file_running)
        end
    end

    %% Clean up left-over 'failed' tags
    mask_failed = ismember(curr_status,{'failed'}); % failed jobs
    if max(mask_failed)>0
        fprintf('Some failed tags were found on some jobs. I will try to restart them.\n');
        list_jobs_failed = list_jobs(mask_failed);
        for num_f = 1:length(list_jobs_failed)
            file_running = [path_logs filesep list_jobs_running{num_f} '.failed'];
            delete(file_failed)
        end
    end

    %% Clean up log files for unfinished jobs
    mask_unfinished = ~ismember(curr_status,'finished'); % non finished jobs
    if max(mask_unfinished)>0
        list_jobs_unfinished = list_jobs(mask_unfinished);
        for num_f = 1:length(list_jobs_unfinished)
            file_log = [path_logs filesep list_jobs_unfinished{num_f} '.log'];
            if exist(file_log,'file')
                delete(file_log)
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%
    %% Run the pipeline %%
    %%%%%%%%%%%%%%%%%%%%%%

    fprintf('\nStarting the pipeline ... \n');

    str_now = datestr(clock);
    save(file_pipe_running,str_now); %% Put a running tag on the pipeline
    path_tmp = psom_path_tmp(['_',name_pipeline]); % Create a temporary folder for shell scripts

    %% Initialize job status
    nb_queued = 0;
    curr_status = psom_job_status(path_logs,list_jobs);
    mask_running = false(size(list_jobs)); % running jobs (at this stage, none)
    mask_todo = ~ismember(curr_status,{'finished'}); % done jobs (there is no failed jobs at this stage)
    mask_todo = mask_todo(:);

    list_jobs_finished = list_jobs(~mask_todo); % Finished jobs
    for num_f = 1:length(list_jobs_finished) % Remove the dependencies on finished jobs
        name_job = list_jobs_finished{num_f};
        for num_f2 = 1:length(list_jobs)
            name_job2 = list_jobs{num_f2};
            if isfield(deps.(name_job2),name_job)
                deps.(name_job2) = rmfield(deps.(name_job2),'name_job');
            end
        end
    end

    mask_deps = false(size(list_jobs)); % jobs that have a dependence on a yet-not-completed job
    for num_j = 1:length(list_jobs)
        name_job = list_jobs{num_j};
        mask_deps(num_j) = ~isempty(deps.(name_job));
    end


    %% Loop until all jobs are done or went bad...
    while max(mask_todo)>0

        % Update the status of running jobs
        new_status_running_jobs = psom_job_status(path_logs,list_jobs(mask_running));
        mask_done(mask_running) = ismember(new_status_running_jobs,{'finished','failed'});

        % Get the list of jobs that failed
        list_jobs_failed = list_jobs(mask_running);
        list_jobs_failed = list_jobs_failed(ismember(new_status_running_jobs,'failed'));
        nb_queued = nb_queued - length(list_jobs_failed);

        % Remove the children of failed jobs from the to-do list
        for num_f = 1:length(list_jobs_failed)
            name_job = list_jobs_failed{num_f};
            list_jobs_child = sub_find_children(list_jobs,name_job,deps);
            mask_child = ismember(list_jobs,list_jobs_children);
            mask_todo(mask_child) = false;
        end

        % Get the list of jobs that were completed
        list_jobs_finished = list_jobs(mask_running);
        list_jobs_finished = list_jobs_finished(ismember(new_status_running_jobs,'finished'));
        nb_queued = nb_queued - length(list_jobs_finished);

        % Remove the dependencies on finished jobs
        for num_f = 1:length(list_jobs_finished)
            name_job = list_jobs_finished{num_f};
            for num_f2 = 1:length(list_jobs)
                name_job2 = list_jobs{num_f2};
                if isfield(deps.(name_job2),name_job)
                    deps.(name_job2) = rmfield(deps.(name_job2),'name_job');
                end
            end
        end

        % Update the dependency mask
        mask_deps = false(size(list_jobs));
        for num_j = find(mask_todo)'
            name_job = list_jobs{num_j};
            mask_deps(num_j) = ~isempty(deps.(name_job));
        end

        % Time to submit jobs !!

        while (nb_queued <= max_queued)&max(mask_todo&~mask_deps)>0

            %% Pick up a job to run
            num_job = find(mask_todo&~mask_deps,1);
            name_job = list_jobs{num_job};
            file_job = [path_logs filesep name_job '.mat'];
            file_log = [path_logs filesep name_job '.log'];
            mask_todo(num_job) = false;
            nb_queued = nb_queued + 1;

            %% Create a temporary shell scripts for 'batch' or 'qsub' modes
            if ~strcmp(mode,'session')

                switch gb_psom_language

                    case 'matlab'

                        instr_job = sprintf(hs,'%s -r ''cd %s, load %s, path(path_work), psom_run_job(%s),''> file_log &\n',gb_psom_command_matlab,path_logs,file_pipe_path,file_job);

                    case 'octave'

                        instr_job = sprintf(hs,'%s --eval ''cd %s, load %s, path(path_work), psom_run_job(%s),''> file_log &\n',gb_psom_command_matlab,path_logs,file_pipe_path,file_job);

                end

            end

            file_shell = [path_tmp filesep name_job '.sh'];
            hf = fopen(file_shell,'w');
            fprintf(hf,'%s',instr_job);
            fclose(hf)

            %% Time to run the job
            switch mode

                case 'session'

                    psom_run_job(file_job);

                case 'batch'

                    instr_batch = ['at ' file_shell ' -now'];
                    system(instr_batch);

                case 'qsub'

                    instr_qsub = ['qsub -N ' name_job ' ' opt.opt_qsub ' ' file_shell];
                    system(instr_qsub);

            end % switch mode


        end % submit jobs
    end

catch

    if exist('path_tmp','var')
        rmdir(path_tmp,'s'); % Clean the temporary folder
    end

    if exist('file_pipe_running','var')
        delete(file_pipe_running); % remove the 'running' tag
    end

    msg = lasterror;
    error(msg)
end

if exist('path_tmp','var')
    rmdir(path_tmp,'s'); % Clean the temporary folder
end

if exist('file_pipe_running','var')
    delete(file_pipe_running); % remove the 'running' tag
end
