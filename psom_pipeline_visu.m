function [] = psom_pipeline_visu(file_pipeline,action,opt_action)
%
% _________________________________________________________________________
% SUMMARY OF PSOM_PIPELINE_VISU
%
% Monitor the execution of a pipeline
%
% SYNTAX:
% [] = PSOM_PIPELINE_VISU(FILE_PIPELINE,ACTION)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_PIPELINE  
%       (string) The file name of a .MAT file generated using 
%       PSOM_PIPELINE_INIT.
%               
% ACTION         
%       (string) Possible values :
%           'submitted', 'running', 'failed', 'finished', 'none', 'log',
%           'graph_stages',
%           
% OPT           
%       (string) see action 'log'.
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
%       Print the log files for all jobs whose name include the string OPT.
%
% ACTION = 'monitor'
%       Print (with updates) the last line of the pipeline execution.
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
% Keywords : medical imaging, pipeline, fMRI, PMP

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
if ~exist('file_pipeline','var') || ~exist('action','var')
    error('SYNTAX: [] = PSOM_PIPELINE_VISU(FILE_PIPELINE,ACTION,OPT). Type ''help psom_pipeline_visu'' for more info.')
end

%% get status 
[path_logs,name_pipeline] = fileparts(file_pipeline);
file_status = [path_logs filesep name_pipeline '_status.mat'];
load(file_status,'job_status')
load(file_pipeline,'list_jobs');

switch action
    
    case {'finished','failed','none','running','submitted'}                

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
        
        load(file_pipeline,'graph_deps','list_jobs');        
        bg = biograph(graph_deps,list_jobs);
        dolayout(bg);
        view(bg);
        
    case 'monitor'
        
        file_monitor = [path_logs filesep name_pipeline '.log'];
        file_pipe_running = [path_logs filesep name_pipeline '.running'];
        
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
        system(sprintf('tail -f %s',file_monitor));
        
    case 'log'

        curr_status = psom_job_status(path_logs,opt_action)
        mask_jobs = ismember(curr_status,{'finished','failed','running'});
        jobs_action = list_jobs(mask_jobs);
        
        if max(mask_jobs) == 0
            
            msg = sprintf('  Could not find any log fitting the filter ''*%s*''  ',opt_action);
            stars = repmat('*',size(msg));
            fprintf('\n\n%s\n%s\n%s\n\n',stars,msg,stars);

        else

            for num_j = 1:length(jobs_action)

                name_job = jobs_action{num_j};
                file_log = [path_logs filesep name_job '.log'];
                msg = sprintf('  Log file of job %s  ',name_job);
                stars = repmat('*',size(msg));
                fprintf('\n\n%s\n%s\n%s\n\n',stars,msg,stars);
                hf = fopen(file_log,'r');
                str_log = fread(hf,Inf,'uint8=>char');
                fclose(hf);
                fprintf('%s\n',str_log)

            end
        end

    otherwise

        error('psom:pipeline: unknown action %s',action);
        
end