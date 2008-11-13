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
% [STATUS,MSG] = PSOM_RUN_JOB(FILE_JOB,FILE_LOG)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_JOB
%       (string) a mat file with full path. This mat file contains the
%       following variables :
%
%       COMMAND
%           (string) the name of the command applied for this job.
%           This command can use the variables FILES_IN, FILES_OUT and OPT
%           associated with the job (see below).
%           Examples :
%               'niak_brick_something(files_in,files_out,opt);'
%               'my_function(opt)'
%
%       FILES_IN
%           (string, cell of strings, structure whose terminal nodes are
%           string or cell of strings)
%           The argument FILES_IN of the BRICK. Note that for properly
%           handling dependencies, this field needs to contain the exact
%           name of the file (full path, no wildcards, no '' for default
%           values).
%
%       FILES_OUT
%           (string, cell of strings, structure whose terminal nodes are
%           string or cell of strings) the argument FILES_OUT of
%           the BRICK. Note that for properly handling dependencies, this
%           field needs to contain the exact name of the file
%           (full path, no wildcards, no '' for default values).
%
%       OPT
%           (any matlab variable) options of the job. This field has no
%           impact on dependencies. OPT can for example be a structure,
%           where each field will be used as an argument of the command.
%
% _________________________________________________________________________
% OUTPUTS:
%
% STATUS
%       (boolean) STATUS == 0 : the execution failed, STATUS == 1 : the
%       execution is finished.
%
% _________________________________________________________________________
% SEE ALSO:
%
% PSOM_PIPELINE_INIT, PSOM_PIPELINE_MANAGE, PSOM_PIPELINE_VISU, PSOM_DEMO_PIPELINE
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%
% This function will not crash even if the job does. If the job returns an
% error, it is tagged as failed. If there is no error but all the output
% files have not been created, it is tagged as failed too. If there was no
% error and all outputs have been created, the job is tagged as finished.
%
% NOTE 2:
%
% The function will generate three files :
%
%       <BASE FILE_JOB>.running : this empty file means that the job is
%       running. It is deleted before returning the function.
%
%       <BASE FILE_JOB>.failed : means that the job failed.
%
%       <BASE FILE_JOB>.finished : means that the job was completed.
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
[path_f,name_f,ext_f] = fileparts(file_job);

if ~strcmp(ext_f,'.mat')
    error('The job file %s should be a .mat file !',file_job);
end

file_running = [path_f filesep name_f '.running'];
file_failed = [path_f filesep name_f '.failed'];
file_finished = [path_f filesep name_f '.finished'];

if exist(file_running,'file')|exist(file_failed,'file')|exist(file_finished,'file')
    fprintf('Already found a tag on that job. Sorry dude, I must quit ...');
    return
end

%% Create a running tag for the job
tmp = datestr(clock);
save(file_running,'tmp')

%% Print general info about the job
msg = sprintf('Log of the (%s) job : %s\nStarted on %s\nUser: %s\nhost : %s\nsystem : %s',gb_psom_language,name_f,datestr(clock),gb_psom_user,gb_psom_localhost,gb_psom_OS);
stars = repmat('*',[1 30]);
fprintf('\n%s\n%s\n%s\n',stars,msg,stars);

job = load(file_job);

gb_name_structure = 'job';
gb_list_fields = {'files_in','files_out','command','opt'};
gb_list_defaults = {{},{},NaN,{}};
psom_set_defaults

str_default = evalc('psom_set_defaults');
fprintf('%s',str_default);

str_log = evalc('command, files_in, files_out, opt,');
fprintf('%s',str_log);

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
        fprintf('Huho the job completed successfully but I found a FAILED tag. There must be something weird going on with the pipeline manager. Anyway, I will let the FAILED tag just in case ...');
    end
        
    if flag_failed
        msg1 = sprintf('The job has FAILED');
        instr_failed = ['touch ',file_failed];
        system(instr_failed);
    else
        msg1 = sprintf('The job was successfully completed');
        instr_finished = ['touch ',file_finished];
        system(instr_finished);
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
