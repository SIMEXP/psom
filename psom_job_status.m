function curr_status = psom_job_status(path_logs,list_jobs)
% Get the current status of a list of jobs.
%
% SYNTAX :
% CURR_STATUS = PSOM_JOB_STATUS(PATH_LOGS,LIST_JOBS)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_LOGS
%       (string) the folder where the logs of a pipeline are stored.
%
% LIST_JOBS
%       (cell of strings) a list of job names
%
% _________________________________________________________________________
% OUTPUTS:
%
% CURR_STATUS
%       (cell of string) CURR_STATUS{K} is the current status of
%       LIST_JOBS{K}. Status can be :
%
%           'running' : the job is currently being processed.
%
%           'failed' : the job was processed, but the execution somehow
%                  failed. That may mean that the function produced an
%                  error, or that one of the expected outputs was not
%                  generated. See the log file of the job for more info
%                  using PSOM_PIPELINE_VISU.
%
%           'finished' : the job was successfully processed.
%
%           'none' : no attempt has been made to process the job yet 
%                  (neither 'failed', 'running' or 'finished').
%
% _________________________________________________________________________
% COMMENTS: 
%
% For each job, the presence of tag files is checked (in the following order)
% to determine the status of the job:
%  * (job_name).running  : 'running' status
%  * (job_name).finished : 'finished' status
%  * (job_name).failed   : 'failed' status
%  * otherwise           : 'none' status
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

%% SYNTAX
if ~exist('path_logs','var') || ~exist('list_jobs','var') 
    error('SYNTAX: CURR_STATUS = PSOM_JOB_STATUS(PATH_LOGS,LIST_JOBS). Type ''help psom_job_status'' for more info.')
end

%% Loop over all job names, and check for the existence of tag files
nb_jobs = length(list_jobs);
curr_status = cell([nb_jobs 1]);

for num_j = 1:nb_jobs
    % Generate the names of relevant tag files
    name_job = list_jobs{num_j};
    file_running  = [path_logs name_job '.running'];
    file_failed   = [path_logs name_job '.failed'];
    file_finished = [path_logs name_job '.finished'];
    
    % Check the presence of tag files
    flag_failed   = psom_exist(file_failed);
    flag_finished = psom_exist(file_finished);            
    flag_running  = psom_exist(file_running); 
    
    % Return status
    if psom_exist(file_running)
        curr_status{num_j} = 'running';
    elseif psom_exist(file_finished)
        curr_status{num_j} = 'finished';
    elseif psom_exist(file_failed)
        curr_status{num_j} = 'failed';  
    else
        curr_status{num_j} = 'submitted';                
    end
end
