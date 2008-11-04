function deps = psom_build_dependencies(pipeline)
%
% _________________________________________________________________________
% SUMMARY PSOM_BUILD_DEPENDENCIES
%
% Generate a dependencie structure from a pipeline structure
%
% SYNTAX:
% DEPS = NIAK_BUILD_DEPENDENCIES(PIPELINE)
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
%               <JOB_NAME2> is actually listed in the cell.
%
% _________________________________________________________________________
% SEE ALSO
%
% PSOM_MANAGE_PIPELINE
%
% _________________________________________________________________________
% COMMENTS
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
    error('SYNTAX: DEPS = PSOM_BUILD_DEPENDENCIES(PIPELINE). Type ''help psom_build_dependencies'' for more info.')
end

list_jobs = fieldnames(pipeline);
nb_jobs = length(list_jobs);

for num_j = 1:nb_jobs
    name_job = list_jobs{num_j};
    files_in.(name_job) = unique(psom_files2cell(pipeline.(name_job).files_in));
    files_out.(name_job) = unique(psom_files2cell(pipeline.(name_job).files_out));
end

for num_j = 1:nb_jobs
    name_job1 = list_jobs{num_j};
    
    for num_k = 1:nb_jobs
        name_job2 = list_jobs{num_k};
        
        if num_j ~= num_k
            mask_dep = ismember(files_in.(name_job1),files_out.(name_job2));
            if max(mask_dep) == 1
                deps.(name_job1).(name_job2) = files_in.(name_job1)(mask_dep);
            end
        end
    end
    
    if ~exist('deps','var')
        deps.(name_job1) = struct([]);
    else
        if ~isfield(deps,name_job1)
            deps.(name_job1) = struct([]);
        end
    end
end
            