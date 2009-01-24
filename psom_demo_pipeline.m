%
% _________________________________________________________________________
% SUMMARY OF PSOM_DEMO_PIPELINE
%
% This is a script to demonstrate how to use the pipeline system for Octave
% and Matlab (PSOM).
%
% SYNTAX:
% Just type in PSOM_DEMO_PIPELINE. 
%
% The blocks of code follow the tutorial that can be found at the following 
% address : 
% http://code.google.com/p/psom/w/edit/HowToUsePsom
%
% You can run a block of code by selecting it and press F9.
%
% _________________________________________________________________________
% COMMENTS:
%
% This is a script and it will clear the workspace !!
% It will also create some files and one folder in ~/psom/data_demo/
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, pipeline, fMRI

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

clear

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% What is a pipeline ? %%
%%%%%%%%%%%%%%%%%%%%%%%%%%    

psom_gb_vars

pipeline.message.command = 'fprintf(''The number of samples was : %i. Well that info will be in the logs anyway but still...\n'',opt.nb_samples)';
pipeline.message.files_in = {};
pipeline.message.files_out = {};
pipeline.message.opt.nb_samples = 30;

pipeline.tseries1.command = 'tseries = randn([opt.nb_samples 1]); save(files_out,''tseries'')';
pipeline.tseries1.files_in = {};
pipeline.tseries1.files_out = [gb_psom_path_demo 'tseries1.mat'];
pipeline.tseries1.opt.nb_samples = pipeline.message.opt.nb_samples;

pipeline.tseries2.command = 'tseries = randn([opt.nb_samples 1]); save(files_out,''tseries'')';
pipeline.tseries2.files_in = {};
pipeline.tseries2.files_out = [gb_psom_path_demo 'tseries2.mat'];
pipeline.tseries2.opt.nb_samples = pipeline.message.opt.nb_samples;

pipeline.fft.command = 'load(files_in{1}); ftseries = zeros([size(tseries,1) 2]); ftseries(:,1) = fft(tseries); load(files_in{2}); ftseries(:,2) = fft(tseries); save(files_out,''ftseries'')';
pipeline.fft.files_in = {pipeline.tseries1.files_out,pipeline.tseries2.files_out};
pipeline.fft.files_out = [gb_psom_path_demo 'ftseries.mat'];
pipeline.fft.opt = struct([]);

pipeline.weights.command = 'load(files_in{1}); load(files_in{2}); res = ftseries * weights; save(files_out,''res'')';
pipeline.weights.files_in.fft = pipeline.fft.files_out;
pipeline.weights.files_in.sessions.session1 = [gb_psom_path_demo 'weights.mat'];
pipeline.weights.files_out = [gb_psom_path_demo 'results.mat'];
pipeline.weights.opt = struct([]);

%%%%%%%%%%%%%%%%%%%%%%%%
%% Running a pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%

% The following lines are setting up the options to run the pipeline

opt.path_logs = [gb_psom_path_demo 'logs' filesep];     % where to store the log files
opt.mode = 'session';                                   % how to execute the pipeline    
opt.mode_pipeline_manager = 'session';                  % how to run the pipeline manager
opt.max_queued = 2;                                     % how much jobs can be processed simultaneously

% The following line is running the pipeline manager on the toy pipeline
psom_run_pipeline(pipeline,opt);
