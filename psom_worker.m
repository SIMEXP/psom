function status_pipe = psom_worker(path_worker,flag)
% Execute jobs.
%
% status = psom_worker( path_worker , [flag_heartbeat] )
%
% PATH_WORKER (string) The name of a path where all logs will be saved.
% FLAG.HEARTBEAT (boolean, default false) if the flag is true, then a new 
%   subprocess will be started , using matlab or octave, that will generate 
%   a heartbeat.mat file updated every 5 seconds. This subprocess will 
%   also detect the presence of a kill file and, if detected, this file will 
%   kill the worker. 
% FLAG.SPAWN (boolean, default false) if FLAG_RESPAWN is true, the pipeline process
%   will not stop until PIPE.lock is removed. It will constantly screen for
%   new jobs in the form of a .mat file where each variable is a job. 
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

%% SYNTAX
if ~exist('path_worker','var')
    error('SYNTAX: status_pipe = psom_worker(path_worker,flag). Type ''help psom_worker'' for more info.')
end

if ~ischar(path_worker)
    error('PATH_WORKER should be a string (name of a path)')
end

if ~strcmp(path_worker(end),filesep)
    path_worker = [path_worker filesep];
end

%% Options
if nargin < 2
    flag = struct;
end
flag = psom_struct_defaults( flag , ...
       { 'heartbeat' , 'spawn' } , ...
       { false       , false   });
       
%% Generating file names
file_heartbeat = [path_worker filesep 'heartbeat.mat'];
file_kill      = [path_worker filesep 'worker.kill'];
file_news_feed = [path_worker filesep 'news_feed.csv'];
file_pipe      = [path_worker filesep 'PIPE_jobs.mat'];
file_lock      = [path_worker filesep 'PIPE.lock'];

%% Start a heartbeat
if flag.heartbeat
    main_pid = getpid;
    cmd = sprintf('psom_heartbeat(''%s'',''%s'',%i)',file_heartbeat,file_kill,main_pid);
    if strcmp(gb_psom_language,'octave')
        instr_heartbeat = sprintf('"%s" %s "addpath(''%s''), %s,exit"',gb_psom_command_octave,gb_psom_opt_matlab,gb_psom_path_psom,cmd);
    else 
        instr_heartbeat = sprintf('"%s" %s "addpath(''%s''), %s,exit"',gb_psom_command_matlab,gb_psom_opt_matlab,gb_psom_path_psom,cmd);
    end 
    system([instr_heartbeat '&']);
end

%% Load jobs
if psom_exist( file_pipe )
    pipeline = load(file_pipe);
    list_jobs = fieldnames(pipeline);
else
    pipeline = struct;
    list_jobs = {};
end

% a try/catch block is used to crash gracefully if the user is
% interrupting the pipeline of if an error occurs
try    
    %% Open the news feed file
    hfnf = fopen(file_news_feed,'w');
    test_loop = true;
    num_job = 0;
    flag_any_fail = false;
    while test_loop

        %% Check for new spawns
        if flag.spawn
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
                    list_jobs = [ list_jobs ; list_new_jobs ];
                    pipeline = psom_merge_pipeline(pipeline,spawn);
                    psom_clean({file_spawn,[path_spawn list_ready{num_r}]});
                end
            end
        end
            
        %% If there are jobs to run
        if num_job < length(list_jobs)
            num_job = num_job + 1;
            name_job = list_jobs{num_job};
            
            %% Add to the news feed
            fprintf(hfnf,'%s , submitted\n',name_job);
            
            %% Execute the job in a "shelled" environment
            flag_failed = psom_run_job(pipeline.(name_job),path_worker,name_job);    
            
            %% Update the news feed
            if flag_failed
                fprintf(hfnf,'%s , failed\n',name_job);
                flag_any_fail = true;
            else
                fprintf(hfnf,'%s , finished\n',name_job);
            end
        end 
        
        if flag.spawn
            test_loop = true;
            if num_job == length(list_jobs)
                if exist('OCTAVE_VERSION','builtin')  
                    [res,msg] = system('sleep 0.1');
                else
                    sleep(0.1); 
                end
            end
        else
            test_loop = (num_job<length(list_jobs));
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
    
    %% Close the log file
    fprintf(hfnf,'PIPE , crashed\n');
    fclose(hfnf)
    status_pipe = 1;
    return
end

%% Close the news feed
fprintf(hfnf,'PIPE , terminated\n');
fclose(hfnf);
status_pipe = double(flag_any_fail);