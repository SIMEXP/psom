function file_pipeline = psom_pipeline_init(pipeline,opt)
%
% _________________________________________________________________________
% SUMMARY PSOM_PIPELINE_INIT
%
% Convert a matlab-based pipeline structure into a set of mat files
% describing each job separatly.
%
% SYNTAX:
% FILE_PIPELINE = PSOM_PIPELINE_INIT(PIPELINE,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% * PIPELINE
%       (structure) a matlab structure which defines a pipeline.
%       Each field name <JOB_NAME> will be used to name jobs in PMP and set
%       dependencies. The fields <JOB_NAME> are themselves structure, with
%       the following fields :
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
% * OPT
%       (structure) with the following fields :
%
%       PATH_LOGS
%           (string) The folder where the .M and .MAT files will be stored.
%
%       NAME_PIPELINE
%           (string, default 'PSOM_pipeline') the name of the pipeline.
%           No space, no weird characters please.
%
%       COMMAND_MATLAB
%           (string, default GB_PSOM_COMMAND_MATLAB or
%           GB_PSOM_COMMAND_OCTAVE depending on the current environment)
%           how to invoke matlab (or OCTAVE).
%           You may want to update that to add the full path of the command.
%           The defaut for this field can be set using the variable
%           GB_PSOM_COMMAND_MATLAB/OCTAVE in the file PSOM_GB_VARS.
%
%       FLAG_VERBOSE
%           (boolean, default 1) if the flag is 1, then the function prints
%           some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% FILE_PIPELINE
%       (string) the file name of the .MAT file recapitulating all the
%       infos on the pipeline
%
% _________________________________________________________________________
% SEE ALSO:
%
% PSOM_PIPELINE_PROCESS, PSOM_PIPELINE_VISU, PSOM_DEMO_PIPELINE
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%
%   All directories for output files are created by PSOM_INIT_PIPELINE.
%
%   The directory PATH_LOGS is created. It contains the following files :
%
%   PATH_LOGS/NAME_PIPELINE.MAT
%       A .MAT file with the following variables:
%
%       PIPELINE, OPT
%           The inputs of the initialization
%
%       HISTORY
%           A string recapituling when and who created the pipeline, (and
%           on which machine).
%
%       DEPS, LIST_JOBS, FILES_IN, FILES_OUT, GRAPH_DEPS
%           See PSOM_BUILD_DEPENDENCIES for more info.
%
%   PATH_LOGS/NAME_PIPELINE.path_def.mat
%       The matlab search path for the pipeline (it is using the current
%       path, so make sure all the tools you need are available before
%       initializing the pipeline).
%
%   PATH_LOGS/<JOB_NAME>.M : A matlab or octave .M file which runs the
%       associated job.
%
%   PATH_LOGS/<JOB_NAME>.MAT : this file contains the variables FILES_IN,
%       FILES_OUT and OPT of the current stage.
%
%
% NOTE 2:
%
%   If a pipeline file already exists, the initialization will simply be
%   cancelled. You need to clean manually the logs before restarting a
%   pipeline.
%
%   There are plans to have an "update" mode in the future.
%
% NOTE 3:
%
%   There will be some checks done on the pipeline before initializing it :
%
%   1. That the dependency graph of the pipeline is a directed acyclic
%   graph, i.e. if job A depends on job B, job B does not depend (even
%   indirectly) on job A.
%
%   2. That an output file is not created twice. Overwritting on files is
%   regarded as a bug in a pipeline (forgetting to edit a copy-paste is a
%   common mistake).
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

%%%%%%%%%%%%%%%%%%%%%
%% Checking inputs %%
%%%%%%%%%%%%%%%%%%%%%

psom_gb_vars

%% Syntax
if ~exist('pipeline','var')||~exist('opt','var')
    error('syntax: FILE_PIPELINE = PSOM_PIPELINE_INIT(PIPELINE,OPT).\n Type ''help psom_pipeline_init'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'path_logs','name_pipeline','command_matlab','flag_verbose'};
gb_list_defaults = {NaN,'PSOM_pipeline','',true};
psom_set_defaults

if isempty(opt.command_matlab)
    if strcmp(gb_psom_language,'matlab')
        opt.command_matlab = gb_psom_command_matlab;
    else
        opt.command_matlab = gb_psom_command_octave;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generating file names %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

file_pipeline = cat(2,path_logs,filesep,name_pipeline,'.mat');
file_path = cat(2,path_logs,filesep,name_pipeline,'.path_def.mat');
list_jobs = fieldnames(pipeline);
nb_jobs = length(list_jobs);

for num_j = 1:nb_jobs

    name_job = list_jobs{num_j};
    files_var.(name_job) = cat(2,path_logs,filesep,name_job,'.mat');
    files_m.(name_job) = cat(2,path_logs,filesep,name_job,'.mat');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Test for an existing pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if exist(file_pipeline,'file')
    error('The file %s already exist.\nIt looks like the pipeline has already been initialized.\nSorry dude, I must quit ...',file_pipeline);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generating dependencies %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Generating the dependencies of the pipeline ...\n');
end

[deps,list_jobs,files_in,files_out,graph_deps] = psom_build_dependencies(pipeline);

%% Check for outputs generated twice

[flag_ok,list_files_failed,list_jobs_failed] = psom_is_files_out_ok(files_out);

if ~flag_ok    
    for num_f = 1:length(list_files_failed)
        if num_f == 1
            str_files = list_files_failed{num_f};
        else
            str_files = [str_files ' ; '  list_files_failed{num_f}];
        end
    end
    
    for num_j = 1:length(list_jobs_failed)
        if num_j == 1
            str_jobs = list_jobs_failed{num_j};
        else
            str_jobs = [str_jobs ' ; ' list_jobs_failed{num_j}];
        end
    end

    error('The following output files are generated multiple times : %s.\nThe following jobs are responsible for that : %s',str_files,str_jobs);
end

%% Check for cycles

[flag_dag,list_vert_cycle] = psom_is_dag(graph_deps);

if ~flag_dag
    
    for num_f = 1:length(list_vert_cycle)
        if num_f == 1
            str_files = list_jobs{list_vert_cycle(num_f)};
        else
            str_files = [str_files ' ; '  list_jobs{list_vert_cycle(num_f)}];
        end
    end
    error('There are cycles in the dependency graph of the pipeline. The following jobs are involved in at least one cycle : %s',str_files);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Creating log & output folders %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Generating output and log folders ...\n');
end

if ~exist(path_logs,'dir')
    [succ,messg,messgid] = psom_mkdir(path_logs);

    if succ == 0
        warning(messgid,messg);
    end
end

for num_j = 1:length(list_jobs)

    job_name = list_jobs{num_j};
    list_files = unique(files_out.(job_name));

    for num_f = 1:length(list_files)

        path_f = fileparts(list_files{num_f});

        if ~exist(path_f,'dir')

            [succ,messg,messgid] = psom_mkdir(path_f);

            if succ == 0
                warning(messgid,messg);
            end

        end

    end % for files

end % for jobs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Saving the matlab version of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Saving the pipeline structure in %s...\n',file_pipeline);
end

history = [datestr(now) ' ' gb_psom_user ' on a ' gb_psom_OS ' system used PSOM v' gb_psom_version '>>>> Created a pipeline !\n'];
save(file_pipeline,'pipeline','history','deps','graph_deps','list_jobs','files_in','files_out')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting up path for the Matlab/Octave environment %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Saving the search path for Matlab or octave in %s... \n',file_path);
end

path_work = path;
save(file_path,'path_work')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Creating the bash scripts for all stages of the pipeline, as well as the core of the PMP script %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for num_j = 1:length(list_jobs)

    if flag_verbose
        fprintf('Adding job : %s\n',job_name);
    end

    %% Getting information on the stage
    job_name = list_jobs{num_j};
    job = pipeline.(job_name);

    gb_name_structure = 'job';
    gb_list_fields = {'command','files_in','files_out','opt','label','environment'};
    gb_list_defaults = {NaN,NaN,NaN,NaN,'',''};
    psom_set_defaults

    %% Creation of the .mat file with all variables necessary to perform
    %% the stage
    save(files_var.(job_name),'command','files_in','files_out','opt')
    
end

if flag_verbose
    fprintf('The pipeline has been successfully initialized\n');
end
