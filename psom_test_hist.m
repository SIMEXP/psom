function [pipel,opt_pipe] = psom_test_hist(path_test,opt)
% A test pipeline with chains of jobs accumulating histograms
%
% [pipe,opt_pipe] = psom_test_hist(path_test,opt)
%
% PATH_TEST (string, default current path) where to run the test.
% OPT (structure) any option passed to PSOM will do. In addition the 
%   following options are available:
%   PATH_LOGS is forced to [path_test filesep 'logs']
%   MINMAX (vector 2x1, default [-5 5]) the min/max of the histogram.
%   SIZEBIN (scalar, default 0.001) the size of the bins of the histogram.
%   NB_JOBS (integer, default 100) the number of jobs.
%   NB_CHAINS (integer, default 1) the number of chains. The final 
%     number of jobs is NB_JOBS x NB_CHAINS.
%   FLAG_TEST (boolean, default false) if FLAG_TEST is on, the pipeline
%     is generated but not executed.
% PIPE (structure) the pipeline.
% OPT_PIPE (structure) the options to run the pipeline.
%
% Note: 1 Mb is defined here as 1000 kb, consistent the international system of units. 
% This is slightly different from the definition used by linux and windows file systems 
% where 1 Mb = 1024 kb
%
% Copyright (c) Pierre Bellec, 
% Departement d'informatique et de recherche operationnelle
% Centre de recherche de l'institut de Geriatrie de Montreal
% Universite de Montreal, 2015.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information the LICENSE file.
% Keywords : pipeline, PSOM, test

%% Set up default options
pipel = struct;

if nargin < 2
    opt = struct;
end

list_opt = { 'nb_samp' , 'minmax' , 'sizebin' , 'nb_jobs' , 'nb_chains' , 'flag_test' };
list_def = { 10^7      , [-5,5]   , 0.001     , 100       , 1           , false       };
opt = psom_struct_defaults(opt,list_opt,list_def,false);

if (nargin < 1)||isempty(path_test)
    path_test = pwd;
end
if ~strcmp(path_test(end),filesep)
    path_test = [path_test filesep];
end

opt.path_logs = [path_test 'logs'];

%% The options for PSOM
opt_pipe = rmfield(opt,list_opt);

%% Options for job
optj.nb_samp = opt.nb_samp;
optj.minmax  = opt.minmax;
optj.sizebin = opt.sizebin;

%% Build the pipeline
for num_c = 1:opt.nb_chains
    for num_j = 1:opt.nb_jobs
        job_name = sprintf('samp%i_%i',num_j,num_c);   
        pipel.(job_name).opt = optj;
        
        if (num_j > 1)
            % normal iteration: accumulate histograms
            pipel.(job_name).command = sprintf([ ...
                ' data0 = load(files_in);' ...
                ' data = randn(opt.nb_samp,1);' ...
                ' edges = opt.minmax(1):opt.sizebin:opt.minmax(2);' ...
                ' N = data0.N + histc(data,edges);' ...
                ' save(files_out,''N'');' ...
                ' psom_clean(files_in);' ...
                ]);
            pipel.(job_name).files_in = sprintf('%sdata_job%i_%i.mat',path_test,num_j-1,num_c);
            pipel.(job_name).files_clean = pipel.(job_name).files_in; % clean the results of the previous iteration
            
        elseif num_j == 1
            % first iteration: generate a single histogram
            pipel.(job_name).command = sprintf([ ...
                ' data = randn(opt.nb_samp,1);' ...
                ' edges = opt.minmax(1):opt.sizebin:opt.minmax(2);' ...
                ' N = histc(data,edges);' ...
                ' save(files_out,''N'');' ...
                ]);      
        end
        pipel.(job_name).files_out = sprintf('%sdata_job%i_%i.mat',path_test,num_j,num_c);   
    end
end

% now normalize the histograms
job_name = sprintf('hist_%i',num_c);
for num_c = 1:opt.nb_chains
    pipel.(job_name).files_in{num_c} = sprintf('%sdata_job%i_%i.mat',path_test,opt.nb_jobs,num_c);
end
pipel.(job_name).files_clean = pipel.(job_name).files_in;
pipel.(job_name).files_out = sprintf('%shistogram_gaussian.mat',path_test);
pipel.(job_name).opt = optj;
pipel.(job_name).opt.nb_jobs = opt.nb_jobs;
pipel.(job_name).command = sprintf([ ...
    ' for num_c = 1:length(files_in);' ...
    '  data = load(files_in{num_c});' ...
    '  if num_c == 1; N = data.N; else N = N + data.N; end;' ...
    ' end;' ...
    ' H = N / (opt.sizebin * opt.nb_jobs * opt.nb_samp);' ...
    ' edges = opt.minmax(1):opt.sizebin:opt.minmax(2);' ...
    ' save(files_out,''H'',''edges'');' ...
    ' psom_clean(files_in);' ...
    ]);
        
%% Run the pipeline
if ~opt.flag_test
    psom_run_pipeline(pipel,opt_pipe);
end