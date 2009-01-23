%
% _________________________________________________________________________
% SUMMARY OF PSOM_DEMO_PIPELINE
%
% This is a script to demonstrate how to use the pipeline system for Octave
% and Matlab (PSOM).
%
% SYNTAX:
% Just type in PSOM_DEMO_PIPELINE. There will be pauses and comments at the
% end of each section of code in the demo. This demo is also available in a
% tutorial form on the internet : 
% http://code.google.com/p/psom/w/edit/HowToUsePsom
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
psom_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%
%% Build the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%
    
% This is a script to generate a toy pipeline

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
pipeline.weights.files_in.weights.session1 = [gb_psom_path_demo 'weights.mat'];
pipeline.weights.files_out = [gb_psom_path_demo 'results.mat'];
pipeline.weights.opt = struct([]);

% The comments for this stage start here

msg = 'WHAT IS A PIPELINE ?';
stars = repmat('*',size(msg));
fprintf('\n%s\n%s\n%s\n\n',stars,msg,stars)

fprintf('In PSOM pipelines are described using a matlab-type structure :\n\n>> pipeline\n');
pipeline

fprintf('Each field of the pipeline is describing one job. For example :\n\n>> pipeline.message\n')
pipeline.message

fprintf('This is a very simple job ! As you can see, the field ''command'' describes the matlab/octave command line(s) executed by the job.\n')

fprintf('\nThe fields ''files_in'' and ''files_out'' respectively describe the lists of input and output files.\n')
fprintf('Note that the format is extremely flexible :\n''files_in/out'' can be a string, a cell of strings or a structure whose fields are of the preceeding type (including structures). Examples : \n')
fprintf('\n>> pipeline.fft.files_in{:}\n')
pipeline.fft.files_in{:}

fprintf('\n>> pipeline.weights.files_in\n')
pipeline.weights.files_in

fprintf('\n>> pipeline.weights.files_in.weights\n')
pipeline.weights.files_in.weights

fprintf('Finally the field ''opt'' could be any variable.\n')

msg = 'PRESS ANY KEY TO CONTINUE THE DEMO, OR CTRL-C TO INTERRUPT';
stars = repmat('*',size(msg));
fprintf('\n\n%s\n%s\n%s\n\n',stars,msg,stars)
pause

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%
opt.path_logs = [gb_psom_path_demo 'logs' filesep];
opt.mode = 'batch';
opt.mode_pipeline_manager = 'session';
opt.max_queued = 2;
opt.time_cool_down = 0;
opt.time_between_checks = 2;
psom_run_pipeline(pipeline,opt);
