function curr_status = psom_job_status(path_logs,list_jobs)
%
% _________________________________________________________________________
% SUMMARY PSOM_JOB_STATUS
%
% Get the current status of a list of jobs.
%
% SYNTAX :
% CURR_STATUS = PSOM_JOB_STATUS(PATH_LOGS,LIST_JOBS)
%
% _________________________________________________________________________
% INPUTS :
%
% PATH_LOGS
%       (string) the folder where the logs of a pipeline are stored.
%
% LIST_JOBS
%       (cell of strings) a list of job names
%
% _________________________________________________________________________
% OUTPUTS :
%
% CURR_STATUS
%       (cell of string) CURR_STATUS{K} is the current status of
%       LIST_JOBS{K}. Status can be :
%           'running' : the job is currently being processed.
%           'failed' : the job was processed, but the execution somehow
%                  failed.
%           'finished' : the job has been successfully processed.
%           'unfinished' : no attempt has been made to process the job yet.
%
% _________________________________________________________________________
% COMMENTS : 
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

nb_jobs = length(list_jobs);
curr_status = cell([nb_jobs 1]);

for num_j = 1:nb_jobs
    
    flag_running = false;
    flag_finished = false;
    flag_failed = false;
    flag_unfinished = false;
    
    name_job = list_jobs{num_j};
    
    file_running = [path_logs filesep name_job '.running'];
    file_failed = [path_logs filesep name_job '.failed'];
    file_finished = [path_logs filesep name_job '.finished'];
    
    if exist(file_running,'file');
        flag_running = true;
    end
    
    if exist(file_failed,'file');
        flag_failed = true;
    end
    
    if exist(file_finished,'file');
        flag_finished = true;
    end
    
    if (flag_running+flag_finished+flag_failed)>1
        error('I am confused : job %s has multiple tags. Sorry dude, I must quit ...',name_job);
    end
    
    if ~(flag_running || flag_finished || flag_failed)
        flag_unfinished = true;
    end
    
    if flag_unfinished
        curr_status{num_j} = 'unfinished';
    elseif flag_finished
        curr_status{num_j} = 'finished';
    elseif flag_failed
        curr_status{num_j} = 'failed';
    elseif flag_running
        curr_status{num_j} = 'running';
    end
end