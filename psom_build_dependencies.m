function [deps,list_jobs,files_in,files_out,graph_deps] = psom_build_dependencies(pipeline,flag_verbose)
%
% _________________________________________________________________________
% SUMMARY PSOM_BUILD_DEPENDENCIES
%
% Generate the dependency graph of a pipeline.
%
% SYNTAX:
% [DEPS,LIST_JOBS,FILES_IN,FILES_OUT,GRAPH_DEPS] = NIAK_BUILD_DEPENDENCIES(PIPELINE)
%
% _________________________________________________________________________
% INPUTS
%
% PIPELINE
%       (structure) Each field of PIPELINE is a job with an arbitrary name:
%
%       <JOB_NAME> a structure with the following fields:
%
%               FILES_IN
%                   (string, cell of strings or structure whos terminal
%                   fields are strings or cell of strings)
%                   a list of the input files of the job
%
%               FILES_OUT
%                   (string, cell of strings or structure whos terminal
%                   fields are strings or cell of strings)
%                   a list of the output files of the job
%
% FLAG_VERBOSE
%       (boolean, default true) if the flag is true, then the function
%       prints some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS
%
% DEPS
%       (structure) the field names are identical to PIPELINE
%
%       <JOB_NAME> a structure with the following fields :
%
%           <JOB_NAME2>
%               (cell of strings)
%               The presence of this field means that the job <JOB_NAME> is
%               using an output of <JOB_NAME2> as one of his inputs. The
%               exact list of inputs of <JOB_NAME> that comes from
%               <JOB_NAME2> is actually listed in the cell.*
%
% LIST_JOBS
%       (cell of strings)
%       The list of all job names
%
% FILES_IN
%       (structure) the field names are identical to PIPELINE
%
%       <JOB_NAME>
%           (cell of strings) the list of input files for the job
%
% FILES_OUT
%       (structure) the field names are identical to PIPELINE
%
%       <JOB_NAME>
%           (cell of strings) the list of output files for the job
%
% GRAPH_DEPS
%       (sparse matrix)
%       GRAPH_DEPS(I,J) == 1 if and only if the job LIST_JOBS{J} depends on
%       the job LIST_JOBS{I}
%
% _________________________________________________________________________
% SEE ALSO
%
% PSOM_MANAGE_PIPELINE
%
% _________________________________________________________________________
% COMMENTS
%
% Empty file names, or file names equal to 'gb_niak_omitted' are ignored.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : pipeline, dependencies

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
if ~exist('pipeline','var')
    error('SYNTAX: DEPS = PSOM_BUILD_DEPENDENCIES(PIPELINE[,FLAG_VERBOSE]). Type ''help psom_build_dependencies'' for more info.')
end

if nargin < 2
    flag_verbose = true;
end
list_jobs = fieldnames(pipeline);
nb_jobs = length(list_jobs);

if flag_verbose
    fprintf('       Reorganizing inputs/outputs ...\n')
end
for num_j = 1:nb_jobs
    name_job = list_jobs{num_j};
    try
        if isfield(pipeline.(name_job),'files_in')
            files_in.(name_job) = unique(psom_files2cell(pipeline.(name_job).files_in));
        else
            files_in.(name_job) = {};
        end
    catch
        fprintf('There was a problem with the input files of job %s\n',name_job)
        errmsg = lasterror;
        rethrow(errmsg);
    end
    try
        if isfield(pipeline.(name_job),'files_out')
            files_out.(name_job) = unique(psom_files2cell(pipeline.(name_job).files_out));
        else
            files_out.(name_job) = {};
        end
    catch
        fprintf('There was a problem with the output files of the job %s\n',name_job)
        errmsg = lasterror;
        rethrow(errmsg);
    end
end
[char_in,ind_in] = psom_struct_cell_string2char(files_in);
[char_out,ind_out] = psom_struct_cell_string2char(files_out);

char_all = char(char_in,char_out);
mask_out = false([size(char_all,1) 1]);
mask_out(size(char_in,1)+1:size(char_all,1)) = true;
[val_tmp,ind_tmp,char_all] = unique(char_all,'rows');
num_in = char_all(~mask_out);
num_out = char_all(mask_out);
clear char_all mask_out val_tmp ind_tmp

graph_deps = sparse(nb_jobs,nb_jobs);
if flag_verbose
    fprintf('       Analyzing job inputs/outputs, percentage completed : ')
    curr_perc = -1;
end

for num_j = 1:nb_jobs
    if flag_verbose
        new_perc = 5*floor(20*num_j/nb_jobs);
        if curr_perc~=new_perc
            fprintf(' %1.0f',new_perc);
            curr_perc = new_perc;
        end
    end
    name_job1 = list_jobs{num_j};
    mask_dep = ismember(num_out,num_in(ind_in==num_j));
    list_job_dep = unique(ind_out(mask_dep));
    
    if ~isempty(list_job_dep)
        for num_l = list_job_dep'
            name_job2 = list_jobs{num_l};
            graph_deps(num_l,num_j) = true;
            deps.(name_job1).(name_job2) = psom_char2cell(char_out(mask_dep & (ind_out==num_l),:));
        end
    else
        deps.(name_job1) = struct([]);
    end
end
if flag_verbose
    fprintf('\n')
end
            