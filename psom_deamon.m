function status_pipe = psom_deamon(path_logs,opt)
% Start workers, a pipeline manager and a garbage collector
%
% status = psom_deamon(path_logs,opt)
%
% PATH_LOGS 
%   (string) the path name to a logs folder.
%
% OPT
%   (structure) with the following fields :
%
%   MODE
%      (string, default GB_PSOM_MODE defined in PSOM_GB_VARS)
%      how to start the workers:
%      'background' : background execution, not-unlogin-proofed 
%                     (asynchronous system call).
%      'batch'      : background execution, unlogin-proofed ('at' in 
%                     UNIX, start in WINDOWS).
%      'qsub'       : remote execution using qsub (torque, SGE, PBS).
%      'msub'       : remote execution using msub (MOAB)
%      'bsub'       : remote execution using bsub (IBM)
%      'condor'     : remote execution using condor
%
%   MAX_QUEUED
%      (integer, default GB_PSOM_MAX_QUEUED defined in PSOM_GB_VARS)
%      The maximum number of jobs that can be processed
%      simultaneously. Some qsub systems actually put restrictions
%      on that. Contact your local system administrator for more info.
%
%   NB_RESUB
%      (integer, default 0 in 'session', 'batch' and 'background' modes,
%      1 otherwise) The number of times a worker will be resubmitted if it 
%      fails.
%
%   SHELL_OPTIONS
%      (string, default GB_PSOM_SHELL_OPTIONS defined in PSOM_GB_VARS)
%      some commands that will be added at the begining of the shell
%      script submitted to batch or qsub. This can be used to set
%      important variables, or source an initialization script.
%
%   QSUB_OPTIONS
%      (string, GB_PSOM_QSUB_OPTIONS defined in PSOM_GB_VARS)
%      This field can be used to pass any argument when submitting a
%      job with bsub/msub/qsub. For example, '-q all.q@yeatman,all.q@zeus' will
%      force qsub to only use the yeatman and zeus workstations in the
%      all.q queue. It can also be used to put restrictions on the
%      minimum avalaible memory, etc.
%
%   COMMAND_MATLAB
%      (string, default GB_PSOM_COMMAND_MATLAB or
%      GB_PSOM_COMMAND_OCTAVE depending on the current environment,
%      defined in PSOM_GB_VARS)
%      how to invoke matlab (or OCTAVE).
%      You may want to update that to add the full path of the command.
%      The defaut for this field can be set using the variable
%      GB_PSOM_COMMAND_MATLAB/OCTAVE in the file PSOM_GB_VARS.
%
%   INIT_MATLAB
%      (string, GB_PSOM_INIT_MATLAB defined in PSOM_GB_VARS) a matlab 
%      command (multiple commands can actually be passed using comma 
%      separation) that will be executed at the begining of any 
%      matlab/Octave job.
%
%   PATH_SEARCH
%      (string, default GB_PSOM_PATH_SEARCH in the file PSOM_GB_VARS). 
%      If PATH_SEARCH is empty, the current path is used. If 
%      PATH_SEARCH equals 'gb_psom_omitted', then PSOM will not attempt 
%      to set the search path, i.e. the search path for every job will 
%      be the current search path in 'session' mode, and the default 
%      Octave/Matlab search path in the other modes. 
%
%   FLAG_VERBOSE
%      (integer 0, 1 or 2, default 1) No verbose (0), standard 
%      verbose (1), a lot of verbose, useful for debugging (2).
%
%   There are actually other minor options available, see
%   PSOM_PIPELINE_INIT and PSOM_PIPELINE_PROCESS for details.
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
   {  'nb_resub' , 'flag_verbose' , 'init_matlab' , 'shell_options' , 'command_matlab' , 'mode' , 'max_queued' , 'qsub_options' , 'time_between_checks' , 'nb_checks_per_point' , 'time_cool_down' };
   {  NaN        , 1              , NaN           , NaN             , NaN              , NaN    , NaN          , NaN            , NaN                   , NaN                   , NaN              };
psom_set_defaults

%% File names
file_pipeline     = [path_logs 'PIPE.mat'];
file_jobs         = [path_logs 'PIPE_jobs.mat'];
file_pipe_running = [path_logs 'PIPE.lock'];
file_heartbeat    = [path_logs 'heartbeat.mat'];
file_kill         = [path_logs 'PIPE.kill'];
path_worker       = [path_logs 'worker' filesep];
for num_w = 1:opt.max_queued
    file_worker_heart{num_w} = sprintf('%spsom%i%sheartbeat.mat',path_worker,num_w,filesep);
    file_worker_kill{num_w}  = sprintf('%spsom%i%sworker.kill',path_worker,num_w,filesep);
end

%% Check for the existence of the pipeline
if ~exist(file_pipeline,'file') % Does the pipeline exist ?
    error('Could not find the pipeline file %s. Please use psom_run_pipeline instead of psom_deamon directly.',file_pipeline);
end

%% Create a running tag on the pipeline (if not done during the initialization phase)
if ~psom_exist(file_pipe_running)
    str_now = datestr(clock);
    save(file_pipe_running,'str_now');
end

% a try/catch block is used to clean temporary file if the user is
% interrupting the pipeline of if an error occurs
try    
       
    %% Print general info about the pipeline
    msg_line1 = sprintf('Deamon started on %s',datestr(clock));
    msg_line2 = sprintf('user: %s, host: %s, system: %s',gb_psom_user,gb_psom_localhost,gb_psom_OS);
    stars = repmat('*',[1 max(length(msg_line1),length(msg_line2))]);
    fprintf('%s\n%s\n%s\n%s\n',stars,msg_line1,msg_line2,stars);
    
    %% Track refresh times for workers
    % (#workers + manager + garbage collector) x 6 (clock info) x 2
    % the first table is to record the last documented active time for the heartbeat
    % the second table is to record the time elapsed since a new heartbeat was detected
    tab_refresh(:,:,1) = -ones(opt.max_queued+2,6);
    tab_refresh(:,:,2) = repmat(clock,[opt.max_queued+2 1]);
    
    %% Initialize miscallenaous variables
    nb_resub    = 0;                   % Number of resubmission               
    nb_checks   = 0;                   % Number of checks to print a points
    nb_points   = 0;                   % Number of printed points
    flag_pipe_running = false;         % Is the pipeline started?
    flag_pipe_finished = false;        % Is the pipeline finished?
    flag_worker_alive = repmat(NaN,[opt.max_queued+2 1]); % Is the worker alive? two last entries are for the PM and the GC
    
    %% Create logs folder for each worker
    for num_w = 1:opt.max_queued
        path_worker_w = sprintf('%spsom%i%s',path_worker,num_w,filesep);
        psom_mkdir(path_worker_w)
    end
    
    %% General options to submit scripts
    opt_script.path_search    = file_pipeline;
    opt_script.mode           = opt.mode;
    opt_script.init_matlab    = opt.init_matlab;
    opt_script.flag_debug     = opt.flag_verbose == 2;        
    opt_script.shell_options  = opt.shell_options;
    opt_script.command_matlab = opt.command_matlab;
    opt_script.qsub_options   = opt.qsub_options;
    
    %% Options for submission of the pipeline manager
    opt_logs_pipe.txt    = [path_logs 'PIPE_history.txt'];
    opt_logs_pipe.eqsub  = [path_logs 'PIPE.eqsub'];
    opt_logs_pipe.oqsub  = [path_logs 'PIPE.oqsub'];
    opt_logs_pipe.failed = [path_logs 'PIPE.failed'];
    opt_logs_pipe.exit   = [path_logs 'PIPE.exit'];   
    opt_pipe = opt_script;
    opt_pipe.name_job = 'psom_manager';   
    cmd_pipe = sprintf('opt.max_queued = %i; opt.time_between_checks = %1.2f; opt.nb_checks_point = %i; psom_manager(''%s'',opt);',opt.max_queued,opt.time_between_checks,opt.nb_checks_per_point,path_logs);    
    if ispc % this is windows
        script_pipe = [path_tmp filesep 'psom_manager.bat'];
    else
        script_pipe = [path_tmp filesep 'psom_manager.sh'];
    end
    
    %% Options for submission of the workers
    for num_w = 1:opt.max_queued
        opt_logs_worker(num_w).txt    = sprintf('%spsom%i%sworker.log',path_worker);
        opt_logs_worker(num_w).eqsub  = sprintf('%spsom%i%sworker.eqsub',path_worker);
        opt_logs_worker(num_w).oqsub  = sprintf('%spsom%i%sworker.oqsub',path_worker);
        opt_logs_worker(num_w).failed = sprintf('%spsom%i%sworker.failed',path_worker);
        opt_logs_worker(num_w).exit   = sprintf('%spsom%i%sworker.exit',path_worker);   
        opt_worker = opt_script;
        opt_worker.name_job = sprintf('psom%i',num_w);   
        cmd_worker = sprintf('flag.heartbeat = true; flag.spawn = true; psom_worker(''%s'',flag);',path_worker_w{num_w});
        if ispc % this is windows
            script_worker = [path_tmp filesep opt_worker.name_job '.bat'];
        else
            script_worker = [path_tmp filesep opt_worker.name_job '.sh'];
        end
    end
    
    %% Start submitting jobs
    while ~flag_pipe_finished 
    
        %% Start the pipeline manager
        flag_pipe_running = psom_exist(file_pipe_running);
        if ~flag_pipe_running || (~flag_worker_alive(end-1)&&(nb_resub < opt.nb_resub)
            [flag_failed,msg] = sub_run_script(cmd_pipe,script_pipe,opt_pipe,opt_logs_pipe,opt.flag_verbose);
            if flag_pipe_running
                nb_resub = nb_resub+1;
                tab_refresh(end-1,:,1) = -1;
                flag_worker_alive(end-1) = NaN;
            end
            %% Wait for the pipeline manager to start
            while ~psom_exist(file_pipe_running)
                fprintf('Waiting for the pipeline manager to start...')
                sub_sleep(opt.time_between_checks)
            end
            flag_pipe_running = true;
        end
    
        %% Check the heartbeats
        for num_w = 1:(opt.max_queued+2)
        
            %% Check for the presence of the heartbeat
            if num_w <= opt.max_queued
                flag_heartbeat = psom_exist(file_worker_heart{num_w});
            elseif num_w == opt.max_queued+1
                flag_heartbeat = psom_exist(file_heartbeat);
            elseif num_w == opt.max_queued+2
                flag_heartbeat = psom_exist(file_heartbeat);
            end
            
            if flag_heartbeat
                if any(tab_refresh(num_w,:,1)<0)
                    % this is the first time an active time is collected
                    % simply update tab_refresh
                    tab_refresh(num_w,:,1) = 0;
                else
                    try
                        refresh_time = load(file_heartbeat);
                        test_change = etime(refresh_time.curr_time,tab_refresh(num_w,:,1))>1;
                    catch
                        % The heartbeat is unreadable
                        % Assume this is a race condition
                        % Consider no heartbeat was detected
                        test_change = false;
                    end

                    if test_change
                        % I heard a heartbeat!    
                        tab_refresh(num_w,:,1) = refresh_time.curr_time;
                        tab_refresh(num_w,:,2) = clock;
                        flag_worker_alive(num_w) = true;
                    else 
                        % how long has it been without a heartbeat?
                        elapsed_time = etime(clock,tab_refresh(num_w,:,2));
                        if elapsed_time > 30
                            % huho 30 seconds without a heartbeat, he's dead Jim
                            flag_worker_alive(num_w) = false;
                        else
                            flag_worker_alive(num_w) = true;
                        end
                end
            end
        end
        
        %% Now start workers
        for num_w = 1:opt.max_queued
            if isnan(flag_worker_alive(num_w)) || (~flag_worker_alive(num_w)&&(nb_resub<opt.nb_resub))
                opt_script.name_job = sprintf('psom%i',num_w);
                cmd = sprintf('flag.heartbeat = true; flag.spawn = true; psom_worker(''%s'',flag);',path_worker_w{num_w});
                if ~isnan(flag_worker_alive(num_w)
                    tab_refresh(num_w,:,1) = -1;
                    flag_worker_alive(num_w) = NaN;
                    nb_resub = nb_resub+1;
                end
            end
        end
        psom_sleep(opt.time_between_checks*10)
        flag_pipe_finished = ~isnan(flag_worker_alive(end-1))&&~psom_exist(file_pipe_running);
    end
    
catch
    
    errmsg = lasterror;        
    fprintf('\n\n******************\nSomething went bad ... the PSOM deamon has FAILED !\nThe last error message occured was :\n%s\n',errmsg.message);
    if isfield(errmsg,'stack')
        for num_e = 1:length(errmsg.stack)
            fprintf('File %s at line %i\n',errmsg.stack(num_e).file,errmsg.stack(num_e).line);
        end
    end
    status_pipe = 1;
    return
end

%% Print general info about the pipeline
msg_line1 = sprintf('Deamon terminated on %s',datestr(now));
stars = repmat('*',[1 length(msg_line1)]);
fprintf('%s\n%s\n',stars,msg_line1);

status_pipe = 0;

%%%%%%%%%%%%%%%%%%
%% subfunctions %%
%%%%%%%%%%%%%%%%%%

%% Find the children of a job
function mask_child = sub_find_children(mask,graph_deps)
% GRAPH_DEPS(J,K) == 1 if and only if JOB K depends on JOB J. GRAPH_DEPS =
% 0 otherwise. This (ugly but reasonably fast) recursive code will work
% only if the directed graph defined by GRAPH_DEPS is acyclic.
% MASK_CHILD(num_w) == 1 if the job num_w is a children of one of the job
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

function [] = sub_run_script(cmd,script,opt,opt_logs,flag_verbose);
[flag_failed,errmsg] = psom_run_script(cmd,script,opt,opt_logs);
if flag_failed~=0
    fprintf('\n    The execution of the job %s failed.\n The feedback was : %s\n',name_job,errmsg);
    error('Something went bad with the execution of the job.')
elseif flag_verbose == 2
    fprintf('\n    The feedback from the execution of job %s was : %s\n',name_job,errmsg);
end    