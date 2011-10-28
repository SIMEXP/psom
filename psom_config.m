function opt = psom_config(path_test,opt,tests)
% Test the configuration of PSOM
%
% SYNTAX:
% OPT = PSOM_CONFIG(PATH_TEST,OPT,TESTS)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_TEST
%    (string, default local_path_demo defined in the file 
%    PSOM_GB_VARS) the full path to folder where the tests will run. 
%    IMPORTANT WARNING : PSOM will empty totally this folder and then 
%    build example files and logs in it.
%
% OPT
%    (structure, optional) the options normally passed to PSOM_RUN_PIPELINE. 
%    Note that the OPT.PATH_LOGS field will be set to [PATH_TEST /logs/].
%    Type "help psom_run_pipeline" for more infos. Note that the defaults 
%    options can be changed by editing the file PSOM_GB_VARS. If you do not 
%    have the permission to edit this file, just copy it under the name 
%    PSOM_GB_VARS_LOCAL and add it to the search path, it will override 
%    PSOM_GB_VARS.
%
% TESTS
%   (string, or cell of strings, default: all tests) The list of tests to be
%   performed (see also the COMMENTs section below):
%   'script_pipe' : Run a simple script       (pipeline manager test)
%   'matlab_pipe' : Start matlab in a script  (pipeline manager test)
%   'psom_pipe'   : Start PSOM in a script    (pipeline manager test)
%   'script_job'  : Run a simple script       (job manager test)
%   'matlab_job'  : Start matlab in a script  (job manager test)
%   'psom_job'    : Start PSOM in a script    (job manager test)
%
% _________________________________________________________________________
% OUTPUTS:
% 
% OPT
%    (structure) an updated version of the input, populated with default 
%    values.
%
% _________________________________________________________________________
% SEE ALSO:
% PSOM_RUN_SCRIPT, PSOM_RUN_PIPELINE, PSOM_DEMO_PIPELINE
% 
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%    PATH_TEST is erased and then populated with (small) test files.
%
% NOTE 2:
%    This function will test the PSOM configuration step-by-step, and will 
%    produce reasonably explicit error messages if an error occurs at any 
%    stage. PSOM_RUN_PIPELINE is assuming a correct configuration, and will 
%    fail without producing informative error messages if there is a problem.
%
% NOTE 3:
%    A "pipeline manager test" means that the test will run in the same 
%    conditions as the pipeline manager (OPT.MODE_PIPELINE_MANAGER).
%
% NOTE 4:
%    A "job manager test" means that the test will run in the same conditions
%    as the job manager: a first process will be started in
%    OPT.MODE_PIPELINE_MANAGER mode, which will itself start a process in 
%    OPT.MODE mode.
%
% Copyright (c) Pierre Bellec, 
% Departement d'informatique et de recherche operationnelle
% Centre de recherche de l'institut de Geriatrie de Montreal
% Universite de Montreal, 2011
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pipeline, PSOM, configuration

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Check syntax and default options %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

psom_gb_vars

if nargin<1||isempty(path_test)
    path_test = gb_psom_path_demo;    
end

if (nargin<3)||isempty(tests)
    tests = {'script_pipe','matlab_pipe','psom_pipe','script_job','matlab_job','psom_job'};
end

if ischar(tests)
    tests = {tests};
end

%% Execution options
list_fields    = {'flag_clean' , 'flag_pause' , 'init_matlab'       , 'flag_update' , 'flag_debug' , 'path_search'       , 'restart' , 'shell_options'       , 'path_logs' , 'command_matlab' , 'flag_verbose' , 'mode'       , 'mode_pipeline_manager' , 'max_queued' , 'qsub_options'       , 'time_between_checks' , 'nb_checks_per_point' , 'time_cool_down' };
list_defaults  = {true         , true         , gb_psom_init_matlab , true          , false        , gb_psom_path_search , {}        , gb_psom_shell_options , []          , ''               , true           , gb_psom_mode , gb_psom_mode_pm         , 0            , gb_psom_qsub_options , []                    , []                    , []               };
if nargin > 1
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
else
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
end
opt.path_logs = fullfile(path_test,'tmp',filesep);

if isempty(opt.mode_pipeline_manager)
    opt.mode_pipeline_manager = opt.mode;
end

if isempty(opt.command_matlab)
    if strcmp(gb_psom_language,'matlab')
        opt.command_matlab = gb_psom_command_matlab;
    else
        opt.command_matlab = gb_psom_command_octave;
    end
end

if ~ismember(opt.mode,{'session','background','batch','qsub','msub'})
    error('%s is an unknown mode of pipeline execution. Sorry dude, I must quit ...',opt.mode);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Show the configuration to the user %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

msg = sprintf('PSOM configuration overview');
stars = repmat('*',[1 length(msg)]);
fprintf('%s\n%s\n%s\n\n',stars,msg,stars);
fprintf('The logs folder is (OPT.PATH_LOGS):\n    %s\n',opt.path_logs);
fprintf('The execution mode of the pipeline manager is (OPT.MODE_PIPELINE_MANAGER):\n    %s\n',opt.mode_pipeline_manager);
fprintf('The execution mode of the job manager is (OPT.MODE):\n    %s\n',opt.mode);
fprintf('%s is called with (OPT.COMMAND_MATLAB):\n    %s\n',upper(gb_psom_language),opt.command_matlab);
if ~isempty(opt.init_matlab)
    fprintf('Every %s session starts with (OPT.INIT_MATLAB):\n    %s\n',upper(gb_psom_language),opt.init_matlab);
end
if ~isempty(opt.shell_options)&&(~strcmp(opt.mode,'session')||~strcmp(opt.mode_pipeline_manager,'session'))
    fprintf('Every shell script starts with (OPT.SHELL_OPTIONS):\n    %s\n',opt.shell_options);
end
if ~isempty(opt.qsub_options)&&(strcmp(opt.mode,'qsub')||strcmp(opt.mode_pipeline_manager,'qsub')||strcmp(opt.mode,'msub')||strcmp(opt.mode_pipeline_manager,'msub'))
    fprintf('QSUB/MSUB is called using the option(s) (OPT.QSUB_OPTIONS):\n    %s\n',opt.qsub_options);
end
fprintf('The following %s search path is used to run the jobs (OPT.PATH_SEARCH):\n',gb_psom_language)
if isempty(opt.path_search)
    fprintf('    Current search path\n    (OPT.PATH_SEARCH = '''')\n')
elseif strcmp(opt.path_search,'gb_niak_omitted')
    fprintf('    The default search path at start-up\n    (OPT.PATH_SEARCH = ''gb_niak_omitted'')\n')
else
    fprintf('    %s\n    (the output may have been truncated, see the output OPT.PATH_SEARCH)\n',opt.path_search(1:min(100,length(opt.path_search))))
end

%% More infos ...
fprintf('\nType "help psom_run_pipeline" for more infos.\n')
fprintf('There is also on on-line tutorial on PSOM configuration\n    http://code.google.com/p/psom/wiki/ConfigurationPsom\n\n')

%% If the pipeline fully runs in session mode, exit
if strcmp(opt.mode,'session')&&strcmp(opt.mode_pipeline_manager,'session')
    fprintf('Both the pipeline and the job managers will be executed in the current session. There is nothing to test !\n')
    return
end

%% Erase the test folder
fprintf('The following folder is going to be emptied before tests are started:\n%s\n',path_test);
fprintf('Press CTRL-C now to stop or any key to continue.\n');
pause
if exist(path_test,'dir')
    rmdir(path_test,'s');
end
psom_mkdir(path_test);

%% Set up the options for PSOM_RUN_SCRIPT
opt_script.path_search    = opt.path_search;
opt_script.init_matlab    = opt.init_matlab;
opt_script.flag_debug     = true;        
opt_script.shell_options  = opt.shell_options;
opt_script.command_matlab = opt.command_matlab;
opt_script.qsub_options   = opt.qsub_options;

%% Start the tests
test_failed = false;
for num_t = 1:length(tests)
    label = tests{num_t};
    switch label
        case 'script_pipe'
            if test_failed
                continue
            end

            % Test description
            msg = sprintf('Running the "%s" test',label);
            stars = repmat('*',[1 length(msg)]);
            fprintf('\n%s\n%s\n%s\n\n',stars,msg,stars);                        
            if strcmp(opt.mode_pipeline_manager,'session')
                fprintf('The execution mode of the pipeline manager is ''session'' ... There is nothing to do !\n')
                continue
            end
            fprintf('Trying to execute a simple command ...\n');

            % Design and start the script
            path_xp = fullfile(path_test,label,filesep);
            psom_mkdir(path_xp);
            opt_script.mode = opt.mode_pipeline_manager;
            if ispc
                script = fullfile(path_xp,[label '.bat']);
            else
                script = fullfile(path_xp,[label '.sh']);
            end
            logs.txt   = fullfile(path_xp,[label '.log']);
            logs.eqsub = fullfile(path_xp,[label '.eqsub']);
            logs.oqsub = fullfile(path_xp,[label '.oqsub']);
            logs.exit  = fullfile(path_xp,[label '.exit']);
            [flag_failed,errmsg] = psom_run_script('',script,opt_script,logs);

            % Debriefing #1 : did the script start ?
            if flag_failed~=0
                if isempty(errmsg)
                    fprintf('\n    The test failed. The script could not be submitted ! \n The feedback was : %s\n',errmsg);
                else
                    fprintf('\n    The test failed. The script could not be submitted ! \n');
                end
                test_failed = true;
                continue

            else
                if ~isempty(errmsg)
                    fprintf('\n    The script was successfully submitted ... The feedback was : %s\n',errmsg);
                else
                    fprintf('\n    The script was successfully submitted ... There was no feedback\n');
                end
            end

            % Debriefing #2 : did the script work ?
            fprintf('Now waiting to see if the script worked ...\nThis could take a while (in qsub/msub modes).\nPress CTRL-C if you think that the job got lost somehow.\nCheck the following files for more infos:\n%s\n%s\n%s\n',logs.txt,logs.eqsub,logs.oqsub)
            while ~psom_exist(logs.exit)
                pause(1)
                fprintf('.')
            end
            fprintf('\nThe test was successful !\n') 
            
        case 'matlab_pipe'

            if test_failed
                continue
            end

            % Test description
            msg = sprintf('Running the "%s" test',label);
            stars = repmat('*',[1 length(msg)]);
            fprintf('\n%s\n%s\n%s\n\n',stars,msg,stars);                        
            if strcmp(opt.mode_pipeline_manager,'session')
                fprintf('The execution mode of the pipeline manager is ''session'' ... There is nothing to do !\n')
                continue
            end
            fprintf('Trying to start matlab from the command line ...\n');

            % Design and start the script
            path_xp = fullfile(path_test,label,filesep);
            psom_mkdir(path_xp);
            opt_script.mode = opt.mode_pipeline_manager;
            if ispc
                script = fullfile(path_xp,[label '.bat']);
            else
                script = fullfile(path_xp,[label '.sh']);
            end
            logs.txt   = fullfile(path_xp,[label '.log']);
            logs.eqsub = fullfile(path_xp,[label '.eqsub']);
            logs.oqsub = fullfile(path_xp,[label '.oqsub']);
            logs.exit  = fullfile(path_xp,[label '.exit']);
            file_test  = fullfile(path_xp,[label '_test.mat']);
            cmd = sprintf('a = clock, save(''%s'',''a'')',file_test);
            [flag_failed,errmsg] = psom_run_script(cmd,script,opt_script,logs);

            % Debriefing #1 : did the script start ?
            if flag_failed~=0
                if isempty(errmsg)
                    fprintf('\n    The test failed. The script could not be submitted ! \n The feedback was : %s\n',errmsg);
                else
                    fprintf('\n    The test failed. The script could not be submitted ! \n');
                end
                test_failed = true;
                continue

            else
                if ~isempty(errmsg)
                    fprintf('\n    The script was successfully submitted ... The feedback was : %s\n',errmsg);
                else
                    fprintf('\n    The script was successfully submitted ... There was no feedback\n');
                end
            end

            % Debriefing #2 : did the script work ?
            fprintf('Now waiting to see if the script worked ...\nThis could take a while (in qsub/msub modes).\nPress CTRL-C if you think that the job got lost somehow.\nCheck the following files for more infos:\n%s\n%s\n%s\n',logs.txt,logs.eqsub,logs.oqsub)
            while ~psom_exist(logs.exit)
                pause(1)
                fprintf('.')
            end
            fprintf('\nThe script has completed \n')
            if psom_exist(file_test)
                fprintf('\nThe test was successful !\n');
            else 
                fprintf('I could not find the file the test was supposed to generate ...\n    %s\n',file_test);
                fprintf('The log of the job was:\n')
                sub_print_log(logs.txt)
                fprintf('\nThe test has failed !\n')
                test_failed = true;
                
            end

        case 'psom_pipe'

            if test_failed
                continue
            end

            % Test description
            msg = sprintf('Running the "%s" test',label);
            stars = repmat('*',[1 length(msg)]);
            fprintf('\n%s\n%s\n%s\n\n',stars,msg,stars);                        
            if strcmp(opt.mode_pipeline_manager,'session')
                fprintf('The execution mode of the pipeline manager is ''session'' ... There is nothing to do !\n')
                continue
            end
            fprintf('Trying to start PSOM ...\n');

            % Design and start the script
            path_xp = fullfile(path_test,label,filesep);
            psom_mkdir(path_xp);
            opt_script.mode = opt.mode_pipeline_manager;
            if ispc
                script = fullfile(path_xp,[label '.bat']);
            else
                script = fullfile(path_xp,[label '.sh']);
            end
            logs.txt   = fullfile(path_xp,[label '.log']);
            logs.eqsub = fullfile(path_xp,[label '.eqsub']);
            logs.oqsub = fullfile(path_xp,[label '.oqsub']);
            logs.exit  = fullfile(path_xp,[label '.exit']);
            file_test  = fullfile(path_xp,[label '_test.mat']);
            file_job   = fullfile(path_xp,[label '_job.mat']);
            command = sprintf('a=clock, save(''%s'',''a'');',file_test);
            save(file_job,'command');
            cmd = sprintf('psom_run_job(''%s'')',file_job);
            [flag_failed,errmsg] = psom_run_script(cmd,script,opt_script,logs);

            % Debriefing #1 : did the script start ?
            if flag_failed~=0
                if isempty(errmsg)
                    fprintf('\n    The test failed. The script could not be submitted ! \n The feedback was : %s\n',errmsg);
                else
                    fprintf('\n    The test failed. The script could not be submitted ! \n');
                end
                test_failed = true;
                continue

            else
                if ~isempty(errmsg)
                    fprintf('\n    The script was successfully submitted ... The feedback was : %s\n',errmsg);
                else
                    fprintf('\n    The script was successfully submitted ... There was no feedback\n');
                end
            end

            % Debriefing #2 : did the script work ?
            fprintf('Now waiting to see if the script worked ...\nThis could take a while (in qsub/msub modes).\nPress CTRL-C if you think that the job got lost somehow.\nCheck the following files for more infos:\n%s\n%s\n%s\n',logs.txt,logs.eqsub,logs.oqsub)
            while ~psom_exist(logs.exit)
                pause(1)
                fprintf('.')
            end
            fprintf('\nThe script has completed \n')
            if psom_exist(file_test)
                fprintf('\nThe test was successful !\n');
            else 
                fprintf('I could not find the file the test was supposed to generate ...\n    %s\n',file_test);
                fprintf('The log of the job was:\n')
                sub_print_log(logs.txt)
                fprintf('\nThe test has failed !\n')
                test_failed = true;
                
            end
        case 'script_job'
        case 'matlab_job'
        case 'psom_job'
        otherwise
            error('Sorry, %s is not a known test',label)
    end
end
if ~test_failed
    msg = sprintf('All tests were successfully completed');
    stars = repmat('*',[1 length(msg)]);
    fprintf('\n%s\n%s\n%s\n\n',stars,msg,stars);            
end

%%%% SUBFUNCTIONS %%%%
function [] = sub_print_log(file_log)
hf = fopen(file_log,'r');
str_read = fread(hf, Inf , 'uint8=>char')';
fclose(hf);
fprintf(str_read)