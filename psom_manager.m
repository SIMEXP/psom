function status_pipe = psom_manager(path_logs,opt)
% Manage the execution of a pipeline
%
% status = psom_manager(path_logs,opt)
%
% PATH_LOGS 
%   (string) the path name to a logs folder.
%
% OPT
%   (structure) with the following fields :
%
%   TIME_BETWEEN_CHECKS
%
%   NB_CHECKS_PER_POINT
%
%   MAX_QUEUED
%
%   FLAG_VERBOSE
%      (integer 0, 1 or 2, default 1) No verbose (0), standard 
%      verbose (1), a lot of verbose, useful for debugging (2).
%
% _________________________________________________________________________
% OUTPUTS:
%
% STATUS 
%   (integer) if the pipeline manager runs in 'session' mode, STATUS is 
%   0 if all jobs have been successfully completed, 1 if there were errors.
%   In all other modes, STATUS is NaN.
%
% STATUS (integer) STATUS is 0 if all jobs have been successfully completed, 
%   1 if there were errors.
%
% See licensing information in the code.

% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
% Departement d'informatique et de recherche operationnelle
% Centre de recherche de l'institut de Geriatrie de Montreal
% Universite de Montreal, 2010-2015.
% Maintainer : pierre.bellec@criugm.qc.ca
% Keywords : pipeline
%
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
if ~exist('path_logs','var')
    error('Syntax: [] = psom_deamon(path_logs,opt)')
end

%% Options
if nargin < 2
    opt = struct;
end
opt = psom_struct_defaults( opt , ...
   {  'flag_verbose' , 'time_between_checks' , 'nb_checks_per_point' , 'max_queued' };
   {  1              , NaN                   , NaN                   ,              };
psom_set_defaults

%% File names
file_pipeline     = [path_logs 'PIPE_jobs.mat'];
file_pipe_running = [path_logs 'PIPE.lock'];
file_heartbeat    = [path_logs 'heartbeat.mat'];
file_kill         = [path_logs 'PIPE.kill'];
file_news_feed    = [path_logs 'news_feed.csv'];
path_worker       = [path_logs 'worker' filesep];

%% Start heartbeat
main_pid = getpid;
cmd = sprintf('psom_heartbeat(''%s'',''%s'',%i)',file_heartbeat,file_kill,main_pid);
if strcmp(gb_psom_language,'octave')
    instr_heartbeat = sprintf('"%s" %s "addpath(''%s''), %s,exit"',gb_psom_command_octave,gb_psom_opt_matlab,gb_psom_path_psom,cmd);
else 
    instr_heartbeat = sprintf('"%s" %s "addpath(''%s''), %s,exit"',gb_psom_command_matlab,gb_psom_opt_matlab,gb_psom_path_psom,cmd);
end 
system([instr_heartbeat '&']);
    
%% Check for the existence of the pipeline
if ~exist(file_pipeline,'file') % Does the pipeline exist ?
    error('Could not find the pipeline file %s. Please use psom_run_pipeline instead of psom_manager directly.',file_pipeline);
end

%% Create a running tag on the pipeline (if not done during the initialization phase)
if ~psom_exist(file_pipe_running)
    str_now = datestr(clock);
    save(file_pipe_running,'str_now');
end

% a try/catch block is used to clean temporary file if the user is
% interrupting the pipeline of if an error occurs
try    
    
    %% Open the news feed file
    if strcmp(gb_psom_language,'matlab');
        hf_news = fopen(file_news_feed,'w');
    else
        hf_news = file_news_feed;
        if psom_exist(file_news_feed)
            psom_clean(file_news_feed);
        end
    end
       
    %% Print general info about the pipeline
    msg_line1 = sprintf('Deamon started on %s',datestr(clock));
    msg_line2 = sprintf('user: %s, host: %s, system: %s',gb_psom_user,gb_psom_localhost,gb_psom_OS);
    stars = repmat('*',[1 max(length(msg_line1),length(msg_line2))]);
    fprintf('%s\n%s\n%s\n%s\n',stars,msg_line1,msg_line2,stars);
    
    %% Load the pipeline
    pipeline = load(file_pipeline);
    list_jobs = fieldnames(pipeline);
    nb_jobs = length(list_jobs);
    
    %% Initialize miscallenaous variables
    psom_plan     = zeros(nb_jobs,1);          % a summary of which worker is running which job
    mask_running  = false(nb_jobs,1);          % A binary mask of running jobs
    mask_failed   = false(nb_jobs,1);          % A binary mask of failed jobs
    mask_finished = false(nb_jobs,1);          % A binary mask of finished jobs
    mask_todo     = true(nb_jobs,1);           % A binary mask of jobs that remain to do
    nb_running    = 0;                         % The number of running jobs
    nb_failed     = 0;                         % The number of failed jobs
    nb_finished   = 0;                         % The number of finished jobs
    nb_todo       = 0;                         % The number of jobs to do
    worker_active = false(opt.max_queued,1);   % A binary list of active workers
    nb_char_news  = zeros(opt.max_queued,1);   % A list of the number of characters read from the news per worker
    nb_run_worker = zeros(opt.max_queued,1);   % A list of the number of running job per worker
    news_worker   = repmat({''},[opt.max_queued,1]);

    %% Find the longest job name
    lmax = 0;
    for num_j = 1:length(list_jobs)
        lmax = max(lmax,length(list_jobs{num_j}));
    end
    
    %% Start submitting jobs
    test_loop = true;
    while test_loop

        %% Check the state of workers
        %% and read the news
        for num_w = 1:opt.max_queued
            file_worker_news = sprintf('%spsom%i%snews_feed.csv',path_worker,num_w,filesep);
            if psom_exist(file_worker_news)
                [str_read,nb_char_news(num_w)] = sub_tail(h_worker(num_w),nb_char_news(num_w));
                news_worker{num_w} = [news_worker{num_w} str_read];
                [event_worker,news_worker{num_w}] = sub_parse(news_worker{num_w});
                
                %% Some verbose for the events
                for num_e = 1:length(event_worker)
                    %% Update status
                    mask_job = strcmp(list_jobs,event_worker{1});
                    switch envent_worker{2}
                        case 'submitted'
                            nb_running = nb_running+1;
                            nb_todo = nb_todo-1;
                            mask_todo(mask_job) = false;
                            mask_running(mask_job) = true;
                        case 'failed'
                            nb_running = nb_running-1;
                            nb_failed = nb_failed+1;
                            mask_running(mask_job) = false;
                            mask_failed(mask_job) = true;
                        case 'finished'
                            nb_running = nb_running-1;
                            nb_finished = nb_finished+1;
                            mask_running(mask_job) = false;
                            mask_finished(mask_job) = true;
                    end
                    %% Add to the news feed
                    sub_add_line_log(hf_news,sprintf('%s , %s\n',event_worker{num_e,1},event_worker{num_e,2}));
                    msg = sprintf('%s %s%s failed   ',datestr(clock),name_job,repmat(' ',[1 lmax-length(name_job)]));
                    fprintf('%s (%i run / %i fail / %i done / %i left)\n',msg,nb_running,nb_failed,nb_finished,nb_todo);
                end
            end    
        end
               
        
        if opt.flag_spawn
            list_ready = dir([path_spawn '*.ready']);
            list_ready = { list_ready.name };
            if ~isempty(list_ready)
                for num_r = 1:length(list_ready)
                    [tmp,base_spawn] = fileparts(list_ready{num_r});
                    file_spawn = [path_spawn base_spawn '.mat'];
                    if ~psom_exist(file_spawn)
                        error('I could not find %s for spawning',file_spawn)
                    end
                    spawn = load(file_spawn);
                    list_new_jobs = fieldnames(spawn);
                    if any(ismember(list_jobs,list_new_jobs))
                        error('Spawn jobs cannot have the same name as existing jobs in %s',file_spawn)
                    end
                    nb_todo = nb_todo+length(list_new_jobs);
                    tab_refresh(end+1:end+length(list_new_jobs),:,1) = -ones(length(list_new_jobs),6);
                    tab_refresh(end+1:end+length(list_new_jobs),:,2) = repmat(clock,[length(list_new_jobs) 1]);
                    list_jobs    = [ list_jobs ; list_new_jobs ];
                    nb_sub       = [ nb_sub ; zeros(length(list_new_jobs),1)];
                    mask_done    = [ mask_done ; false(length(list_new_jobs),1)];
                    mask_todo    = [ mask_todo ; true(length(list_new_jobs),1)];
                    mask_running = [ mask_running ; false(length(list_new_jobs),1)];
                    mask_deps    = [ mask_deps ; false(length(list_new_jobs),1)];
                    graph_deps_old = graph_deps;
                    graph_deps = sparse(length(list_jobs),length(list_jobs));
                    graph_deps(1:size(graph_deps_old,1),1:size(graph_deps_old,1)) = graph_deps_old;
                    clear graph_deps_old
                    save(file_jobs,'-struct','-append','spawn')
                    psom_clean({file_spawn,[path_spawn list_ready{num_r}]});
                end
            end
        end
        
        %% Update logs & status
        save(file_logs           ,'-struct','logs');
        copyfile(file_logs,file_logs_backup,'f');        
        save(file_status         ,'-struct','status');
        copyfile(file_status,file_status_backup,'f');
        save(file_profile        ,'-struct','profile');
        copyfile(file_profile,file_profile_backup,'f');
        
        %% Update the status of running jobs
        if isempty(list_event)
            list_num_running = find(mask_running);
            list_num_running = list_num_running(:)';
            list_jobs_running = list_jobs(list_num_running);
            [new_status_running_jobs,tab_refresh(list_num_running,:,:)] = psom_job_status(path_logs,list_jobs_running,opt.mode,tab_refresh(list_num_running,:,:));
            
            %% Detect events
            flag_changed = ~ismember(new_status_running_jobs,{'submitted','running'});
            list_event = list_num_running(flag_changed);
            new_status_running_jobs = new_status_running_jobs(flag_changed); 
        end
        
        % if nothing happened before but an event occured...
        if flag_nothing_happened&&~isempty(list_event) 
            %% Reset the 'dot counter'
            flag_nothing_happened = false;
            nb_checks = 0;
            if nb_points>0
                sub_add_line_log(hfpl,sprintf('\n'),flag_verbose);
            end
            nb_points = 0;
        end
        
        %% Give some time to generate the eqsub/oqsub files 
        if time_cool_down>0
            if exist('OCTAVE_VERSION','builtin')  
                [res,msg] = system(sprintf('sleep %i',time_cool_down));
            else
                pause(time_cool_down); 
            end
        end
        
        %% Update the status of one of the jobs
        flag_nothing_happened = isempty(list_event);
        if ~flag_nothing_happened
            num_l = 1;
            num_j = list_event(num_l);
            name_job = list_jobs{num_j};
            status.(name_job) = new_status_running_jobs{num_l};
                
            if strcmp(status.(name_job),'exit') % the script crashed ('exit' tag)
                sub_add_line_log(hfpl,sprintf('%s - The script of job %s terminated without generating any tag, I guess we will count that one as failed.\n',datestr(clock),name_job),flag_verbose);;
                status.(name_job) = 'failed';
                nb_failed = nb_failed + 1;
            end
                
            if strcmp(status.(name_job),'failed')||strcmp(status.(name_job),'finished')
                %% for finished or failed jobs, transfer the individual
                %% test log files to the matlab global logs structure
                nb_queued = nb_queued - 1;
                text_log    = sub_read_txt([path_logs filesep name_job '.log']);
                text_qsub_o = sub_read_txt([path_logs filesep name_job '.oqsub']);
                text_qsub_e = sub_read_txt([path_logs filesep name_job '.eqsub']);                    
                if isempty(text_qsub_o)&&isempty(text_qsub_e)
                    logs.(name_job) = text_log;                        
                else
                    logs.(name_job) = [text_log hat_qsub_o text_qsub_o hat_qsub_e text_qsub_e];
                end
                %% Update profile for the jobs
                file_profile_job = [path_logs filesep name_job '.profile.mat'];
                if psom_exist(file_profile_job)
                    profile.(name_job) = load(file_profile_job);
                end
                profile.(name_job).nb_submit = nb_sub(num_j);
                sub_clean_job(path_logs,name_job); % clean up all tags & log                    
            end
                
            switch status.(name_job)
                    
                case 'failed' % the job has failed, too bad !

                    if nb_sub(num_j) > nb_resub % Enough attempts to submit the jobs have been made, it failed !
                        nb_failed = nb_failed + 1;   
                        msg = sprintf('%s %s%s failed   ',datestr(clock),name_job,repmat(' ',[1 lmax-length(name_job)]));
                        sub_add_line_log(hfpl,sprintf('%s (%i run / %i fail / %i done / %i left)\n',msg,nb_queued,nb_failed,nb_finished,nb_todo),flag_verbose);
                        sub_add_line_log(hfnf,sprintf('%s , failed\n',name_job),false);
                        mask_child = false([1 length(mask_todo)]);
                        mask_child(num_j) = true;
                        mask_child = sub_find_children(mask_child,graph_deps);
                        mask_todo(mask_child) = false; % Remove the children of the failed job from the to-do list
                    else % Try to submit the job one more time (at least)
                        mask_todo(num_j) = true;
                        status.(name_job) = 'none';
                        new_status_running_jobs{num_l} = 'none';
                        nb_todo = nb_todo+1;
                        msg = sprintf('%s %s%s reset    ',datestr(clock),name_job,repmat(' ',[1 lmax-length(name_job)]));
                        sub_add_line_log(hfpl,sprintf('%s (%i run / %i fail / %i done / %i left)\n',msg,nb_queued,nb_failed,nb_finished,nb_todo),flag_verbose);
                    end

                case 'finished'
                    nb_finished = nb_finished + 1;                        
                    msg = sprintf('%s %s%s completed',datestr(clock),name_job,repmat(' ',[1 lmax-length(name_job)]));
                    sub_add_line_log(hfpl,sprintf('%s (%i run / %i fail / %i done / %i left)\n',msg,nb_queued,nb_failed,nb_finished,nb_todo),flag_verbose);
                    sub_add_line_log(hfnf,sprintf('%s , finished\n',name_job),false);
                    graph_deps(num_j,:) = 0; % update dependencies
            end
            
            %% update the to-do list
            mask_done(num_j) = ismember(new_status_running_jobs{num_l},{'finished','failed','exit'});
            mask_todo(num_j) = mask_todo(num_j)&~mask_done(num_j);
            
            %% Update the dependency mask
            mask_deps = max(graph_deps,[],1)>0;
            mask_deps = mask_deps(:);
            
            %% Remove the updated job from the list of running jobs
            mask_running(num_j) = false;
            list_event = list_event(2:end);
            new_status_running_jobs = new_status_running_jobs(2:end);
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
                    sub_add_line_log(hfpl,sprintf('\n'),flag_verbose);
                end
                nb_points = 0;
            end
            
            %% Pick up a job to run
            num_job = list_num_to_run(num_jr);
            num_jr = num_jr + 1;
            name_job = list_jobs{num_job};
            
            mask_todo(num_job) = false;
            mask_running(num_job) = true;
            nb_queued = nb_queued + 1;
            nb_todo = nb_todo - 1;
            nb_sub(num_job) = nb_sub(num_job)+1;
            status.(name_job) = 'submitted';
            msg = sprintf('%s %s%s submitted',datestr(clock),name_job,repmat(' ',[1 lmax-length(name_job)]));            
            sub_add_line_log(hfpl,sprintf('%s (%i run / %i fail / %i done / %i left)\n',msg,nb_queued,nb_failed,nb_finished,nb_todo),flag_verbose);
            sub_add_line_log(hfnf,sprintf('%s , submitted\n',name_job),false);
            
            %% Execute the job in a "shelled" environment
            file_job        = [path_logs filesep name_job '.mat'];
            opt_logs.txt    = [path_logs filesep name_job '.log'];
            opt_logs.eqsub  = [path_logs filesep name_job '.eqsub'];
            opt_logs.oqsub  = [path_logs filesep name_job '.oqsub'];
            opt_logs.failed = [path_logs filesep name_job '.failed'];
            opt_logs.exit   = [path_logs filesep name_job '.exit'];
            opt_script.path_search    = file_pipeline;
            opt_script.name_job       = name_job;
            opt_script.mode           = opt.mode;
            opt_script.init_matlab    = opt.init_matlab;
            opt_script.flag_debug     = opt.flag_debug;        
            opt_script.shell_options  = opt.shell_options;
            opt_script.command_matlab = opt.command_matlab;
            opt_script.qsub_options   = opt.qsub_options;
            opt_script.flag_short_job_names = opt.flag_short_job_names;
            opt_script.file_handle    = hfpl;
            if strcmp(opt_script.mode,'session')
                cmd = sprintf('psom_run_job(''%s'')',file_job);
            else
                cmd = sprintf('psom_run_job(''%s'',true)',file_job);
            end
                
            if ispc % this is windows
                script = [path_tmp filesep name_job '.bat'];
            else
                script = [path_tmp filesep name_job '.sh'];
            end
                
            [flag_failed,errmsg] = psom_run_script(cmd,script,opt_script,opt_logs);
            if flag_failed~=0
                msg = fprintf('\n    The execution of the job %s failed.\n The feedback was : %s\n',name_job,errmsg);
                sub_add_line_log(hfpl,msg,true);
                error('Something went bad with the execution of the job.')
            elseif flag_debug
                msg = fprintf('\n    The feedback from the execution of job %s was : %s\n',name_job,errmsg);
                sub_add_line_log(hfpl,msg,true);
            end            
        end % submit jobs
        
        if flag_nothing_happened && (any(mask_todo) || any(mask_running)) && psom_exist(file_pipe_running)
            if exist('OCTAVE_VERSION','builtin')  
                [res,msg] = system(sprintf('sleep %i',time_between_checks));
            else
                pause(time_between_checks); % To avoid wasting resources, wait a bit before re-trying to submit jobs
            end
        end
        
        if strcmp(gb_psom_language,'octave') && ismember(opt.mode,{'qsub','msub','condor'})
            % In octave, due to the way asynchronous processes work, it is necessary to listen to children to kill 
            % zombies
            tmp = 1;
            while tmp ~= -1
                tmp = waitpid(-1);
            end
        end
        
        if nb_checks >= nb_checks_per_point
            nb_checks = 0;
            if flag_verbose
                fprintf('.');
            end
            sub_add_line_log(hfpl,sprintf('.'),flag_verbose);
            nb_points = nb_points+1;
        else
            nb_checks = nb_checks+1;
        end
        
        if opt.flag_spawn
            test_loop = psom_exist(file_pipe_running);
        else
            test_loop = (any(mask_todo) || any(mask_running)) && psom_exist(file_pipe_running);
        end
    end % While there are jobs to do
    
catch
    
    errmsg = lasterror;        
    sub_add_line_log(hfpl,sprintf('\n\n******************\nSomething went bad ... the pipeline has FAILED !\nThe last error message occured was :\n%s\n',errmsg.message),flag_verbose);
    if isfield(errmsg,'stack')
        for num_e = 1:length(errmsg.stack)
            sub_add_line_log(hfpl,sprintf('File %s at line %i\n',errmsg.stack(num_e).file,errmsg.stack(num_e).line),flag_verbose);
        end
    end
    if exist('file_pipe_running','var')
        if exist(file_pipe_running,'file')
            delete(file_pipe_running); % remove the 'running' tag
        end
    end
    
    %% Close the log file
    if strcmp(gb_psom_language,'matlab')
        fclose(hfpl);
        fclose(hfnf);
    end
    status_pipe = 1;
    return
end

%% Update the final status
save(file_logs           ,'-struct','logs');
copyfile(file_logs,file_logs_backup,'f');
save(file_status         ,'-struct','status');
copyfile(file_status,file_status_backup,'f');
save(file_profile        ,'-struct','profile');
copyfile(file_profile,file_profile_backup,'f');

%% Print general info about the pipeline
msg_line1 = sprintf('Pipeline terminated on %s',datestr(now));
stars = repmat('*',[1 length(msg_line1)]);
sub_add_line_log(hfpl,sprintf('%s\n%s\n',stars,msg_line1),flag_verbose);

%% Report if the lock file was manually removed
if exist('file_pipe_running','var')
    if ~exist(file_pipe_running,'file')        
        sub_add_line_log(hfpl,sprintf('The pipeline manager was interrupted because the .lock file was manually deleted.\n'),flag_verbose);
    end
    if any(mask_running)
        list_num_running = find(mask_running);
        sub_add_line_log(hfpl,'Killing left-overs ...\n',flag_verbose)
        list_num_running = list_num_running(:)';
        list_jobs_running = list_jobs(list_num_running); 
        for num_r = 1:length(list_jobs_running)
            file_kill = [path_logs filesep list_jobs_running{num_r} '.kill'];
            hf = fopen(file_kill,'w');
            fclose(hf);
        end
    end
end

%% Print a list of failed jobs
mask_failed = false([length(list_jobs) 1]);
for num_j = 1:length(list_jobs)
    mask_failed(num_j) = strcmp(status.(list_jobs{num_j}),'failed');
end
mask_todo = false([length(list_jobs) 1]);
for num_j = 1:length(list_jobs)
    mask_todo(num_j) = strcmp(status.(list_jobs{num_j}),'none');
end
list_num_failed = find(mask_failed);
list_num_failed = list_num_failed(:)';
list_num_none = find(mask_todo);
list_num_none = list_num_none(:)';
flag_any_fail = ~isempty(list_num_failed);

if flag_any_fail
    if length(list_num_failed) == 1
        sub_add_line_log(hfpl,sprintf('1 job has failed.\n',length(list_num_failed)),flag_verbose);
    else
        sub_add_line_log(hfpl,sprintf('%i jobs have failed.\n',length(list_num_failed)),flag_verbose);
    end
    sub_add_line_log(hfpl,sprintf('Use psom_pipeline_visu to access logs, e.g.:\n\n    psom_pipeline_visu(''%s'',''log'',''%s'')\n\n',path_logs,list_jobs{list_num_failed(1)}),flag_verbose);
end

%% Print a list of jobs that could not be processed
if ~isempty(list_num_none)
    if length(list_num_none) == 1
        sub_add_line_log(hfpl,sprintf('1 job could not be processed due to a dependency on a failed job or the interruption of the pipeline manager.\n'),flag_verbose);
    else
        sub_add_line_log(hfpl,sprintf('%i jobs could not be processed due to a dependency on a failed job or the interruption of the pipeline manager.\n', length(list_num_none)),flag_verbose);
    end
end

%% Give a final one-line summary of the processing
if flag_any_fail    
    sub_add_line_log(hfpl,sprintf('Some jobs have failed.\n'),flag_verbose);
else
    if isempty(list_num_none)
        sub_add_line_log(hfpl,sprintf('All jobs have been successfully completed.\n'),flag_verbose);
    end
end

if ~strcmp(opt.mode_pipeline_manager,'session')&& strcmp(gb_psom_language,'octave')   
    sub_add_line_log(hfpl,sprintf('Press CTRL-C to go back to Octave.\n'),flag_verbose);
end

%% Close the log file
if strcmp(gb_psom_language,'matlab')
    fclose(hfpl);
    fclose(hfnf);
end

if exist('file_pipe_running','var')
    if exist(file_pipe_running,'file')
        delete(file_pipe_running); % remove the 'running' tag
    end
end

status_pipe = double(flag_any_fail);

%%%%%%%%%%%%%%%%%%
%% subfunctions %%
%%%%%%%%%%%%%%%%%%

%% Find the children of a job
function mask_child = sub_find_children(mask,graph_deps)
% GRAPH_DEPS(J,K) == 1 if and only if JOB K depends on JOB J. GRAPH_DEPS =
% 0 otherwise. This (ugly but reasonably fast) recursive code will work
% only if the directed graph defined by GRAPH_DEPS is acyclic.
% MASK_CHILD(NUM_J) == 1 if the job NUM_J is a children of one of the job
% in the boolean mask MASK and the job is in MASK_TODO.
% This last restriction is used to speed up computation.

if max(double(mask))>0
    mask_child = max(graph_deps(mask,:),[],1)>0;    
    mask_child_strict = mask_child & ~mask;
else
    mask_child = false(size(mask));
end

if any(mask_child)
    mask_child = mask_child | sub_find_children(mask_child_strict,graph_deps);
end

%% Read a text file
function str_txt = sub_read_txt(file_name)

hf = fopen(file_name,'r');
if hf == -1
    str_txt = '';
else
    str_txt = fread(hf,Inf,'uint8=>char')';
    fclose(hf);    
end

%% Clean up the tags and logs associated with a job
function [] = sub_clean_job(path_logs,name_job)

files{1}  = [path_logs filesep name_job '.log'];
files{2}  = [path_logs filesep name_job '.finished'];
files{3}  = [path_logs filesep name_job '.failed'];
files{4}  = [path_logs filesep name_job '.running'];
files{5}  = [path_logs filesep name_job '.exit'];
files{6}  = [path_logs filesep name_job '.eqsub'];
files{7}  = [path_logs filesep name_job '.oqsub'];
files{8}  = [path_logs filesep name_job '.profile.mat'];
files{9}  = [path_logs filesep name_job '.heartbeat.mat'];
files{10} = [path_logs filesep name_job '.kill'];
files{11} = [path_logs filesep 'tmp' filesep name_job '.sh'];

for num_f = 1:length(files)
    if psom_exist(files{num_f});
        delete(files{num_f});
    end
end

function [] = sub_add_line_log(file_write,str_write,flag_verbose);

if flag_verbose
    fprintf('%s',str_write)
end

if ischar(file_write)
    hf = fopen(file_write,'a');
    fprintf(hf,'%s',str_write);
    fclose(hf);
else
    fprintf(file_write,'%s',str_write);
end

function [] = sub_sleep(time_sleep)

if exist('OCTAVE_VERSION','builtin')  
    [res,msg] = system(sprintf('sleep %1.3f',time_sleep));
else
    pause(time_sleep); 
end

function [str_read,nb_chars] = sub_tail(file_read,nb_chars)
% Read the tail of a text file
hf = fopen(file_read,'r');
fseek(hf,nb_chars,'bof');
str_read = fread(hf, Inf , 'uint8=>char')';
nb_chars = ftell(hf);
fclose(hf);

function [events,news] = sub_parse_news(news)
% Parse the news feed
news_line = psom_string2lines(news);
if strcmp(news(end),char(10))||strcmp(news(end),char(13))
    % The last line happens to be complete
    news = ''; % we are able to parse eveything
else
    news = news_line{end};
    news_line = news_line(1:end-1);
end
nb_lines = length(news_line);
events = cell(nb_lines,2);
for num_e = 1:nb_lines
    pos = strfind(news_line,' , ');
    events{num_e,1} = news_line{num_e}(1:pos-1);
    events{num_e,2} = news_line{num_e}(pos+3:end);
end
    
