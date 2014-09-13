This page describes how to customize the runtime environment of PSOM pipelines. The only necessary option describes where to save the logs. All other options could be set by default. By changing these options, it is possible to get full advantage of multiple CPUs or even distributed computational resources. 

```matlab
>> opt.path_logs = '/home/pbellec/svn/psom/trunk/data_demo/';
```

#PSOM configuration

##Psom defaults
All the configuration variables of PSOM are stored in a file called `psom_gb_vars.m`. This file can be edited to tailor the default configuration to the local production environment. In the case where the file `psom_gb_vars` cannot be edited directly, it is possible to copy this file under the name `psom_gb_vars_local.m` and edit this file instead. As long as `psom_gb_vars_local.m` is found in the Matlab/Octave search path, regardless where it is located, it will override the settings found in `psom_gb_vars.m`.

##Jobs
The runtime environment of jobs can be set using the `opt.mode` option, example :
```matlab
opt.mode = 'batch';
```
Five modes are available: 
* `'session'` : The jobs are executed in the current Matlab/Octave session, one after the other.
* `'background'` : That's the default. Each job is executed in an independent Matlab/Octave session. The jobs are executed in the background using using an "asynchronous" system call. 
* `'batch'` : Each job is executed in an independent Matlab/Octave session. The jobs are executed in the background using the `at` command. 
* `'qsub'` : The jobs are executed through independent submissions to a 'qsub' system (either torque, SGE or PBS).
* `'msub'` : The jobs are executed through independent submissions to a 'msub' MOAB system.
The `'qsub'` and `'msub'` modes are using tools available in supercomputing centers to submit a job for execution on one of multiple machines or cores. By contrast, the `'background'`, `'batch'` and `'session'` modes work locally on your machine. The default execution mode is `'background'`, which can be changed by setting the variable `gb_psom_mode` in the file `psom_gb_vars.m`. The main difference between the `'background'` and the '`batch`' mode is that the former will be interrupted if the Matlab/Octave session is interrupted, while with the latter the pipeline will keep on working even if the use exits Matlab/Octave and unlogs from his/her machine. The `'background'` mode is set by default because it will work on all systems (while `'batch'` sometimes requires changing some of the system's settings). Note that on Linux the [screen](http://www.rackaid.com/resources/linux-screen-tutorial-and-how-to/) command can be used in combination with the `'background'` mode. 

Another important option sets the maximal number of jobs that can potentially be processed simultaneously. That is usefull in `'batch'` mode (this maximal number is the number of processors) and maybe in `'qsub'` mode (if the system administrator has set a limit on the number of jobs per user). Example:
```matlab
>> opt.max_queued = 2;
```
The default for this option is `1` in `'batch'` mode, and `Inf` in all other modes. This default can be changed by setting the variable `gb_psom_max_queued` in the file `psom_gb_vars.m`.

##Pipeline manager
The pipeline manager is the part of PSOM that submits the jobs. It is just a long loop that constantly monitors the state of the pipeline, and submits jobs whenever possible. It is sometimes desirable to run the pipeline manager in a different mode than the jobs. For example, if jobs are executed through `qsub`, one may still want to run the pipeline manager in `batch` to avoid wasting a full slot for a process that is hardly using any memory or CPU. The runtime mode of the pipeline manager can be set using a specific option : 
```matlab
>> opt.mode_pipeline_manager = 'batch';
```
All the execution modes available for jobs are also available for the pipeline manager. The default is `'session'`. This can be changed by setting the variable `gb_psom_mode_pipeline_manager` in the file `psom_gb_vars.m`.

##Batch mode
On some systems, the "at" command is not available to regular users for security reasons. That's the case at least on Mac OSX and openSUSE. This command is used by PSOM in the so-called `'batch'` mode (see below). Note that the 'background' mode offers a PSOM experience that is very close to 'batch', and will work "out-of-the-box" on all systems. To enable "at" on Mac OSX, type the following line in a terminal:
```matlab
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist
```
On OpenSUSE, please contact your system administrator to open "at" to regular users. 


# System configuration

##Octave configuration
There are other system configuration settings that can be adjusted in some environments. For Octave users, the default verbose mode is using a tool called "more". The PSOM verbose mode works better without "more". To disable "more", simply type on the command line:
```matlab
more off
```
To make this change permanent, edit the file `.octaverc` in your home directory, and add the line above. 

##Qsub/Msub options
The string `opt.qsub_options` is used as an argument when invoking `qsub`. It can be used to specify the queue to submit job, or any other qsub option:
```matlab
opt.qsub_options = '-q brain';
```
The default is an empty string `''` but this can be changed by setting the variable `gb_psom_qsub_options` in the file `psom_gb_vars.m`. Note that despite its name, `qsub_options` actually applies both to `qsub` and `msub` modes.

##Shell options
In all modes but `'session'`, the jobs are executed in their own matlab sessions started from a shell. It is possible to run a couple of shell commands before matlab is started, for example to modify the shell environment if your job is using some system calls. This is done by specifying for example:
```matlab
opt.shell_options = 'source ~/psom/example_init_qsub.sh';
```
where the script `example_init_qsub.sh` may look like:
```matlab
export PATH=$PATH:/usr/local/minc_tools
export MINC_COMPRESS=0
unset MINC_FORCE_V2
```
The default value is an empty string `''`, but this can be changed by setting the variable `gb_psom_shell_options` in the file `psom_gb_vars.m`. Note that PSOM is using the default shell on your system, and is not forcing any specific type of shell such as sh or csh.

##Invoking Matlab/Octave

There is an option to specify how to invoke matlab :
```matlab
>> opt.command_matlab = 'matlab'
```
By default, PSOM is using the version of matlab that was used to invoke PSOM, including the local full path access (i.e. something like `/usr/bin/matlab', or `/usr/bin/octave` in an Octave environment). Note that PSOM is using additional options to start Matlab/Octave `-nosplash -nojvm` and `--silent` respectively (in Linux/Mac OSX, the Windows options are different), to get rid of any unnecessary graphical effects. It is possible to change the PSOM defaults by editing the variables `gb_psom_command_matlab` and `gb_psom_command_octave` in the file `psom_gb_vars`.

##Matlab/Octave initialization

There is an option to specify a set of commands that will be executed at matlab startup :
```matlab
>> opt.init_matlab = 'fprintf(''Matlab version %s\n'',version)';
```
This example would verbose the version of matlab at the begining of each job. 

Note that this is only relevant when the pipeline manager executes jobs in 'batch', 'qsub' or 'msub' modes, i.e. it is not used in 'session' mode. By default there is no initialization, which means the value is the empty string `''`. It is possible to change this default by editing the variable `gb_psom_init_matlab` in the file `psom_gb_vars`.

##Matlab/Octave search path

There is an option to set up the matlab search path : 
```matlab
>> path_current = matlabpath;
>> opt.path_search = path_current;
```
This is the default behaviour, i.e. PSOM is using the current search path when the user calls ``psom_run_pipeline``. This may be problematic in one instance : if the folder where matlab is installed on the master node (where PSOM is started) is different from the folder where matlab is installed on the cluster nodes (where the jobs are executed). In this tricky situation, Matlab will get confused because the access path to its toolbox will no longer be available. There is a workaround though : 
```matlab
>> opt.path_search = '';
```
In this case, PSOM will not change the search path. It is always possible to use some `genpath` and `addpath` commands in `opt.init_matlab` to add some folders to the search path.

#Minor tweaks 
There are a couple of additional options to change some aspects of PSOM behaviour. These "minor" options are reviewed below : 

##Debug
If something is going wrong in the submission of the pipeline manager or the jobs, it may be hard to figure out why with the standard level of verbose. The following option can be used to increase the amount of verbose:
```matlab
opt.flag_debug = true;
```
By default ``flag_debug`` is false. When it is true, PSOM will provide additional information on the command which was used to submit each job and the pipeline manager, as well as the response from the system to each of these submissions. It is however recommended to use `psom_config` to identify and solve problems of configuration.

##Update
In general PSOM will compare the current pipeline submitted by the user to whatever older pipeline was executed in the same log folder. This is one of the most powerful features of PSOM, i.e. its ability to figure out "by itself" what jobs have changed and what needs to be restarted. This behaviour may sometimes not be desirable, i.e. the user have decided to change the folder where the results are stored, so all the intermediate results and associated jobs have changed even though no actual change in the processing was done. It is then possible to turn off the "update" mechanism using the following option :
```matlab
opt.flag_update = false;
```
By default that option is true.

##Clean
Before executing a pipeline, PSOM will remove any file which will eventually be generated by one of the scheduled jobs. This is to avoid possible confusion regarding the time of generation of a particular output, and crashes due to jobs that are unable to overwrite previous results. If a lot of files need to be cleared, this can take a while at the initialization phase because matlab/octave is making a single system call per file. If the issues mentioned above are not critical, it is possible to skip this step altogether by using the following option :
```matlab
opt.flag_clean = false;
```
By default this option is true.

##Pause
After initializing the pipeline, PSOM is going to print a summary of the actions taken on jobs and wait for the user to hit a key before anything is actually written on the disk. This lets the opportunity to the user to cancel the operation if the actions planned by PSOM do not meet their expectations. This can be disabled using the following option :
```matlab
opt.flag_pause = false;
```
By default this option is true.

##Time between checks
The time (in seconds) where the pipeline processing remains inactive to wait for jobs to complete before attempting to submit new jobs can be changed with the following option :
```matlab
opt.time_between_checks = 10;
```
The default value is 10 seconds.

##Random number generator
Note that Matlab random number generator uses the same initial value at each session, which means that the exact same random numbers will be produced. As a result, if jobs are executed in independent matlab sessions, i.e. the 'batch', 'qsub' or 'msub' modes, the random numbers will be identical for all jobs. By contrast, jobs executed sequentially within a session will be based on different random number sequences. As of PSOM release 0.8.5, the random number generator is initialized independently for each job based on the CPU time. This is the default behaviour in Octave 3.x. In order to be able to replicate computations, one would have to set the initialization for the random number generator at a fixed value as part of the job. See the dedicated section in the [http://code.google.com/p/psom/wiki/CodingGuidelines#Jobs coding guidelines wiki page].

#Examples

##All local
The following options will run PSOM in the current session :
```matlab
opt.path_logs = '~/test_logs/';
opt.mode = 'session';
opt.mode_pipeline_manager = 'session';
```

##All batch
The following options will run PSOM in batch mode using 8 cores:
```matlab
opt.path_logs = '~/test_logs/';
opt.mode = 'batch';
opt.mode_pipeline_manager = 'batch';
opt.max_queued = 8;
```

##Batch and qsub

The following options will run the pipeline manager in batch mode (it hardly uses resources anyway) and the jobs through qsub using 100 cores:
```matlab
opt.path_logs = '~/test_logs/';
opt.mode = 'qsub';
opt.mode_pipeline_manager = 'batch';
opt.max_queued = 100;
```

##Batch and qsub with init
The following options will run the pipeline manager in batch mode (it hardly uses resources anyway) and the jobs through qsub to the so-called "brain" queue, using 100 cores. The pipeline is configured to use the local search path of the cluster nodes with an additional folder which is included at matlab startup. A variable MINC_COMPRESS is also defined in the shell before starting Octave/Matlab.
```matlab
opt.path_logs = '~/test_logs/';
opt.mode = 'qsub';
opt.mode_pipeline_manager = 'batch';
opt.shell_options = 'export MINC_COMPRESS=0';
opt.qsub_options = '-q brain';
opt.path_search = '';
opt.init_matlab = 'P = genpath(''~/my_toolbox/''); addpath(P);';  
opt.max_queued = 100;
```

#Testing a configuration
When PSOM is executing a pipeline, it assumes that the configuration is correct. If it is a case, any job failure will not crash PSOM itself, which will generate a comprehensive failure report. However, if the configuration is not correct, PSOM will not necessarily produce informative error messages. This is because a number of choices were made to speed up the PSOM execution that prevent to properly catch errors. There is however a function called `psom_config` that will test step-by-step the process of job submission, and generate context-specific error messages and suggestions to fix the configuration. See the [http://code.google.com/p/psom/wiki/TestPsom test page] for a list of the systems/configurations that have already been tested.