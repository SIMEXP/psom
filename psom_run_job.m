function [status,msg] = psom_run_job(file_job)
%
% _________________________________________________________________________
% SUMMARY PSOM_RUN_JOB
%
% Load some variables in a matlab file and run the corresponding job. The
% function is generating empty files to flag the status of the processing
% (running, failed or finished). It also verboses some information.
%
% SYNTAX:
% [STATUS,MSG] = PSOM_RUN_JOB(FILE_JOB)
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%
% This function is not meant to be used by itself. It is called by
% PSOM_PIPELINE_PROCESS and PSOM_RUN_PIPELINE
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

%% Generate file names
[path_f,name_job,ext_f] = fileparts(file_job);

if ~strcmp(ext_f,'.mat')
    error('The job file %s should be a .mat file !',file_job);
end

file_jobs = [path_f filesep 'PIPE_jobs.mat'];
file_running = [path_f filesep name_job '.running'];
file_failed = [path_f filesep name_job '.failed'];
file_finished = [path_f filesep name_job '.finished'];

if exist(file_running,'file')|exist(file_failed,'file')|exist(file_finished,'file')
    error('Already found a tag on that job. Sorry dude, I must quit ...');
end

%% Create a running tag for the job
tmp = datestr(clock);
save(file_running,'tmp')

%% Print general info about the job
msg = sprintf('Log of the (%s) job : %s\nStarted on %s\nUser: %s\nhost : %s\nsystem : %s',gb_psom_language,name_job,datestr(clock),gb_psom_user,gb_psom_localhost,gb_psom_OS);
stars = repmat('*',[1 30]);
fprintf('\n%s\n%s\n%s\n',stars,msg,stars);

job = sub_load_job(file_jobs,name_job);

gb_name_structure = 'job';
gb_list_fields = {'files_in','files_out','command','opt'};
gb_list_defaults = {{},{},NaN,{}};
psom_set_defaults

psom_set_defaults
command, files_in, files_out, opt

try
    %% The job starts now !
    msg = sprintf('The job starts now !');
    stars = repmat('*',[1 size(msg,2)]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);

    flag_failed = false;
   
    try

        tic;
        eval(command)
        telapsed = toc;

    catch

        telapsed = toc;
        flag_failed = true;
        errmsg = lasterror;
        fprintf('\n\n%s\nSomething went bad ... the job has FAILED !\nThe last error message occured was :\n%s\n',stars,errmsg.message);
        if isfield(errmsg,'stack')
            for num_e = 1:length(errmsg.stack)
                fprintf('File %s at line %i\n',errmsg.stack(num_e).file,errmsg.stack(num_e).line);
            end
        end
    end
    
    %% Checking outputs
    msg = sprintf('Checking outputs');
    stars = repmat('*',[1 size(msg,2)]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);

    list_files = psom_files2cell(files_out);

    for num_f = 1:length(list_files)
        if ~exist(list_files{num_f})
            fprintf('The output file %s has not been generated!\n',list_files{num_f});
            flag_failed = true;
        else
            fprintf('The output file %s was successfully generated!\n',list_files{num_f});
        end
    end

    %% Finishing the job
    delete(file_running);
    
    if exist(file_failed)
        flag_failed = true;
        fprintf('Huho the job just finished but I found a FAILED tag. There must be something weird going on with the pipeline manager. Anyway, I will let the FAILED tag just in case ...');
    end
        
    if flag_failed
        msg1 = sprintf('%s : The job has FAILED',datestr(clock));
        save(file_failed,'tmp')       
    else
        msg1 = sprintf('%s : The job was successfully completed',datestr(clock));
        save(file_finished,'tmp')        
    end

    msg2 = sprintf('Total time used to process the job : %1.2f sec.',telapsed);
    stars = repmat('*',[1 max(size(msg1,2),size(msg2,2))]);
    fprintf('\n%s\n%s\n%s\n%s\n',stars,msg1,msg2,stars);    

catch
    
    if exist('hf','var')
        fprintf('%s',str_log);
    end
    delete(file_running);
    msg1 = sprintf('The job has FAILED');
    tmp = datestr(clock);
    save(file_failed,'tmp');
    errmsg = lasterror;
    rethrow(errmsg)
end

%%%%%%%%%%%%%%%%%%
%% Subfunctions %%
%%%%%%%%%%%%%%%%%%

function job = sub_load_job(file_jobs,name_job)

load(file_jobs,name_job);
eval(['job = ' name_job ';']);