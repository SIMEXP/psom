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
%      (string) how to start the workers:
%      'background' : background execution, not-unlogin-proofed 
%                     (asynchronous system call).
%      'batch'      : background execution, unlogin-proofed ('at' in 
%                     UNIX, start in WINDOWS).
%      'qsub'       : remote execution using qsub (torque, SGE, PBS).
%      'msub'       : remote execution using msub (MOAB)
%      'bsub'       : remote execution using bsub (IBM)
%      'condor'     : remote execution using condor
%
%   MODE_PIPELINE_MANAGER
%      (string) same as OPT.MODE, but applies to the pipeline manager itself.
%
%   MAX_QUEUED
%      (integer) The maximum number of jobs that can be processed
%      simultaneously. Some qsub systems actually put restrictions
%      on that. Contact your local system administrator for more info.
%
%   MAX_BUFFER
%       (integer) the maximum number of jobs submitted to a worker at a 
%       given time.
%
%   NB_RESUB
%      (integer) The number of times a worker will be resubmitted if it 
%      fails.
%
%   SHELL_OPTIONS
%      (string) some commands that will be added at the begining of the 
%      shell script submitted to batch or qsub. This can be used to set
%      important variables, or source an initialization script.
%
%   QSUB_OPTIONS
%      (string) This field can be used to pass any argument when submitting a
%      job with bsub/msub/qsub. For example, '-q all.q@yeatman,all.q@zeus' will
%      force qsub to only use the yeatman and zeus workstations in the
%      all.q queue. It can also be used to put restrictions on the
%      minimum avalaible memory, etc.
%
%   COMMAND_MATLAB
%      (string) how to invoke matlab (or OCTAVE).
%      You may want to update that to add the full path of the command.
%      The defaut for this field can be set using the variable
%      GB_PSOM_COMMAND_MATLAB/OCTAVE in the file PSOM_GB_VARS.
%
%   INIT_MATLAB
%      (string) a matlab command (multiple commands can actually be 
%      passed using comma separation) that will be executed at the begining 
%      of any matlab/Octave job.
%
%   TIME_BETWEEN_CHECKS
%
%   NB_CHECKS_PER_POINT
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
   {  'mode_pipeline_manager' , 'nb_resub' , 'flag_verbose' , 'init_matlab' , 'shell_options' , 'command_matlab' , 'mode' , 'max_queued' , 'max_buffer' , 'qsub_options' , 'time_between_checks' , 'nb_checks_per_point' }, ...
   {  NaN                     , NaN        , 1              , NaN           , NaN             , NaN              , NaN    , NaN          , NaN          , NaN            , NaN                   , NaN                   });

if ~strcmp(path_logs(end),filesep)
    path_logs = [path_logs filesep];
end

%% Constants
time_death = 10; % Time before a worker is considered dead

%% File names
file_pipeline     = [path_logs 'PIPE.mat'];
file_pipe_running = [path_logs 'PIPE.lock'];
file_kill         = [path_logs 'PIPE.kill'];
file_time         = [path_logs 'PIPE_time.mat'];
path_tmp          = [path_logs 'tmp' filesep];
path_worker       = [path_logs 'worker' filesep];
path_garbage      = [path_logs 'garbage' filesep];
for num_w = 1:opt.max_queued
    name_worker{num_w} = sprintf('psom%i',num_w);
    file_worker_heart{num_w} = [path_worker name_worker{num_w} filesep 'heartbeat.mat'];
    file_worker_reset{num_w} = [path_worker name_worker{num_w} filesep 'worker.reset'];
    file_worker_end{num_w}   = [path_worker name_worker{num_w} filesep 'worker.end'];
end
name_worker{opt.max_queued+1} = 'psom_manager';
file_worker_heart{opt.max_queued+1} = [path_logs 'heartbeat.mat'];
name_worker{opt.max_queued+2} = 'psom_garbage';
file_worker_heart{opt.max_queued+2} = [path_garbage 'heartbeat.mat'];
psom_mkdir(path_tmp);

%% Check for the existence of the pipeline
if ~exist(file_pipeline,'file') % Does the pipeline exist ?
    error('Could not find the pipeline file %s. Please use psom_run_pipeline instead of psom_deamon directly.',file_pipeline);
end

%% Save the time
time_pipeline = datestr(clock);
save(file_time,'time_pipeline');

% a try/catch block is used to clean temporary file if the user is
% interrupting the pipeline of if an error occurs
try    
       
    %% Print general info about the pipeline
    if opt.flag_verbose
        fprintf('Deamon started on %s\n',datestr(clock));
    end
    
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
    nb_chars_logs = 0;                 % Number of characters printed from the pipeline history                
    flag_pipe_running  = false;        % Is the pipeline started?
    flag_pipe_finished = false;        % Is the pipeline finished?
    flag_started = false([opt.max_queued+2 1]); % Has the worker ever started? two last entries are for the PM and the GC
    flag_alive   = false([opt.max_queued+2 1]); % Is the worker alive? two last entries are for the PM and the GC
    flag_wait    = false([opt.max_queued+2 1]); % Are we waiting for the worker to start? two last entries are for the PM and the GC
    flag_end     = false([opt.max_queued 1]);   % did the manager request for the worker to end?
    
    %% Create logs folder for each worker
    path_worker_w = cell(opt.max_queued,1);
    for num_w = 1:opt.max_queued
        path_worker_w{num_w} = sprintf('%spsom%i%s',path_worker,num_w,filesep);
        if psom_exist(path_worker_w{num_w})
            psom_clean(path_worker_w{num_w},struct('flag_verbose',false));
        end
        psom_mkdir(path_worker_w{num_w});
    end
    
    %% General options to submit scripts
    opt_script.path_search    = file_pipeline;
    opt_script.mode           = opt.mode;
    opt_script.init_matlab    = opt.init_matlab;
    opt_script.flag_debug     = opt.flag_verbose == 2;        
    opt_script.shell_options  = opt.shell_options;
    opt_script.command_matlab = opt.command_matlab;
    opt_script.qsub_options   = opt.qsub_options;
    opt_script.name_job       = ''; % to be specified
    
    %% Options for submission of the pipeline manager
    opt_logs_pipe.txt    = [path_logs 'PIPE_history.txt'];
    opt_logs_pipe.eqsub  = [path_logs 'PIPE.eqsub'];
    opt_logs_pipe.oqsub  = [path_logs 'PIPE.oqsub'];
    opt_logs_pipe.failed = [path_logs 'PIPE.failed'];
    opt_logs_pipe.exit   = [path_logs 'PIPE.exit'];   
    opt_pipe = opt_script;
    opt_pipe.name_job = 'psom_manager';   
    cmd_pipe = sprintf('opt.time_pipeline = ''%s''; opt.flag_verbose = %i; opt.max_buffer = %i; opt.max_queued = %i; opt.time_between_checks = %1.2f; opt.nb_checks_per_point = %i; psom_manager(''%s'',opt);',time_pipeline,opt.flag_verbose,opt.max_buffer,opt.max_queued,opt.time_between_checks,opt.nb_checks_per_point,path_logs);    
    if ispc % this is windows
        script_pipe = [path_tmp filesep 'psom_manager.bat'];
    else
        script_pipe = [path_tmp filesep 'psom_manager.sh'];
    end
    
    %% Options for submission of the garbage collector
    opt_logs_garb.txt    = [path_garbage 'garbage_history.txt'];
    opt_logs_garb.eqsub  = [path_garbage 'garbage.eqsub'];
    opt_logs_garb.oqsub  = [path_garbage 'garbage.oqsub'];
    opt_logs_garb.failed = [path_garbage 'garbage.failed'];
    opt_logs_garb.exit   = [path_garbage 'garbage.exit'];   
    opt_garb = opt_script;
    opt_garb.name_job = 'psom_garbage';   
    cmd_garb = sprintf('opt.time_pipeline = ''%s''; opt.time_between_checks = %1.2f; opt.nb_checks_per_point = %i; psom_garbage(''%s'',opt);',time_pipeline,opt.time_between_checks,opt.nb_checks_per_point,path_logs);    
    if ispc % this is windows
        script_garb = [path_tmp filesep 'psom_garbage.bat'];
    else
        script_garb = [path_tmp filesep 'psom_garbage.sh'];
    end
    
    %% Options for submission of the workers
    for num_w = 1:opt.max_queued
        opt_logs_worker(num_w).txt    = sprintf('%spsom%i%sworker.log',path_worker,num_w,filesep);
        opt_logs_worker(num_w).eqsub  = sprintf('%spsom%i%sworker.eqsub',path_worker,num_w,filesep);
        opt_logs_worker(num_w).oqsub  = sprintf('%spsom%i%sworker.oqsub',path_worker,num_w,filesep);
        opt_logs_worker(num_w).failed = sprintf('%spsom%i%sworker.failed',path_worker,num_w,filesep);
        opt_logs_worker(num_w).exit   = sprintf('%spsom%i%sworker.exit',path_worker,num_w,filesep);   
        opt_worker(num_w) = opt_script;
        opt_worker(num_w).name_job = name_worker{num_w};
        cmd_worker{num_w} = sprintf('psom_worker(''%s'',''%s'',%i,''%s'');',path_worker_w{num_w},path_logs,num_w,time_pipeline);
        if ispc % this is windows
            script_worker{num_w} = [path_tmp filesep opt_worker(num_w).name_job '.bat'];
        else
            script_worker{num_w} = [path_tmp filesep opt_worker(num_w).name_job '.sh'];
        end
    end
    
    %% Start submitting jobs
    while ~flag_pipe_finished 
    
        %% Start the pipeline manager
        flag_pipe_running = psom_exist(file_pipe_running);
        if ~flag_alive(end-1)&&(nb_resub < opt.nb_resub)
            [flag_failed,msg] = psom_run_script(cmd_pipe,script_pipe,opt_pipe,opt_logs_pipe,opt.flag_verbose);
            fprintf('Starting the pipeline manager...\n')
            if flag_started(end-1)
                nb_resub = nb_resub+1;
                tab_refresh(end-1,:,1) = -1;
            end
            %% Wait for the pipeline manager to start
            while ~psom_exist(file_pipe_running)
                sub_sleep(opt.time_between_checks)
            end
            flag_alive(end-1) = true;
            flag_pipe_running = true;
            flag_started(end-1) = true;
        end
        
        %% Start the garbage collector
        if ~flag_wait(end)&&~flag_alive(end)&&(~flag_started(end)||(nb_resub < opt.nb_resub))
            if psom_exist(path_garbage)
                psom_clean(path_garbage,struct('flag_verbose',false));
            end
            psom_mkdir(path_garbage);
            [flag_failed,msg] = psom_run_script(cmd_garb,script_garb,opt_garb,opt_logs_garb,opt.flag_verbose);
            tab_refresh(end,:,1)   = -1;
            flag_alive(end) = false;
            flag_wait(end)  = true;
            if flag_started(end)
                fprintf('Restarting the garbage collector...\n')
                nb_resub = nb_resub+1;
            else
                fprintf('Starting the garbage collector...\n')    
            end
        end
    
        %% Check the heartbeats
        for num_w = 1:(opt.max_queued+2)
        
            %% Check for the presence of the heartbeat
            flag_heartbeat = psom_exist(file_worker_heart{num_w});
            
            if ~flag_heartbeat
                if opt.flag_verbose == 2
                    fprintf('No heartbeat for process %s\n',name_worker{num_w})
                end
            else
                if any(tab_refresh(num_w,:,1)<0)
                    % this is the first time an active time is collected
                    % simply update tab_refresh
                    tab_refresh(num_w,:,1) = 0;
                    flag_started(num_w) = true;
                    if opt.flag_verbose == 2
                        fprintf('First time heartbeat for process %s\n',name_worker{num_w})
                    end
                else
                    try
                        refresh_time = load(file_worker_heart{num_w});
                        test_change = etime(refresh_time.curr_time,tab_refresh(num_w,:,1))>1;
                    catch
                        % The heartbeat is unreadable
                        % Assume this is a race condition
                        % Consider no heartbeat was detected
                        if opt.flag_verbose == 2
                            fprintf('There was a problem reading the heartbeat of process %s.\n',name_worker{num_w})
                        end
                        test_change = false;
                    end

                    if test_change
                        % I heard a heartbeat!    
                        tab_refresh(num_w,:,1) = refresh_time.curr_time;
                        tab_refresh(num_w,:,2) = clock;
                        flag_alive(num_w) = true;
                        flag_wait(num_w) = false;
                        if opt.flag_verbose == 2
                            fprintf('I heard a heartbeat for process %s\n',name_worker{num_w})
                        end
                    else 
                        % I did not hear a heartbeat
                        % how long has it been?
                        elapsed_time = etime(clock,tab_refresh(num_w,:,2));
                        if opt.flag_verbose >= 3
                            fprintf('No heartbeat in %1.2fs for process %s\n',elapsed_time,name_worker{num_w})
                        end
                        if num_w<=opt.max_queued
                            flag_worker_end = psom_exist(file_worker_end{num_w});
                        else
                            flag_worker_end = false;
                        end
                        if (elapsed_time > time_death)&&~flag_worker_end
                            if opt.flag_verbose
                                fprintf('No heartbeat for process %s, counted as dead.\n',name_worker{num_w});
                            end 
                            % huho 30 seconds without a heartbeat, he's dead Jim
                            flag_alive(num_w) = false;
                            flag_wait(num_w) = false;
                        else
                            % Not that long, just go on
                            flag_alive(num_w) = true;
                            flag_wait(num_w) = false;
                        end
                    end
                end
            end
        end
        
        %% Now start workers
        for num_w = 1:opt.max_queued
            if ~flag_end(num_w)&&~flag_wait(num_w)&&~flag_alive(num_w)&&(~flag_started(num_w)||(nb_resub<=opt.nb_resub))
                fprintf('Starting worker number %i...\n',num_w)
                if flag_started(num_w)
                    %% Cleaning the worker folder
                    psom_clean([path_worker name_worker{num_w} filesep]);
                    psom_mkdir([path_worker name_worker{num_w} filesep]);
                end
                [flag_failed,msg] = psom_run_script(cmd_worker{num_w},script_worker{num_w},opt_worker(num_w),opt_logs_worker(num_w),opt.flag_verbose);
                flag_wait(num_w) = true;
                tab_refresh(num_w,:,1) = -1;
                if flag_started(num_w)
                    nb_resub = nb_resub+1;
                    time_reset = clock;
                    save(file_worker_reset{num_w},'time_reset')
                end
            end
        end
        if opt.flag_verbose&&strcmp(opt.mode_pipeline_manager,'session')
            nb_chars_logs = psom_pipeline_visu(path_logs,'monitor',nb_chars_logs);      
        end
        sub_sleep(opt.time_between_checks)
        flag_pipe_finished = ~psom_exist(file_pipe_running);
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
if opt.flag_verbose&&strcmp(opt.mode_pipeline_manager,'session')
    nb_chars_logs = psom_pipeline_visu(path_logs,'monitor',nb_chars_logs);
end
fprintf('Deamon terminated on %s\n',datestr(now));
status_pipe = 0;

%%%%%%%%%%%%%%%%%%
%% subfunctions %%
%%%%%%%%%%%%%%%%%%
function [] = sub_sleep(time_sleep)

if exist('OCTAVE_VERSION','builtin')  
    [res,msg] = system(sprintf('sleep %1.3f',time_sleep));
else
    pause(time_sleep); 
end 