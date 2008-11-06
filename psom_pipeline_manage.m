function [] = psom_pipeline_manage(file_pipeline,action,opt)
%
% _________________________________________________________________________
% SUMMARY OF PSOM_PIPELINE_MANAGE
%
% Run or reset a PMP pipeline.
%
% SYNTAX:
% [] = PSOM_PIPELINE_MANAGE(FILE_PIPELINE,ACTION,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_PIPELINE  
%       (string) The file name of a .MAT file generated using 
%       PSOM_PIPELINE_INIT. 
%               
% ACTION             
%       (string) Available actions :
%
%           'run' : start a pipeline. If the pipeline is tagged as already 
%                   running, the pipeline manager will not do anything.
%
%           'restart' : reset all 'running' and 'failed' tags to
%                   'unfinished' and restart the pipeline from there.
%
% OPT
%       (structure) with the following fields :
%
%       MODE
%           (string, default 'session') how to execute the pipeline :
%
%           'session' 
%                   the pipeline is executed within the current matlab
%                   session. Interrupting the pipeline with CTRL-C will 
%                   result in interrupting the pipeline (you can always do 
%                   a 'restart' latter). There will be no log file for the
%                   pipeline itself in this mode.
%
%           'batch'
%                   Start the pipeline manager and each job in independent
%                   matlab sessions. Note that more than one session can be
%                   started at the same time to take advantage of
%                   muli-processors machine. Moreover, the pipeline will
%                   run in the background, you can continue to work, close
%                   matlab or even unlog from your machine on a linux
%                   system without interrupting it.
%
%           'sge'
%                   Use the qsub sge system to process the jobs. The
%                   pipeline runs in the background.
%
%           'pbs'   
%                   Use the qsub pbs system to process the jobs. The
%                   pipeline runs in the background.
%
%       MAX_QUEUED
%           (integer, default 1 in 'session' and 'batch' modes, Inf in
%           'sge' and 'pbs' modes)
%           The maximum number of jobs that can be processed
%           simultaneously. Some qsub systems actually put restrictions
%           on that. Contact your local system administrator for more info.
%
%       QSUB_OPTIONS
%           (string)
%           This field can be used to pass any argument when submitting a
%           job with qsub. For example, '-q all.q@yeatman,all.q@zeus' will
%           force qsub to only use the yeatman and zeus workstations in the
%           all.q queue. It can also be used to put restrictions on the
%           minimum avalaible memory, etc.
%
% _________________________________________________________________________
% OUTPUTS:
% 
% _________________________________________________________________________
% SEE ALSO:
%
% PSOM_PIPELINE_INIT, PSOM_PIPELINE_VISU, PSOM_DEMO_PIPELINE,
% PSOM_RUN_PIPELINE.
%
% _________________________________________________________________________
% COMMENTS:
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

niak_gb_vars

init_shell = cat(2,gb_niak_path_quarantine,gb_niak_init_civet);
type_shell = gb_niak_shell;

if ~exist('action','var'); error('niak:pipeline','please specify an action'); end

if ~exist('execution_mode','var'); execution_mode = 'spawn'; end

if ~exist('max_queued','var'); max_queued = 9999; end

[path_logs,name_pipeline,ext_pl] = fileparts(file_pipeline);

file_lock = cat(2,path_logs,filesep,name_pipeline,'.lock');
file_log = cat(2,path_logs,filesep,name_pipeline,'.log');
file_run = cat(2,path_logs,filesep,name_pipeline,'.run');
file_start = cat(2,path_logs,filesep,name_pipeline,'.start');

switch action
    
    case 'run'
        if exist(file_lock,'file')
            error('niak:pipeline: A lock file has been found ! This means the pipeline is either running or crashed.\n If it is crashed, try a ''restart'' or ''reset'' action instead of ''run''')
        end
        
        fprintf('Starting the pipeline ... \n');        
        
        hs = fopen(file_run,'w');

        if exist(file_log,'file')
            system(cat(2,'rm -f ',file_log));
        end
        
        fprintf(hs,'%s run %s %i > %s',file_pipeline,execution_mode,max_queued,file_log);
        fclose(hs);
        
        system(cat(2,'chmod u+x ',file_run));
        [succ,messg] = system(cat(2,'at -f ',file_run,' now > ',file_start));
        
        if succ == 0
            fprintf('The pipeline was started in the background:\n%s\n',messg);
        else
            error(messg)
        end        
        
        
    case 'restart'
        
        fprintf('Cleaning all lock, running and failed jobs ... \n');
        
        list_ext = {'running','failed','lock'};
        
        for num_e = 1:length(list_ext)
            
            list_files = dir(cat(2,path_logs,filesep,'*',list_ext{num_e}));
            list_files = {list_files.name};
            
            for num_f = 1:length(list_files)
                base_file = list_files{num_f};
                base_file = base_file(1:end-length(list_ext{num_e}));
                system(cat(2,'rm -f ',path_logs,filesep,base_file,'log'));
                system(cat(2,'rm -f ',path_logs,filesep,base_file,list_ext{num_e}));
            end
            
        end                    
                
        s = niak_manage_pipeline(file_pipeline,'run',execution_mode)
        
    case 'reset'
        
        fprintf('Cleaning all lock, running, failed and finished jobs ... \n');        
        
        list_ext = {'running','failed','lock','finished'};
        
        for num_e = 1:length(list_ext)
            
            list_files = dir(cat(2,path_logs,filesep,'*',list_ext{num_e}));
            list_files = {list_files.name};
            
            for num_f = 1:length(list_files)
                base_file = list_files{num_f};
                base_file = base_file(1:end-length(list_ext{num_e}));
                system(cat(2,'rm -f ',path_logs,filesep,base_file,'log'));
                system(cat(2,'rm -f ',path_logs,filesep,base_file,list_ext{num_e}));
            end
            
        end                    
               
        s = niak_manage_pipeline(file_pipeline,'run',execution_mode);        
        
    otherwise
        error('niak:pipeline:%s : unknown action',action);
end