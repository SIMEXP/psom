function [] = psom_pipeline_process(file_pipeline,opt)
%
% _________________________________________________________________________
% SUMMARY OF PSOM_PIPELINE_PROCESS
%
% Process a pipeline that has previously been initialized.
%
% SYNTAX:
% [] = PSOM_PIPELINE_PROCESS(FILE_PIPELINE,OPT)
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
%               current matlab search path will be used instead of the one
%               that was active when the pipeline was initialized. In that
%               mode, the log files of individual jobs are appendend to the
%               log file of the pipeline.
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
%       MODE_PIPELINE_MANAGER
%           (string, default same as OPT.MODE) same as OPT.MODE, but
%           applies to the pipeline manager itself.
%
%       MAX_QUEUED
%           (integer, default 1 'batch' modes, Inf in 'session' and 'qsub'
%           modes)
%           The maximum number of jobs that can be processed
%           simultaneously. Some qsub systems actually put restrictions
%           on that. Contact your local system administrator for more info.
%
%       SHELL_OPTIONS
%           (string, default GB_PSOM_SHELL_OPTIONS defined in PSOM_GB_VARS)
%           some commands that will be added at the begining of the shell
%           script submitted to batch or qsub. This can be used to set
%           important variables, or source an initialization script.
%
%       QSUB_OPTIONS
%           (string, GB_PSOM_QSUB_OPTIONS defined in PSOM_GB_VARS)
%           This field can be used to pass any argument when submitting a
%           job with qsub. For example, '-q all.q@yeatman,all.q@zeus' will
%           force qsub to only use the yeatman and zeus workstations in the
%           all.q queue. It can also be used to put restrictions on the
%           minimum avalaible memory, etc.
%
%       COMMAND_MATLAB
%           (string, default GB_PSOM_COMMAND_MATLAB or
%           GB_PSOM_COMMAND_OCTAVE depending on the current environment)
%           how to invoke matlab (or OCTAVE).
%           You may want to update that to add the full path of the command.
%           The defaut for this field can be set using the variable
%           GB_PSOM_COMMAND_MATLAB/OCTAVE in the file PSOM_GB_VARS.
%
%       TIME_BETWEEN_CHECKS
%           (real value, default 0 in 'session' mode, 10 otherwise)
%           The time (in seconds) where the pipeline processing remains
%           inactive to wait for jobs to complete before attempting to
%           submit new jobs.
%
%       TIME_COOL_DOWN
%           (real value, default 2 in 'qsub' mode, 0 otherwise)
%           A small pause time between evaluation of status and flushing of
%           tags. This is to let qsub the time to write the output/error
%           log files.
%
%       NB_CHECKS_PER_POINT
%           (integer,defautlt 6) After NB_CHECK_PER_POINT successive checks
%           where the pipeline processor did not find anything to do, it
%           will issue a '.' verbose to show it is not dead.
%
%       FLAG_DEBUG
%           (boolean, default false) if FLAG_DEBUG is true, the program
%           prints additional information for debugging purposes.
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
% Empty file names, or file names equal to 'gb_niak_omitted' are ignored
% when building the dependency graph between jobs.
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting up default values for inputs %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SYNTAX
if ~exist('file_pipeline','var')
    error('SYNTAX: [] = PSOM_PIPELINE_PROCESS(FILE_PIPELINE,OPT). Type ''help psom_pipeline_manage'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'flag_debug','shell_options','command_matlab','mode','mode_pipeline_manager','max_queued','qsub_options','time_between_checks','nb_checks_per_point','time_cool_down'};
gb_list_defaults = {false,'','','session','',0,'',[],[],[]};
psom_set_defaults

if isempty(opt.mode_pipeline_manager)
    opt.mode_pipeline_manager = opt.mode;
end

if isempty(opt.command_matlab)
    if strcmp(gb_psom_language,'matlab')
        opt.command_matlab = gb_psom_command_matlab;
    else
        opt.command_matlab = gb_psom_command_octave;
    end
end

if isempty(opt.qsub_options)
    opt.qsub_options = gb_psom_qsub_options;
end

if isempty(opt.shell_options)
    opt.shell_options = gb_psom_shell_options;
end

if max_queued == 0
    switch opt.mode
        case {'batch'}
            opt.max_queued = 1;
            max_queued = 1;
        case {'session','qsub'}
            opt.max_queued = Inf;
            max_queued = Inf;
    end % switch action
end % default of max_queued

%% Test the the requested mode of execution of jobs exists
if ~ismember(opt.mode,{'session','batch','qsub'})
    error('%s is an unknown mode of pipeline execution. Sorry dude, I must quit ...',opt.mode);
end

switch opt.mode
    case 'session'
        if isempty(time_between_checks)
            opt.time_between_checks = 0;
            time_between_checks = 0;
        end
        if isempty(nb_checks_per_point)
            opt.nb_checks_per_point = Inf;
            nb_checks_per_point = Inf;
        end
        if isempty(time_cool_down)
            opt.time_cool_down = 0;
            time_cool_down = 0;
        end
    case 'batch'
        if isempty(time_between_checks)
            opt.time_between_checks = 10;
            time_between_checks = 10;
        end
        if isempty(nb_checks_per_point)
            opt.nb_checks_per_point = 6;
            nb_checks_per_point = 6;
        end
        if isempty(time_cool_down)
            opt.time_cool_down = 0;
            time_cool_down = 0;
        end
    case 'qsub'
        if isempty(time_between_checks)
            opt.time_between_checks = 10;
            time_between_checks = 10;
        end
        if isempty(nb_checks_per_point)
            opt.nb_checks_per_point = 6;
            nb_checks_per_point = 6;
        end
        if isempty(time_cool_down)
            opt.time_cool_down = 1;
            time_cool_down = 2;
        end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The pipeline processing starts now  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Generic messages
hat_qsub_o = sprintf('\n\n*****************\nOUTPUT QSUB\n*****************\n');
hat_qsub_e = sprintf('\n\n*****************\nERROR QSUB\n*****************\n');

%% Generating file names
[path_logs,name_pipeline,ext_pl] = fileparts(file_pipeline);
file_pipe_running = cat(2,path_logs,filesep,name_pipeline,'.lock');
file_pipe_log = cat(2,path_logs,filesep,name_pipeline,'_history.txt');
file_logs = cat(2,path_logs,filesep,name_pipeline,'_logs.mat');
file_logs_backup = cat(2,path_logs,filesep,name_pipeline,'_logs_backup.mat');
file_status = cat(2,path_logs,filesep,name_pipeline,'_status.mat');
file_status_backup = cat(2,path_logs,filesep,name_pipeline,'_status_backup.mat');
file_jobs = cat(2,path_logs,filesep,name_pipeline,'_jobs.mat');

%% Check for the existence of the pipeline
if ~exist(file_pipeline,'file') % Does the pipeline exist ?
    error('Could not find the pipeline file %s. You first need to initialize the pipeline using PSOM_PIPELINE_INIT !',file_pipeline);
end

%% Create a running tag on the pipeline
str_now = datestr(clock);
save(file_pipe_running,'str_now'); 

%% If specified, start the pipeline in the background
switch opt.mode_pipeline_manager

    case {'batch','qsub'}
        
        switch opt.mode_pipeline_manager
            case 'qsub'
                fprintf('I am sending the pipeline manager in the background using the ''qsub'' command.\n')
                switch gb_psom_language
                    case 'matlab'
                        instr_job = sprintf('%s -nosplash -nojvm -r "cd %s, load(''%s'',''path_work''), path(path_session), opt.time_cool_down = %1.3f, opt.nb_checks_per_point = %i; opt.time_between_checks = %1.3f; opt.command_matlab = ''%s''; opt.mode = ''%s''; opt.mode_pipeline_manager = ''session''; opt.max_queued = %i; opt.qsub_options = ''%s'', psom_pipeline_process(''%s'',opt),"\n',opt.command_matlab,path_logs,file_pipeline,opt.time_cool_down,opt.nb_checks_per_point,opt.time_between_checks,opt.command_matlab,opt.mode,opt.max_queued,opt.qsub_options,file_pipeline);
                    case 'octave'
                        instr_job = sprintf('%s --silent --eval "cd %s, load(''%s'',''path_work''), path(path_session), opt.time_cool_down = %1.3f, opt.nb_checks_per_point = %i; opt.time_between_checks = %1.3f; opt.command_matlab = ''%s''; opt.mode = ''%s''; opt.mode_pipeline_manager = ''session''; opt.max_queued = %i; opt.qsub_options = ''%s'', psom_pipeline_process(''%s'',opt),"\n',opt.command_matlab,path_logs,file_pipeline,opt.time_cool_down,opt.nb_checks_per_point,opt.time_between_checks,opt.command_matlab,opt.mode,opt.max_queued,opt.qsub_options,file_pipeline);
                end
            otherwise
                fprintf('I am sending the pipeline manager in the background using the ''at'' command.\n')
                switch gb_psom_language
                    case 'matlab'
                        instr_job = sprintf('%s -nosplash -nojvm -r "cd %s, load(''%s'',''path_session''), path(path_session), opt.time_cool_down = %1.3f, opt.nb_checks_per_point = %i; opt.time_between_checks = %1.3f; opt.command_matlab = ''%s''; opt.mode = ''%s''; opt.mode_pipeline_manager = ''session''; opt.max_queued = %i; opt.qsub_options = ''%s'', psom_pipeline_process(''%s'',opt),"\n',opt.command_matlab,path_logs,file_pipeline,opt.time_cool_down,opt.nb_checks_per_point,opt.time_between_checks,opt.command_matlab,opt.mode,opt.max_queued,opt.qsub_options,file_pipeline);
                    case 'octave'
                        instr_job = sprintf('%s --silent --eval "cd %s, load(''%s'',''path_session''), path(path_session), opt.time_cool_down = %1.3f, opt.nb_checks_per_point = %i; opt.time_between_checks = %1.3f; opt.command_matlab = ''%s''; opt.mode = ''%s''; opt.mode_pipeline_manager = ''session''; opt.max_queued = %i; opt.qsub_options = ''%s'', psom_pipeline_process(''%s'',opt),"\n',opt.command_matlab,path_logs,file_pipeline,opt.time_cool_down,opt.nb_checks_per_point,opt.time_between_checks,opt.command_matlab,opt.mode,opt.max_queued,opt.qsub_options,file_pipeline);
                end
        end

        

        if flag_debug
           fprintf('\n\nThe following shell script is used to run the pipeline manager in the background :\n%s\n\n',instr_job);
        end
        
        file_shell = psom_file_tmp('_proc_pipe.sh');
        hf = fopen(file_shell,'w');
        fprintf(hf,'%s',instr_job);
        fclose(hf);

        switch opt.mode_pipeline_manager
            
            case 'qsub'
                
                file_qsub_o = [path_logs filesep name_pipeline '.oqsub'];
                file_qsub_e = [path_logs filesep name_pipeline '.eqsub'];
                instr_batch = ['qsub -e ' file_qsub_e ' -o ' file_qsub_o ' -N ' name_pipeline(1:min(15,length(name_pipeline))) ' ' opt.qsub_options ' ' file_shell];
                
            otherwise
                
                switch gb_psom_OS
                    case 'windows'
                        instr_batch = ['soon delay 0 "' file_shell '"'];
                    otherwise
                        instr_batch = ['at -f ' file_shell ' now'];
                end
                
        end
        [fail,msg] = system(instr_batch);
        if fail~=0
            error('Something went bad with the at command. The error message was : %s',msg)
        end
        if flag_debug
            fprintf('\n\nThe call to at/qsub produced the following message :\n%s\n\n',msg);
        end

        delete(file_shell)
        return

end

% a try/catch block is used to clean temporary file if the user is
% interrupting the pipeline of if an error occurs
try    
    
    %% If the pipeline manager is executed in the session, open the log
    %% file   
    hfpl = fopen(file_pipe_log,'a');

    %% Print general info about the pipeline
    msg_line1 = sprintf('The pipeline %s is now being processed.',name_pipeline);    
    msg_line2 = sprintf('Started on %s',datestr(clock));
    msg_line3 = sprintf('user: %s, host: %s, system: %s',gb_psom_user,gb_psom_localhost,gb_psom_OS);
    size_msg = max([size(msg_line1,2),size(msg_line2,2),size(msg_line3,2)]);
    msg = sprintf('%s\n%s\n%s',msg_line1,msg_line2,msg_line3);
    stars = repmat('*',[1 size_msg]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);
    fprintf(hfpl,'\n%s\n%s\n%s\n',stars,msg,stars);

    %% Load the pipeline
    load(file_pipeline,'list_jobs','deps','graph_deps','files_in');

    %% Loading the current status of the pipeline
    all_status = load(file_status);
    for num_j = 1:length(list_jobs)
        name_job = list_jobs{num_j};
        if isfield(all_status,name_job)
            job_status{num_j} = all_status.(name_job);
        else
            job_status{num_j} = 'none';
        end
    end
	clear all_status
    list_num_jobs = 1:length(job_status);
            
    %% update dependencies
    mask_finished = ismember(job_status,'finished');       
    graph_deps(mask_finished,:) = 0;    
    mask_deps = max(graph_deps,[],1)>0;
    mask_deps = mask_deps(:);            

    %% Initialize the to-do list
    mask_todo = ismember(job_status,{'none'}); 
    mask_todo = mask_todo(:);
    mask_done = ~mask_todo; 
    
    mask_failed = ismember(job_status,{'failed'});
    list_num_failed = find(mask_failed);
    list_num_failed = list_num_failed(:)';
    for num_j = list_num_failed
        list_num_child = find(sub_find_children(num_j,graph_deps));
        mask_todo(list_num_child) = false; % Remove the children of the failed job from the to-do list
    end
    
    mask_running = false(size(mask_done));
    
    %% Initialize miscallenaous variables
    nb_queued = 0;
    nb_checks = 0;
    nb_points = 0;
    path_tmp = [path_logs filesep 'tmp']; % Create a temporary folder for shell scripts
    if exist(path_tmp,'dir')
        delete([path_tmp '*']);
    else
        mkdir(path_tmp);
    end

    %% The pipeline manager really starts here
    while (max(mask_todo)>0) || (max(mask_running)>0)

        flag_nothing_happened = true;

        %% Update the status of running jobs         
        list_num_running = find(mask_running);
        list_num_running = list_num_running(:)';
        list_jobs_running = list_jobs(list_num_running);
        new_status_running_jobs = psom_job_status(path_logs,list_jobs_running,opt.mode);    
        pause(time_cool_down); % pause for a while to let the system finish to write eqsub and oqsub files (useful in 'qsub' mode).
                
        %% Loop over running jobs to check the new status
        num_l = 0;
        for num_j = list_num_running
            num_l = num_l+1;
            name_job = list_jobs{num_j};
            flag_changed = ~strcmp(job_status{num_j},new_status_running_jobs{num_l});            

            if flag_changed

                if flag_nothing_happened % if nothing happened before...
                    %% Reset the 'dot counter'
                    flag_nothing_happened = false;                    
                    nb_checks = 0;
                    if nb_points>0
                        fprintf('\n');
                        fprintf(hfpl,'\n');
                    end
                    nb_points = 0;
                end
                   
                % update status in the status file
                job_status{num_j} = new_status_running_jobs{num_l};
                sub_add_var(file_status,name_job,job_status{num_j});
                sub_add_var(file_status_backup,name_job,job_status{num_j});
                
                if strcmp(job_status{num_j},'exit') % the script crashed ('exit' tag)
                    fprintf('%s - The script of job %s terminated without generating any tag, I guess we will count that one as failed (%i jobs in queue).\n',datestr(clock),name_job,nb_queued);
                    fprintf(hfpl,'%s - The script of job %s terminated without generating any tag, I guess we will count that one as failed (%i jobs in queue).\n',datestr(clock),name_job,nb_queued);;
                    job_status{num_j} = 'failed';
                end

                if strcmp(job_status{num_j},'failed')||strcmp(job_status{num_j},'finished')
                    %% for finished or failed jobs, transfer the individual
                    %% test log files to the matlab global logs structure
                    nb_queued = nb_queued - 1;
                    text_log = sub_read_txt([path_logs filesep name_job '.log']);
                    text_qsub_o = sub_read_txt([path_logs filesep name_job '.oqsub']);
                    text_qsub_e = sub_read_txt([path_logs filesep name_job '.eqsub']);
                    if isempty(text_qsub_o)&isempty(text_qsub_e)
                        sub_add_var(file_logs,name_job,text_log);
                        sub_add_var(file_logs_backup,name_job,text_log);
                    else
                        sub_add_var(file_logs,name_job,[text_log hat_qsub_o text_qsub_o hat_qsub_e text_qsub_e]);
                        sub_add_var(file_logs_backup,name_job,[text_log hat_qsub_o text_qsub_o hat_qsub_e text_qsub_e]);
                    end
                    sub_clean_job(path_logs,name_job); % clean up all tags & log
                end

                switch job_status{num_j}

                    case 'failed' % the job has failed, darn it !

                        fprintf('%s - The job %s has failed (%i jobs in queue).\n',datestr(clock),name_job,nb_queued);
                        fprintf(hfpl,'%s - The job %s has failed (%i jobs in queue).\n',datestr(clock),name_job,nb_queued);
                        list_num_child = find(sub_find_children(num_j,graph_deps));
                        mask_todo(list_num_child) = false; % Remove the children of the failed job from the to-do list

                    case 'finished'

                        fprintf('%s - The job %s has been successfully completed (%i jobs in queue).\n',datestr(clock),name_job,nb_queued);
                        fprintf(hfpl,'%s - The job %s has been successfully completed (%i jobs in queue).\n',datestr(clock),name_job,nb_queued);
                        graph_deps(num_j,:) = 0; % update dependencies

                end

            end % if flag changed
        end % loop over running jobs
                 
        if ~flag_nothing_happened % if something happened ...                   

            %% update the to-do list
            mask_done(mask_running) = ismember(new_status_running_jobs,{'finished','failed','exit'});
            mask_todo(mask_running) = mask_todo(mask_running)&~mask_done(mask_running);

            %% Update the dependency mask
            mask_deps = max(graph_deps,[],1)>0;
            mask_deps = mask_deps(:);

            %% Finally update the list of currently running jobs
            mask_running(mask_running) = mask_running(mask_running)&~mask_done(mask_running);
            
        end

        %% Time to (try to) submit jobs !!
        list_num_to_run = find(mask_todo&~mask_deps);
        num_jr = 1;

        while (nb_queued < max_queued) && (num_jr <= length(list_num_to_run))

            if flag_nothing_happened % if nothing happened before...
                %% Reset the 'dot counter'
                flag_nothing_happened = false;
                nb_checks = 0;
                if nb_points>0
                    fprintf('\n');
                    fprintf(hfpl,'\n');
                end
                nb_points = 0;
            end

            %% Pick up a job to run
            num_job = list_num_to_run(num_jr);
            num_jr = num_jr + 1;
            name_job = list_jobs{num_job};
            file_job = [path_logs filesep name_job '.mat'];
            file_log = [path_logs filesep name_job '.log'];
            mask_todo(num_job) = false;
            mask_running(num_job) = true;
            nb_queued = nb_queued + 1;
            job_status{num_job} = 'submitted';
            sub_add_var(file_status,name_job,job_status{num_job});
            sub_add_var(file_status_backup,name_job,job_status{num_job});
            fprintf('%s - The job %s has been submitted to the queue (%i jobs in queue).\n',datestr(clock),name_job,nb_queued)
            fprintf(hfpl,'%s - The job %s has been submitted to the queue (%i jobs in queue).\n',datestr(clock),name_job,nb_queued);

            %% Create a temporary shell scripts for 'batch' or 'qsub' modes
            if ~strcmp(opt.mode,'session')

                switch gb_psom_language
                    case 'matlab'
                        if ~isempty(opt.shell_options)
                            instr_job = sprintf('%s\n%s -nosplash -nojvm -r "cd %s, load(''%s'',''path_work''), path(path_work), psom_run_job(''%s''),exit">%s\n',opt.shell_options,opt.command_matlab,path_logs,file_pipeline,file_job,file_log);
                        else
                            instr_job = sprintf('%s -nosplash -nojvm -r "cd %s, load(''%s'',''path_work''), path(path_work), psom_run_job(''%s''),exit">%s\n',opt.command_matlab,path_logs,file_pipeline,file_job,file_log);
                        end
                    case 'octave'
                        if ~isempty(opt.shell_options)
                            instr_job = sprintf('%s\n%s -q --eval "cd %s, load(''%s'',''path_work''), path(path_work), psom_run_job(''%s''),exit">%s\n',opt.shell_options,opt.command_matlab,path_logs,file_pipeline,file_job,file_log);
                        else
                            instr_job = sprintf('%s -q --eval "cd %s, load(''%s'',''path_work''), path(path_work), psom_run_job(''%s''),exit">%s\n',opt.command_matlab,path_logs,file_pipeline,file_job,file_log);
                        end
                end

                file_shell = [path_tmp filesep name_job '.sh'];
                file_exit = [path_logs filesep name_job '.exit'];
                hf = fopen(file_shell,'w');
                fprintf(hf,'%s\ntouch %s',instr_job,file_exit);
                fclose(hf);

            end

            %% run the job

            switch opt.mode

                case 'session'

                    diary(file_log)
                    psom_run_job(file_job);
                    diary off

                case 'batch'

                    switch gb_psom_OS
                        case 'windows'
                            instr_batch = ['soon delay 0 "' file_shell '"'];
                        otherwise
                            instr_batch = ['at -f ' file_shell ' now'];
                    end
                   
                    if flag_debug
                        [fail,msg] = system(instr_batch);
                        if fail~=0
                            error('Something went bad with the at command. The command was : %s . The error message was : %s',instr_batch,msg)
                        end
                    else
                        [fail,msg] = system([instr_batch '&']);
                        if fail~=0
                            error('Something went bad with the at command. The command was : %s . The error message was : %s',instr_batch,msg)
                        end
                        delete(file_shell);
                    end
                    
                case 'qsub'

                    file_qsub_o = [path_logs filesep name_job '.oqsub'];
                    file_qsub_e = [path_logs filesep name_job '.eqsub'];

                    instr_qsub = ['qsub -e ' file_qsub_e ' -o ' file_qsub_o ' -N ' name_job(1:min(15,length(name_job))) ' ' opt.qsub_options ' ' file_shell];
                    if flag_debug
                        [fail,msg] = system(instr_qsub);
                        if fail~=0
                            error('Something went bad with the qsub command. The command was : %s . The error message was : %s',instr_qsub,msg)
                        end
                    else
                        [fail,msg] = system([instr_qsub '&']);
                        if fail~=0
                            error('Something went bad with the qsub command. The command was : %s . The error message was : %s',instr_qsub,msg)
                        end
                        delete(file_shell);
                    end
            end % switch mode
        end % submit jobs       
        
        pause(time_between_checks); % To avoid wasting resources, wait a bit before re-trying to submit jobs

        if nb_checks >= nb_checks_per_point
            nb_checks = 0;
            fprintf('.');
            fprintf(hfpl,'.');
            nb_points = nb_points+1;
        else
            nb_checks = nb_checks+1;
        end

    end % While there are jobs to do

catch

    errmsg = lasterror;
    
    if exist('path_tmp','var')
        if exist(path_tmp,'dir')
            if strcmp(gb_psom_language,'octave')
                instr_rm = ['rm -rf ' path_tmp];
                [succ,msg] = system(instr_rm);
            else
                rmdir(path_tmp,'s'); % Clean the temporary folder
            end
        end
    end   

    fprintf('\n\n******************\nSomething went bad ... the pipeline has FAILED !\nThe last error message occured was :\n%s\n',errmsg.message);
    fprintf(hfpl,'\n\n******************\nSomething went bad ... the pipeline has FAILED !\nThe last error message occured was :\n%s\n',errmsg.message);
    if isfield(errmsg,'stack')
        for num_e = 1:length(errmsg.stack)
            fprintf('File %s at line %i\n',errmsg.stack(num_e).file,errmsg.stack(num_e).line);
            fprintf(hfpl,'File %s at line %i\n',errmsg.stack(num_e).file,errmsg.stack(num_e).line);
        end
    end
    if exist('file_pipe_running','var')
        if exist(file_pipe_running,'file')
            delete(file_pipe_running); % remove the 'running' tag
        end
    end
    
end

if exist('path_tmp','var')
    if exist(path_tmp,'dir')
        if strcmp(gb_psom_language,'octave')
            instr_rm = ['rm -rf ' path_tmp];
            [succ,msg] = system(instr_rm);
        else
            rmdir(path_tmp,'s'); % Clean the temporary folder
        end
    end
end

%% Print general info about the pipeline
msg_line1 = sprintf('The processing of the pipeline was completed.');
msg_line2 = sprintf('%s',datestr(now));
size_msg = max([size(msg_line1,2),size(msg_line2,2)]);
msg = sprintf('%s\n%s',msg_line1,msg_line2);
stars = repmat('*',[1 size_msg]);
fprintf('\n%s\n%s\n%s\n',stars,msg,stars);
fprintf(hfpl,'\n%s\n%s\n%s\n',stars,msg,stars);

%% Print a list of failed jobs
list_num_failed = find(ismember(job_status,'failed'));
list_num_failed = list_num_failed(:)';
list_num_none = find(ismember(job_status,'none'));
list_num_none = list_num_none(:)';
flag_any_fail = ~isempty(list_num_failed);

if flag_any_fail
    if length(list_num_failed) == 1
        fprintf('The execution of the following job has failed :\n\n    ');
        fprintf(hfpl,'The execution of the following job has failed :\n\n    ');
    else
        fprintf('The execution of the following jobs have failed :\n\n    ');
        fprintf(hfpl,'The execution of the following jobs have failed :\n\n    ');
    end
    for num_j = list_num_failed
        name_job = list_jobs{num_j};
        fprintf('%s ; ',name_job);
        fprintf(hfpl,'%s ; ',name_job);
    end
    fprintf('\n\n');
    fprintf(hfpl,'\n\n');
    fprintf('More infos can be found in the individual log files. Use the following command to display these logs :\n\n    psom_pipeline_visu(''%s'',''log'',JOB_NAME)\n\n',path_logs);
    fprintf(hfpl,'More infos can be found in the individual log files. Use the following command to display these logs :\n\n    psom_pipeline_visu(''%s'',''log'',JOB_NAME)\n\n',path_logs);    
end

%% Print a list of jobs that could not be processed
if ~isempty(list_num_none)
    if length(list_num_none) == 1
        fprintf('The following job has not been processed due to a dependence on a failed job:\n\n    ');
        fprintf(hfpl,'The following job has not been processed due to a dependence on a failed job:\n\n    ');
    else
        fprintf('The following jobs have not been processed due to a dependence on a failed job:\n\n    ');
        fprintf(hfpl,'The following jobs have not been processed due to a dependence on a failed job:\n\n    ');
    end
    for num_j = list_num_none
        name_job = list_jobs{num_j};
        fprintf('%s ; ',name_job);
        fprintf(hfpl,'%s ; ',name_job);
    end
    fprintf('\n\n');
    fprintf(hfpl,'\n\n');
end

%% Give a final one-line summary of the processing
if flag_any_fail
    fprintf('All jobs have been processed, but some jobs have failed.\nYou may want to restart the pipeline latter if you managed to fix the problems.\n');
    fprintf(hfpl,'All jobs have been processed, but some jobs have failed.\nYou may want to restart the pipeline latter if you managed to fix the problems.\n');
else
    if isempty(list_num_none)
        fprintf('All jobs have been successfully completed.\n');
        fprintf(hfpl,'All jobs have been successfully completed.\n');
    end
end

fclose(hfpl);

if exist('file_pipe_running','var')
    if exist(file_pipe_running,'file')
        delete(file_pipe_running); % remove the 'running' tag
    end
end

%%%%%%%%%%%%%%%%%%
%% subfunctions %%
%%%%%%%%%%%%%%%%%%

%% Find the children of a job
function mask_child = sub_find_children(num_j,graph_deps)

% INPUTS : 
% 
% GRAPH_DEPS
%   (matrix) GRAPH_DEPS(J,K) == 1 if and only if JOB K depends on JOB J. 
%   GRAPH_DEPS = 0 otherwise. 
%       
% NUM_J
%   (integer) the number of a job.
%
% OUTPUTS:
%
% MASK_CHILD
%   (vector) MASK_CHILD(NUM_K) = 1 if job NUM_K is a child of NUM_J, and 0 
%   otherwise.
%
% COMMENTS:
% This (ugly but reasonably fast) recursive code will work
% only if the directed graph defined by GRAPH_DEPS is acyclic.

mask_child = graph_deps(num_j,:)>0;
list_num_child = find(mask_child);

if ~isempty(list_num_child)
    for num_c = list_num_child        
        mask_child = mask_child | sub_find_children(num_c,graph_deps);
    end
end

%% Update (or add) a variable in an existing '.mat' file

function sub_add_var(file_name,var_name,var_value)

eval([var_name ' = var_value;']);
if ~exist(file_name,'file')
    save(file_name,var_name)
else
    save('-append',file_name,var_name)
end

%% Read a text file
function str_txt = sub_read_txt(file_name)

if exist(file_name,'file')
    hf = fopen(file_name,'r');
    str_txt = fread(hf,Inf,'uint8=>char')';
    fclose(hf);
else
    str_txt = '';
end

%% Clean up the tags and logs associated with a job

function [] = sub_clean_job(path_logs,name_job)

files{1} = [path_logs filesep name_job '.log'];
files{2} = [path_logs filesep name_job '.finished'];
files{3} = [path_logs filesep name_job '.failed'];
files{4} = [path_logs filesep name_job '.running'];
files{5} = [path_logs filesep name_job '.exit'];
files{6} = [path_logs filesep name_job '.eqsub'];
files{7} = [path_logs filesep name_job '.oqsub'];

for num_f = 1:length(files)
    if exist(files{num_f},'file')
        delete(files{num_f});
    end
end