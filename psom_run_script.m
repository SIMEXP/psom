function [flag_failed,msg] = psom_run_script(cmd,script,opt,logs)
% Run an Octave/Matlab command in a script 
%
% SYNTAX:
% [FLAG_FAILED,MSG] = PSOM_RUN_SCRIPT(CMD,SCRIPT,OPT,LOGS)
%
%_________________________________________________________________________
% INPUTS:
%
% CMD
%    (string) A Matlab/Octave command. If it is empty, it is still possible 
%    to run a command using OPT.SHELL_OPTIONS below.
%
% SCRIPT
%    (string) The name of the script that will be generated to run the 
%    command (except if OPT.MODE is 'session', in which case no script is
%    generated to execute the command and SCRIPT is ignored).
%
% OPT
%    (structure) describes how to execute the command.
%
%    NAME_JOB
%        (string, default 'psom_script') This name is used when submitting
%        the script in 'qsub' or 'msub' execution modes (see below).
%
%    MODE
%        (string) the execution mechanism. Available 
%        options :
%        'session'    : current Matlab session.
%        'background' : background execution, non-unlogin-proofed 
%                       (asynchronous system call).
%        'batch'      : background execution, unlogin-proofed ('at' in 
%                       UNIX, start in WINDOWS.
%        'qsub'       : remote execution using qsub (torque, SGE, PBS).
%        'msub'       : remote execution using msub (MOAB)
%
%    SHELL_OPTIONS
%       (string, default GB_PSOM_SHELL_OPTIONS defined in PSOM_GB_VARS)
%       some commands that will be added at the begining of the shell
%       script. This can be used to set important variables, or source an 
%       initialization script.
%
%    QSUB_OPTIONS
%        (string, GB_PSOM_QSUB_OPTIONS defined in PSOM_GB_VARS)
%        This field can be used to pass any argument when submitting a
%        job with qsub/msub. For example, '-q all.q@yeatman,all.q@zeus'
%        will force qsub/msub to only use the yeatman and zeus
%        workstations in the all.q queue. It can also be used to put
%        restrictions on the minimum avalaible memory, etc.
%
%    COMMAND_MATLAB
%        (string, default GB_PSOM_COMMAND_MATLAB or
%        GB_PSOM_COMMAND_OCTAVE depending on the current environment)
%        how to invoke matlab (or OCTAVE).
%        You may want to update that to add the full path of the command.
%        The defaut for this field can be set using the variable
%        GB_PSOM_COMMAND_MATLAB/OCTAVE in the file PSOM_GB_VARS.
%
%    INIT_MATLAB
%        (string, default '') a matlab command (multiple commands can
%        actually be passed using comma separation) that will be
%        executed at the begining of any matlab/Octave job. That 
%        mechanism can be used, e.g., to set up the state of the random 
%        generation number.
%
%    FLAG_DEBUG
%        (boolean, default false) if FLAG_DEBUG is true, the program
%        prints additional information for debugging purposes.
%
%    FILE_HANDLE
%        (scalar, default []) if non-empty, the handle of a text file 
%        where all verbose will be appended.
%
% LOGS
%    (structure, optional) Indicates where to save the logs. If 
%    unspecified, no log is generated. LOGS can have the following 
%    fields:
%
%    TXT
%        (string) where the text log file will be saved.
%
%    EQSUB
%        (string) where the error log file from QSUB will be generated.
%        This is only used in 'qsub' and 'msub' modes.
%
%    OQSUB
%        (string) where the output log file from QSUB will be generated.
%        This is only used in 'qsub' and 'msub' modes.
%
%    EXIT
%        (string) the name of an empty file that will be generated 
%        when the script is finished. This is ignored in 'session' mode.
% 
%_________________________________________________________________________
% OUTPUTS:
%
% FLAG_FAILED
%    (boolean) FLAG_FAILED is true if the script has failed. 
%
% MSG
%    (string) the output of the script.
%         
% _________________________________________________________________________
% COMMENTS:
%
% The function will automatically use Matlab (resp. Octave) to execute the 
% commmand when invoked from Matlab (resp. Octave).  
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
% Departement d'informatique et de recherche operationnelle
% Centre de recherche de l'institut de Geriatrie de Montreal
% Universite de Montreal, 2010-2011.
% Maintainer : pierre.bellec@criugm.qc.ca
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

%% Check syntax
if nargin<3
    error('SYNTAX: [] = PSOM_RUN_SCRIPT(CMD,SCRIPT,OPT,LOGS). Type ''help psom_run_script'' for more info.')
end

%% Options
list_fields    = { 'file_handle' , 'name_job'    , 'init_matlab'       , 'flag_debug' , 'shell_options'       , 'command_matlab' , 'mode' , 'qsub_options'       };
list_defaults  = { []            , 'psom_script' , gb_psom_init_matlab , false        , gb_psom_shell_options , ''               , NaN    , gb_psom_qsub_options };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

if ~isempty(opt.init_matlab)&&~ismember(opt.init_matlab(end),{',',';'})
    opt.init_matlab = [opt.init_matlab ','];
end

if isempty(opt.command_matlab)
    if strcmp(gb_psom_language,'matlab')
        opt.command_matlab = gb_psom_command_matlab;
    else
        opt.command_matlab = gb_psom_command_octave;
    end
end

%% Logs
if nargin < 4
    logs = [];
else
    list_fields   = { 'txt' , 'eqsub' , 'oqsub' , 'exit' };
    list_defaults = { NaN   , NaN     , NaN     , ''     };
end

%% Check that the execution mode exists
if ~ismember(opt.mode,{'session','background','batch','qsub','msub'})
    error('%s is an unknown mode of command execution. Sorry dude, I must quit ...',opt.mode);
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate the script %%
%%%%%%%%%%%%%%%%%%%%%%%%%

%% Generate some OS-appropriate options to start Matlab/Octave
switch gb_psom_language
    case 'matlab'
        if ispc
            opt_matlab = '-automation -nodesktop -r';
        else
            opt_matlab = '-nosplash -nodesktop -r';
        end        
    case 'octave'
        opt_matlab = '--silent --eval';       
end
    
%% Add an appropriate call to Matlab/Octave
if ~isempty(cmd)            
    instr_job = sprintf('%s %s "%s %s,exit"',opt.command_matlab,opt_matlab,opt.init_matlab,cmd);
    if ~isempty(logs)
        instr_job = sprintf('%s>%s\n',instr_job,logs.txt);
    else
        instr_job = sprintf('%s\n',instr_job);
    end
else
    instr_job = '';
end
        
%% Add shell options
if ~isempty(opt.shell_options)
    instr_job = sprintf('%s\n%s',opt.shell_options,instr_job);
end    

%% Add a .exit tag file
if ~isempty(logs)&&~isempty(logs.exit)
    if ispc % this is windows
        instr_job = sprintf('%s\ntype nul > %s\nexit\n',instr_job,logs.exit);
    else
        instr_job = sprintf('%s\ntouch %s',instr_job,logs.exit);
    end
end

%% Write the script
if ~strcmp(opt.mode,'session')            
    if opt.flag_debug
        msg = sprintf('    The following script is used to run the command :\n%s\n\n',instr_job);
        fprintf('%s',msg);
        if ~isempty(opt.file_handle)
            fprintf(opt.file_handle,'%s',msg);
        end
    end
    
    hf = fopen(script,'w');
    fprintf(hf,'%s',instr_job);
    fclose(hf);
else
    if opt.flag_debug
        msg = sprintf('    The following command is going to be executed :\n%s\n\n',cmd);
        fprintf('%s',msg);
        if ~isempty(opt.file_handle)
            fprintf(opt.file_handle,'%s',msg);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%   
%% Execute the script %%
%%%%%%%%%%%%%%%%%%%%%%%%

switch opt.mode

    case 'session'

        try
            if ~isempty(logs)
                diary(logs.txt)
                sub_eval(cmd);
                diary off
            else
                sub_eval(cmd);
            end
            flag_failed = false;
            msg = '';
        catch
            flag_failed = true;
            errmsg = lasterror;
            msg = errmsg.message;
            if isfield(errmsg,'stack')
                for num_e = 1:length(errmsg.stack)
                    msg = sprintf('%s\nFile %s at line %i\n',msg,errmsg.stack(num_e).file,errmsg.stack(num_e).line);
                end           
            end
        end

    case 'background'
       
       if opt.flag_debug
           [flag_failed,msg] = system(['. ' script]);
       else
           if strcmp(gb_psom_language,'octave')
               system(['. ' script ],false,'async');
               flag_failed = 0;
           else 
               flag_failed = system(['. ' script ' &']);
           end
           msg = '';
       end

    case 'batch'

        if ispc
            instr_batch = sprintf('start /b %s',script); % /min instead of /b ?
        else
            instr_batch = ['at -f ' script ' now'];
        end
        if opt.flag_debug 
            [flag_failed,msg] = system(instr_batch);    
        else
            if strcmp(gb_psom_language,'octave')
                 system(instr_batch,false,'async');
                 flag_failed = 0;
            else
                 flag_failed = system([instr_batch ' &']);
            end
            msg = '';
        end

    case {'qsub','msub'}
        
        if isempty(logs)
            qsub_logs = '';
        else
            qsub_logs = [' -e ' logs.eqsub ' -o ' logs.oqsub];
        end
        instr_qsub = [opt.mode qsub_logs ' -N ' opt.name_job ' ' opt.qsub_options ' ' script];            
        if flag_debug
            [flag_failed,msg] = system(instr_qsub);
        else 
            if strcmp(gb_psom_language,'octave')
                system(instr_qsub,false,'async');
                flag_failed = 0;
            else
                flag_failed = system([instr_qsub ' &']);
            end
            msg = '';
        end
end

%%%%%% Subfunctions %%%%%%

function [] = sub_eval(cmd)
eval(cmd)