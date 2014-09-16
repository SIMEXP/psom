#PSOM configuration
This page describes how to customize the runtime environment of PSOM pipelines, to get full advantage of multiple CPUs or distributed computational resources. Many other minor options are available, see the help of `psom_run_pipeline`.  
>The PSOM configuration parameters are located in a file called `psom_gb_vars.m`. Edit this file directly, or copy it under the name `psom_gb_vars_local.m`, to tailor the default configuration to the local production environment.

##Logs folder
The parameter `path_logs` describes where to save the logs. All other options can be set by default.
```matlab
opt.path_logs = '/home/pbellec/svn/psom/trunk/data_demo/';
```

##Execution mode for jobs
The runtime environment of jobs can be set using the `mode` parameter. The default execution mode is `'background'`, which can be changed by setting the variable `gb_psom_mode` in the file `psom_gb_vars.m`. 
```matlab
opt.mode = 'batch';
``` 
 * `'session'`    : The jobs are executed in the current Matlab/Octave session, one after the other.
 * `'background'` : That's the default. Each job is executed in an independent Matlab/Octave session. The jobs are executed in the background using using an "asynchronous" system call. 
 * `'batch'`      : Each job is executed in an independent Matlab/Octave session. The jobs are executed in the background using the `at` command.
 * `'qsub'`       : The jobs are executed through independent submissions to a 'qsub' system (either torque, SGE or PBS).
 * `'msub'`       : The jobs are executed through independent submissions to a 'msub' MOAB system.
>For `batch` mode on OpenSUSE, the system administrator needs to authorize the "at" command. On Mac OSX, to use `batch`, type the following line in a terminal ```batch sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist``` 

##Number of parallel jobs
The `max_queued` option sets the maximal number of jobs that can be processed simultaneously. 
```matlab
opt.max_queued = 2;
```
The default for `max_queued` is 2, see `gb_psom_max_queued` in `psom_gb_vars.m`.
>`max_queued` is useful in `'batch'` mode (it is the number of processors) and maybe in `'qsub'` or `'msub'` mode (if there is a limit on the number of jobs a user can submit simultaneously).

##Pipeline manager
The pipeline manager is the process responsible to start the jobs, and its execution mode is set with `mode_pipeline_manager`. All the execution modes available for jobs are also available for the pipeline manager. The default is `'session'` (see `gb_psom_mode_pipeline_manager` in `psom_gb_vars.m`). 
```matlab
opt.mode_pipeline_manager = 'batch';
```
>The execution mode of the pipeline manager is often different from the one of the jobs. For example, if jobs run through `qsub`, the pipeline manager can run in `batch` as this process uses minimal memory and CPU.

##MORE verbose 
For Octave users, the default verbose mode is using a tool called "more". PSOM works better without "more". To disable "more", simply type `more off` is Octave. 
>>To make this change permanent, add the line `more off` to the file `~/.octaverc`. 

#Testing a configuration
The function called `psom_config` will test the process of job submission step-by-step, and generate context-specific error messages, as well as suggestions to fix the configuration. 
>`psom_run_pipeline` will not necessarily produce informative error messages when the configuration is incorrect, because of some choices made to speed up the execution.

#Examples

##All local
Run PSOM in the current session.
```matlab
opt.path_logs = '~/test_logs/';
opt.mode = 'session';
opt.mode_pipeline_manager = 'session';
```

##All batch
Run PSOM in batch mode using 8 cores.
```matlab
opt.path_logs = '~/test_logs/';
opt.mode = 'batch';
opt.mode_pipeline_manager = 'batch';
opt.max_queued = 8;
```

##Batch and qsub

Run the pipeline manager in `batch` mode and the jobs through `qsub`, using 100 cores.
```matlab
opt.path_logs = '~/test_logs/';
opt.mode = 'qsub';
opt.mode_pipeline_manager = 'batch';
opt.max_queued = 100;
```
