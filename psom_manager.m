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
%   MAX_BUFFER
%
%   FLAG_VERBOSE
%      (integer 0, 1 or 2, default 1) No verbose (0), verbose (1).
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
    error('Syntax: [] = psom_manager(path_logs,opt)')
end

%% Options
if nargin < 2
    opt = struct;
end
opt = psom_struct_defaults( opt , ...
   {  'flag_verbose' , 'time_between_checks' , 'nb_checks_per_point' , 'max_queued' , 'max_buffer' }, ...
   {  1              , NaN                   , NaN                   , NaN          , 5            });

%% Logs folder
if ~strcmp(path_logs(end),filesep)
    path_logs = [ path_logs filesep];
end

%% File names
file_pipeline     = [path_logs 'PIPE.mat'];
file_jobs         = [path_logs 'PIPE_jobs.mat'];
file_status       = [path_logs 'PIPE_status.mat'];
file_pipe_running = [path_logs 'PIPE.lock'];
file_heartbeat    = [path_logs 'heartbeat.mat'];
file_kill         = [path_logs 'PIPE.kill'];
file_news_feed    = [path_logs 'news_feed.csv'];
path_worker       = [path_logs 'worker' filesep];

for num_w = 1:opt.max_queued
    file_worker_news{num_w}  = sprintf('%spsom%i%snews_feed.csv',path_worker,num_w,filesep);
    file_worker_heart{num_w} = sprintf('%spsom%i%sheartbeat.mat',path_worker,num_w,filesep);
    file_worker_job{num_w}   = sprintf('%spsom%i%snew_jobs.mat',path_worker,num_w,filesep);
    file_worker_ready{num_w} = sprintf('%spsom%i%snew_jobs.ready',path_worker,num_w,filesep);
    file_worker_reset{num_w} = sprintf('%spsom%i%sworker.reset',path_worker,num_w,filesep);
end
          
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
if ~exist(file_jobs,'file') % Does the pipeline exist ?
    error('Could not find the pipeline file %s. Please use psom_run_pipeline instead of psom_manager directly.',file_jobs);
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
    if strcmp(gb_psom_language,'matlab')
        hf_news = fopen(file_news_feed,'w');
    else
        if psom_exist(file_news_feed)
            psom_clean(file_news_feed);
        end
        hf_news = file_news_feed;
        hf = fopen(hf_news,'w');
        fclose(hf);
    end
       
    %% Print general info about the pipeline
    msg_line1 = sprintf('Pipeline started on %s',datestr(clock));
    msg_line2 = sprintf('user: %s, host: %s, system: %s',gb_psom_user,gb_psom_localhost,gb_psom_OS);
    stars = repmat('*',[1 max(length(msg_line1),length(msg_line2))]);
    fprintf('%s\n%s\n%s\n%s\n',stars,msg_line1,msg_line2,stars);
    
    %% Load the pipeline
    load(file_pipeline,'list_jobs','graph_deps');
    status = load(file_status);
    pipeline = load(file_jobs);
    nb_jobs = length(list_jobs);
    
    %% Initialize the mask of finished jobs
    mask_finished = false([length(list_jobs) 1]);
    for num_j = 1:length(list_jobs)
        mask_finished(num_j) = strcmp(status.(list_jobs{num_j}),'finished');
        if mask_finished(num_j)
            sub_add_line_log(hf_news,sprintf('%s , finished\n',list_jobs{num_j}),false);
        end
    end
    nb_finished = sum(mask_finished); % The number of finished jobs                         
    graph_deps(mask_finished,:) = 0;
    mask_deps = max(graph_deps,[],1)>0;
    mask_deps = mask_deps(:);
    
    %% Initialize the to-do list
    mask_todo = false([length(list_jobs) 1]);
    for num_j = 1:length(list_jobs)
        mask_todo(num_j) = strcmp(status.(list_jobs{num_j}),'none');
    end    
    nb_todo = sum(mask_todo);    % The number of jobs to do
    
    %% Initialize miscallenaous variables
    psom_plan     = zeros(nb_jobs,1);          % a summary of which worker is running which job
    mask_running  = false(nb_jobs,1);          % A binary mask of running jobs
    mask_failed   = false(nb_jobs,1);          % A binary mask of failed jobs
    nb_failed     = 0;                         % The number of failed jobs
    nb_running    = 0;                         % The number of running jobs
    nb_checks     = 0;                         % The number of checks before printing a point
    worker_reset  = false(opt.max_queued,1);    % A binary list of workers that have been reset
    nb_char_news  = zeros(opt.max_queued,1);   % A list of the number of characters read from the news per worker
    nb_run_worker = zeros(opt.max_queued,1);   % A list of the number of running job per worker   
    news_worker   = repmat({''},[opt.max_queued,1]); % a list to store the news of all workers
    flag_point    = false; % A flag to indicate if a . was verbosed last
    %% Find the longest job name
    lmax = 0;
    for num_j = 1:length(list_jobs)
        lmax = max(lmax,length(list_jobs{num_j}));
    end
    
    %% Start submitting jobs
    while (any(mask_todo) || any(mask_running)) && psom_exist(file_pipe_running)

        %% Check for workers that have been reset
        for num_w = 1:opt.max_queued
            worker_reset(num_w) = psom_exist(file_worker_reset{num_w});
            if worker_reset(num_w)
                if opt.flag_verbose == 2
                    fprintf('Worker %i has been reset.\n');
                end
                psom_clean(file_worker_reset{num_w});
                nb_running = nb_running - sum(mask_running(psom_plan==num_w));
                mask_running(psom_plan==num_w) = false;
                mask_todo(psom_plan==num_w) = true;
                nb_todo = nb_todo + sum(psom_plan==num_w);
                nb_run_worker(num_w) = 0;
                psom_plan(psom_plan==num_w) = 0;
            end 
        end
        
        %% Check the state of workers
        %% and read the news
        flag_nothing_happened = true;
        for num_w = 1:opt.max_queued
            if psom_exist(file_worker_heart{num_w})
                if nb_run_worker(num_w)==Inf
                    nb_run_worker(num_w) = 0;
                end
                
                %% Parse news_feed.csv for one worker
                [str_read,nb_char_news(num_w)] = sub_tail(file_worker_news{num_w},nb_char_news(num_w));
                news_worker{num_w} = [news_worker{num_w} str_read];
                [event_worker,news_worker{num_w}] = sub_parse_news(news_worker{num_w});
                
                %% Check if something happened
                if length(event_worker)>1
                    flag_nothing_happened = false;
                    if flag_point 
                        fprintf('\n')
                    end
                    flag_point = false;                    
                end
                
                %% Some verbose for the events
                for num_e = 1:size(event_worker,1)
                    %% Update status
                    mask_job = strcmp(list_jobs,event_worker{num_e,1});
                    if ~any(mask_job)
                        if opt.flag_verbose == 2
                            fprintf('Could not parse the following event:\n')
                            event_worker(num_e,:)
                        end
                        continue
                    end
                    name_job = list_jobs{mask_job};
                    switch event_worker{num_e,2}
                        case 'submitted'
                            nb_running = nb_running+1;
                            nb_todo = nb_todo-1;
                            msg = sprintf('%s %s%s running  ',datestr(clock),name_job,repmat(' ',[1 lmax-length(name_job)]));
                        case 'failed'
                            nb_run_worker(num_w) = nb_run_worker(num_w)-1;
                            nb_running = nb_running-1;
                            nb_failed = nb_failed+1;
                            mask_running(mask_job) = false;
                            mask_failed(mask_job) = true;
                            % Remove the children of the failed job from the to-do list
                            mask_child = sub_find_children(mask_job',graph_deps);
                            mask_todo(mask_child) = false; 
                            psom_plan(mask_job) = 0;
                            msg = sprintf('%s %s%s failed   ',datestr(clock),name_job,repmat(' ',[1 lmax-length(name_job)]));
                        case 'finished'
                            nb_run_worker(num_w) = nb_run_worker(num_w)-1;
                            nb_running = nb_running-1;
                            nb_finished = nb_finished+1;
                            mask_running(mask_job) = false;
                            mask_finished(mask_job) = true;
                            graph_deps(mask_job,:) = false;
                            psom_plan(mask_job) = 0;
                            msg = sprintf('%s %s%s finished ',datestr(clock),name_job,repmat(' ',[1 lmax-length(name_job)]));
                    end
                    %% Add to the news feed
                    sub_add_line_log(hf_news,sprintf('%s , %s\n',event_worker{num_e,1},event_worker{num_e,2}),false);
                    if opt.flag_verbose
                        fprintf('%s (%i run / %i fail / %i done / %i left)\n',msg,nb_running,nb_failed,nb_finished,nb_todo);
                    end
                end
            else
                nb_run_worker(num_w) = Inf; % The worker is not ready. Mark infinite number of jobs running to ensure no new submission will occur.
            end    
        end
               
        %% Update the dependency mask
        if ~flag_nothing_happened
            mask_deps = max(graph_deps,[],1)>0;
            mask_deps = mask_deps(:);
        end
        
        %% Time to (try to) submit jobs !!
        list_num_to_run = find(mask_todo&~mask_deps);
        mask_new_submit = false(opt.max_queued,1);
        tag = [];
        curr_job = 1;
        while (min(nb_run_worker)<opt.max_buffer)&&(curr_job<=length(list_num_to_run))
            [val,ind] = min(nb_run_worker);
            pipe_sub = struct;
            pipe_sub.(list_jobs{list_num_to_run(curr_job)}) = pipeline.(list_jobs{list_num_to_run(curr_job)});
            save(file_worker_job{ind},'-append','-struct','pipe_sub');
            mask_new_submit(ind) = true;
            nb_run_worker(ind) = nb_run_worker(ind)+1;
            mask_running(list_num_to_run(curr_job)) = true;
            mask_todo(list_num_to_run(curr_job)) = false;
            psom_plan(list_num_to_run(curr_job)) = ind;
            curr_job = curr_job+1;
        end
        
        %% Mark new submissions as ready to process
        for num_w = 1:opt.max_queued
            if mask_new_submit(num_w)
                flag_nothing_happened = false;
                save(file_worker_ready{num_w},'tag');
            end
        end
        
        if flag_nothing_happened && (any(mask_todo) || any(mask_running)) && psom_exist(file_pipe_running)
            sub_sleep(opt.time_between_checks)
         
            if (nb_checks >= opt.nb_checks_per_point)
                nb_checks = 0;
                if opt.flag_verbose
                    fprintf('.');
                    flag_point = true;
                end
                nb_checks = nb_checks+1;
            else
                nb_checks = nb_checks+1;
            end
        end
    end % While there are jobs to do
    
catch
    
    errmsg = lasterror;        
    fprintf('\n\n******************\nSomething went bad ... the pipeline has FAILED !\nThe last error message occured was :\n%s\n',errmsg.message);
    if isfield(errmsg,'stack')
        for num_e = 1:length(errmsg.stack)
            fprintf('File %s at line %i\n',errmsg.stack(num_e).file,errmsg.stack(num_e).line);
        end
    end
    if exist('file_pipe_running','var')
        if exist(file_pipe_running,'file')
            delete(file_pipe_running); % remove the 'running' tag
        end
    end
    
    %% Close the log file
    if strcmp(gb_psom_language,'matlab')
        fclose(hf_news);
    end
    status_pipe = 1;
    return
end

%% Print general info about the pipeline
msg_line1 = sprintf('Pipeline terminated on %s',datestr(now));
stars = repmat('*',[1 length(msg_line1)]);
if opt.flag_verbose
    fprintf('%s\n%s\n',stars,msg_line1);
end

%% Report if the lock file was manually removed
if exist('file_pipe_running','var')&&~psom_exist(file_pipe_running)
    fprintf('The pipeline manager was interrupted because the .lock file was manually deleted.\n');
end

%% Print a list of failed jobs
list_num_failed = find(mask_failed);
list_num_failed = list_num_failed(:)';
flag_any_fail = ~isempty(list_num_failed);

if flag_any_fail
    if length(list_num_failed) == 1
        fprintf('1 job has failed.\n',length(list_num_failed));
    else
        fprintf('%i jobs have failed.\n',length(list_num_failed));
    end
end

%% Print a list of jobs that could not be processed
list_num_none = find(~mask_finished&~mask_failed);
list_num_none = list_num_none(:)';
if ~isempty(list_num_none)
    if length(list_num_none) == 1
        fprintf('1 job could not be processed due to failures or interruption.\n');
    else
        fprintf('%i jobs could not be processed due to failures or interruption.\n', length(list_num_none));
    end
end

%% Suggest using psom_pipeline_visu
if flag_any_fail
    fprintf('Use psom_pipeline_visu to access logs, e.g.:\n\n   psom_pipeline_visu(''%s'',''log'',''%s'')\n',path_logs,list_jobs{list_num_failed(1)});
end

%% Give a final one-line summary of the processing
if ~flag_any_fail&&isempty(list_num_none)
    fprintf('All jobs have been successfully completed.\n');
end

%% Close the log file
if strcmp(gb_psom_language,'matlab')
    fclose(hf_news);
end
status_pipe = double(flag_any_fail);

%% Terminate the pipeline
if exist('file_pipe_running','var')
    if exist(file_pipe_running,'file')
        delete(file_pipe_running); % remove the 'running' tag
    end
end

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
if isempty(news)
    events = {};
    return
end

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
    pos = strfind(news_line{num_e},' , ');
    events{num_e,1} = news_line{num_e}(1:pos-1);
    events{num_e,2} = news_line{num_e}(pos+3:end);
end