function [] = psom_pipeline_visu(path_logs,action,opt_action)
%
% _________________________________________________________________________
% SUMMARY OF PSOM_PIPELINE_VISU
%
% Display various information on a pipeline.
%
% SYNTAX:
% [] = PSOM_PIPELINE_VISU(PATH_LOGS,ACTION,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_LOGS 
%       (string) The path of the pipeline logs
%               
% ACTION         
%       (string) Possible values :
%
%           'submitted', 'running', 'failed', 'finished', 'none'
%               List the jobs that have this status.
%
%           'monitor'
%               Monitor the execution of the pipeline.
%               
%           'log'
%               Display the log of one job.
%
%           'graph_stages'
%               Draw the graph of dependencies of the pipeline.
%              
%           
% OPT           
%       (string) see the following notes on action 'log'.
%
% _________________________________________________________________________
% OUTPUTS:
% 
% What the function does depends on the argument ACTION :
%
% ACTION = 'submitted'
%       Display a list of the jobs of the pipeline that are scheduled in 
%       the queue but not currently running.
%
% ACTION = 'running'
%       Display a list of the jobs of the pipeline that are currently 
%       running 
%
% ACTION = 'failed'
%       Display a list of the jobs of the pipeline that have failed.
%
% ACTION = 'finished'
%       Display a list of finished jobs of the pipeline.
%
% ACTION = 'none'
%       Display a list of jobs without tag (no attempt has been made to
%       process the job).
%
% ACTION = 'log'
%       Print (with updates) the log files for the job OPT.
%
% ACTION = 'monitor'
%       Print (with updates) the pipeline master log.
%
% ACTION = 'graph_stages'
%       Represent the dependency graph between jobs.  
%
% _________________________________________________________________________
% SEE ALSO:
%
% PSOM_PIPELINE_INIT, PSOM_PIPELINE_PROCESS, PSOM_RUN_PIPELINE, 
% PSOM_DEMO_PIPELINE
%
% _________________________________________________________________________
% COMMENTS:
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
if ~exist('path_logs','var') || ~exist('action','var')
    error('SYNTAX: [] = PSOM_PIPELINE_VISU(PATH_LOGS,ACTION,OPT). Type ''help psom_pipeline_visu'' for more info.')
end

%% Get status 
file_pipeline = [path_logs 'PIPE.mat'];
name_pipeline = 'PIPE';
file_status = [path_logs filesep name_pipeline '_status.mat'];
file_logs = [path_logs filesep name_pipeline '_logs.mat'];
load(file_pipeline,'list_jobs');
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


switch action
    
    case {'finished','failed','none','running','submitted'}                

        %% List the jobs that have a specific status
        
        mask_jobs = ismember(job_status,action);
        jobs_action = list_jobs(mask_jobs);

        if isempty(jobs_action)
            msg = sprintf('There is currently no %s job',action);
        else
            msg = sprintf('List of %s job(s)',action);
        end
        
        stars = repmat('*',size(msg));
        fprintf('\n\n%s\n%s\n%s\n\n',stars,msg,stars);
        
        for num_j = 1:length(jobs_action)
            fprintf('%s\n',jobs_action{num_j});
        end
        
    case 'graph_stages'
        
        %% Display the graph of dependencies of the pipeline
        
        load(file_pipeline,'graph_deps','list_jobs');        
        bg = biograph(graph_deps,list_jobs);
        dolayout(bg);
        view(bg);
        
    case 'monitor'
        
        %% Prints the history of the pipeline, with updates
        
        file_monitor = [path_logs filesep name_pipeline '_history.txt'];
        file_pipe_running = [path_logs filesep name_pipeline '.lock'];
        
        if exist(file_pipe_running,'file')
            msg = 'The pipeline is currently running';
        else
            msg = 'The pipeline is NOT currently running';
        end
        
        stars = repmat('*',size(msg));
        fprintf('\n\n%s\n%s\n%s\n\n',stars,msg,stars);
        
        while ~exist(file_monitor,'file') && exist(file_pipe_running,'file') % the pipeline started but the log file has not yet been created
            
            fprintf('I could not find any log file. This pipeline has not been started (yet?). Press CTRL-C to cancel.\n');
            pause(1)
            
        end
        
        sub_tail(file_monitor,file_pipe_running);
        
    case 'log'

        %% Prints the log of one job 
        
        ind_job =  find(ismember(list_jobs,opt_action));
        
        if isempty(ind_job)
            error('%s : is not a job of this pipeline.',opt_action);                    
        end

        curr_status = job_status{ind_job};
        
        msg = sprintf('  Log file of job %s (status %s) ',opt_action,curr_status);
        stars = repmat('*',size(msg));
        fprintf('\n\n%s\n%s\n%s\n\n',stars,msg,stars);
        
        
        if strcmp(curr_status,'running');
            
            file_job_log = [path_logs opt_action '.log'];
            file_job_running = [path_logs opt_action '.running'];
            sub_tail(file_job_log,file_job_running);
            
        else
            
            load(file_logs,opt_action);
            eval(['fprintf(''%s'',',opt_action,');']);
        
        end            

    otherwise

        error('psom:pipeline: unknown action %s',action);
        
end

%%%%%%%%%%%%%%%%%%%
%% sub-functions %%
%%%%%%%%%%%%%%%%%%%

function [] = sub_tail(file_read,file_running,time_pause)

% prints out the content of the text file FILE_READ with constant updates
% as long as the file FILE_RUNNING exists. TIME_PAUSE (default 0.5) is the
% time between two prints.

if nargin < 3
    time_pause = 0.5;
end

hf = fopen(file_read,'r');

str_read = fread(hf, Inf, 'uint8=>char')';
fprintf('%s',str_read);
    
while exist(file_running,'file')
    str_read = fread(hf, Inf, 'uint8=>char')';
    fprintf('%s',str_read);
    pause(time_pause)
end

fclose(hf)