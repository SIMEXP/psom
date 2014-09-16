You can copy/paste the code of [`psom_demo_pipeline`](https://github.com/SIMEXP/psom/blob/master/psom_demo_pipeline.m) and execute it block by block to replicate this tutorial. The demo will create a folder `psom_demo` in the current direction, and generate several files inside of it. To restart the demo from scratch, simply delete this folder. Minor options not covered in this tutorial can be found in the help of [psom_run_pipeline](https://github.com/SIMEXP/psom/blob/master/psom_run_pipeline.m).

# Code a pipeline 

## Syntax
A `job` is a Matlab/Octave command that takes files as inputs and produce files as outputs, along with some optional parameters. A `pipeline` is a just a list of jobs. Each field of the pipeline is describing one job, including the following subfields. `command` describes the matlab/octave command line(s) executed by the job. `opt` (optional) contains any variable that is used by the job. `files_in` and `files_out` (optional) respectively describe the lists of input and output files, using either a string, a cell of strings or a nested structure whose terminal fields are strings/cell of strings. 
```matlab
%% An example of (toy) pipeline

% where to generate the outputs of the demo
clear, path_demo = [pwd filesep 'demo_psom' filesep]; 

% Job "sample" :    No input, generate a random vector a
command = 'a = randn([opt.nb_samps 1]); save(files_out,''a'')';
pipeline.sample.command      = command;
pipeline.sample.files_out    = [path_demo 'sample.mat'];
pipeline.sample.opt.nb_samps = 10;

% Job "quadratic" : Compute a.^2 and save the results
command = 'load(files_in); b = a.^2; save(files_out,''b'')';
pipeline.quadratic.command   = command;
pipeline.quadratic.files_in  = pipeline.sample.files_out;
pipeline.quadratic.files_out = [path_demo 'quadratic.mat']; 

% Adding a job "cubic" : Compute a.^3 and save the results
command = 'load(files_in); c = a.^3; save(files_out,''c'')';
pipeline.cubic.command       = command;
pipeline.cubic.files_in      = pipeline.sample.files_out;
pipeline.cubic.files_out     = [path_demo 'cubic.mat']; 

% Adding a job "sum" : Compute a.^2+a.^3 and save the results
command = 'load(files_in{1}); load(files_in{2}); d = b+c, save(files_out,''d'')';
pipeline.sum.command       = command;
pipeline.sum.files_in{1}   = pipeline.quadratic.files_out;
pipeline.sum.files_in{2}   = pipeline.cubic.files_out;
pipeline.sum.files_out     = [path_demo 'sum.mat'];
```

## Dependencies

The inputs of the job `sum` are the outputs of the jobs `quadratic` and `cubic`. As a consequence, the jobs `quadratic` and `cubic` need to be completed before the job `sum` can start. PSOM can figure that out by analyzing the input and output file names. PSOM builds a directed graph of dependencies between the jobs, which can be visualized if the bioinformatics toolbox (or the [graphviz package](http://www.graphviz.org/) is installed.
```matlab
%% Visualize the dependency graph
psom_visu_dependencies(pipeline)
```

>![An example of pipeline dependency graph](https://raw.githubusercontent.com/SIMEXP/psom/master/demo_pipe1.jpg)

## Execution
The only required option to run the pipeline is the `opt.path_logs`, i.e. the name of the logs folder (the "memory" of PSOM). Other options (e.g. `opt.mode`, `opt.max_queued`) are available to specify how to execute the job. In this example, two processes are used in the background, i.e. outside of the current matlab/octave session. See the [PSOM configuration](psom_configuration.html) tutorial for more configuration options.  Finally, a call to `psom_run_pipeline` will execute the pipeline. 
```matlab
opt.path_logs = [path_demo 'logs' filesep]; 
opt.mode = 'background';
opt.max_queued = 2;
psom_run_pipeline(pipeline,opt)
```
>```matlab
(...)
*******************************************                                                      
The pipeline PIPE is now being processed.
Started on 16-Sep-2014 11:34:48
user: pbellec, host: merisier, system: unix
*******************************************
16-Sep-2014 11:34:48 sample    submitted (1 run / 0 fail / 0 done / 3 left)
16-Sep-2014 11:34:48 sample    completed (0 run / 0 fail / 1 done / 3 left)
16-Sep-2014 11:34:48 quadratic submitted (1 run / 0 fail / 1 done / 2 left)
16-Sep-2014 11:34:48 cubic     submitted (2 run / 0 fail / 1 done / 1 left)
16-Sep-2014 11:34:49 quadratic completed (1 run / 0 fail / 2 done / 1 left)
16-Sep-2014 11:34:49 cubic     completed (0 run / 0 fail / 3 done / 1 left)
16-Sep-2014 11:34:49 sum       submitted (1 run / 0 fail / 3 done / 0 left)
16-Sep-2014 11:34:49 sum       completed (0 run / 0 fail / 4 done / 0 left)
*********************************************
The processing of the pipeline is terminated.
See report below for job completion status.
16-Sep-2014 11:34:49
*********************************************
All jobs have been successfully completed.
```

# Update a pipeline

## Change a job

If the pipeline is executed again using the same logs folder, PSOM is going to compare the old and current pipeline and figure out by itself which jobs need to be reprocessed. 
```matlab
% Change the job quadratic to introduce a bug
pipeline.quadratic.command = 'BUG!';
psom_run_pipeline(pipeline,opt)
```
>```matlab
(...)
Setting up the to-do list. The following jobs will be executed ...
    quadratic (changed)
    sum       (child of a restarted job)
(...)
16-Sep-2014 11:46:07 quadratic submitted (1 run / 0 fail / 2 done / 1 left)
16-Sep-2014 11:46:07 quadratic failed    (0 run / 1 fail / 2 done / 1 left)
(...)
All jobs have been processed, but some jobs have failed.
You may want to restart the pipeline latter if you managed to fix the problems.
```

If a job fails, it is possible to display the log of the failed job to understand what happened.
```matlab
psom_pipeline_visu(opt.path_logs,'log','quadratic'); 
```

>```matlab
(...)
Something went bad ... the job has FAILED !
The last error message occured was :
parse error:
  syntax error
>>> BUG!
File /home/pbellec/git/psom/psom_run_job.m at line 214
File /home/pbellec/git/psom/psom_run_job.m at line 128
(...)
```

If the job `quadratic` is fixed, the pipeline will complete without problem. Note that the job `sum` will also be restarted, because it depends on `quadratic`.
```matlab
pipeline.quadratic.command   = ...
   'load(files_in); b = a.^2; save(files_out,''b'')';
psom_run_pipeline(pipeline,opt);
```
>```matlab
(...)
All jobs have been successfully completed.
```

## Add a job
It is possible to add new jobs to the pipeline (or remove old jobs).
```matlab
pipeline.cleanup.command     = 'delete(files_clean)';
pipeline.cleanup.files_clean = pipeline.sample.files_out;
psom_run_pipeline(pipeline,opt);
```
>```matlab
(...)
Setting up the to-do list. The following jobs will be executed ...
    cleanup   (new)
(...)
16-Sep-2014 14:02:17 cleanup   submitted (1 run / 0 fail / 4 done / 0 left)
16-Sep-2014 14:02:18 cleanup   completed (0 run / 0 fail / 5 done / 0 left)
(...)
All jobs have been successfully completed.
```

This example introduces a new job subfield,  `files_clean`, which lists the files deleted by a job. As the job `cleanup` will delete a file that is used as an input by `quadratic` and `cubic`, it is necessary to wait that both of these jobs have completed their execution before starting `cleanup`. 
>![An example of pipeline dependency graph](https://raw.githubusercontent.com/SIMEXP/psom/master/demo_pipe2.jpg)

## Restart a job
It is possible to manually force a job (e.g. `quadratic`) to restart with `opt.restart`. Note that the restart mechanism it tolerant to missing files (previously deleted by `cleanup`).
```matlab
opt.restart = {'quadratic'};
psom_run_pipeline(pipeline,opt);
```
>```matlab
(...)
Setting up the to-do list. The following jobs will be executed ...
    quadratic (manual restart)
    sum       (child of a restarted job)
    cleanup   (child of a restarted job)
    sample    (produce necessary files)
    cubic     (child of a restarted job)
(...)
All jobs have been successfully completed.
```

#Monitor a pipeline
The log folder tracks all processing steps, options and logs into .mat files. Some of these info can be extracted using `psom_pipeline_visu`.

## Display flowchart

The flowchart of the pipeline is visualized with the `'flowchart'` option.
```matlab
psom_pipeline_visu(opt.path_logs,'flowchart');
```
>![An example of pipeline dependency graph](https://raw.githubusercontent.com/SIMEXP/psom/master/demo_pipe2.jpg)

## List the jobs

The jobs can also be listed based on their current status (either `'none'`, `'failed'` or `'finished'`). 
```matlab
psom_pipeline_visu(opt.path_logs,'finished');
```
>```matlab
***********************
List of finished job(s)
***********************
cleanup
cubic
quadratic
sample
sum
```

## Display log
The log of any job can be displayed with the `'log'` argument, followed by the name of the job.
```matlab
psom_pipeline_visu(opt.path_logs,'log','quadratic');
```

```matlab
*****************************
Log of the (octave) job : quadratic
Started on 16-Sep-2014 14:41:02
User: pbellec
host : merisier
system : unix
*****************************
The job starts now !
********************

****************
Checking outputs
****************
The output file or directory /home/pbellec/tmp/demo_psom/quadratic.mat was successfully generated!

*********************************************************
16-Sep-2014 14:41:02 : The job was successfully completed
Total time used to process the job : 0.01 sec.
*********************************************************
```

## Display computation time
The `'time'` parameter generates a summary of the effective computation time for all of the jobs. Note that the last argument can be used to select only a subpart of the pipeline (e.g. 'cubic').
```matlab
psom_pipeline_visu(opt.path_logs,'time','')
```
>```matlab
**********
cleanup   : 0.08 s, 0.00 mn, 0.00 hours, 0.00 days.
cubic     : 0.05 s, 0.00 mn, 0.00 hours, 0.00 days.
quadratic : 0.07 s, 0.00 mn, 0.00 hours, 0.00 days.
sample    : 0.05 s, 0.00 mn, 0.00 hours, 0.00 days.
sum       : 0.10 s, 0.00 mn, 0.00 hours, 0.00 days.
**********
Total computation time :  0.35 s, 0.01 mn, 0.00 hours, 0.00 days.
```

##History
It is possible to access the pipeline history (concatenated over all executions, and with updates) using the `'monitor'` parameter. The result of this command is not listed here, because it recapitulates everything that has been done so far in the tutorial and is therefore quite lengthy.
```matlab
>> psom_pipeline_visu(opt.path_logs,'monitor')
(...)
```

# Misc

##Temporary files
There are two functions to generate temporary files or folders in PSOM, `psom_file_tmp` and `psom_path_tmp`. In both cases, PSOM will generate a random name, using a user-specified suffix. Before attributing the name, PSOM will check that this name is not already used (in which case it will generate another random name). As soon as the name has been selected, an empty file name or directory is automatically created. Moreover, if these commands are called as part of a job, the job name is automatically added in the temporary name. All these features ensure that there will be no conflict of temporary names between jobs, even if the same pipeline is executed multiple times on a single machine. By default, the name of the temporary folder is the default of the system (as defined by the `tempdir` variable). This can be changed using the `gb_psom_tmp` variable defined in `psom_gb_vars.m`.
```matlab
>> file_tmp = psom_file_tmp('_suffix')
file_tmp = /tmp/psom_tmp_359007_suffix
>> path_tmp = psom_path_tmp ('_suffix')
path_tmp = /tmp/psom_tmp_44068_suffix/
```

##Random number generator 
When running Monte Carlo simulations, it is critical to take a great care setting up the state of the random number generator. The way to perform this operation has changed with versions of Matlab, and is not currently the same in Matlab and Octave. There is a PSOM command called `psom_set_rand_seed` which will set the state of the Gaussian and uniform random number generator. `psom_set_rand_seed` will work in all versions and languages. If called without an input, the function uses the clock to set the state of the generator. By default, this is what PSOM does for each job. If the results of the pipeline have to be reproducible, use the `psom_set_rand_seed` command to set a fixed seed (e.g. 0) for each job. However, in some Monte Carlo simulations, the only thing that changes from one job to another is exactly the seed of the random number generator. In that case, it is possible to generate a list of seeds once, which are then fed into the jobs as an input parameter for `psom_set_rand_seed`.
```matlab
>> psom_set_rand_seed(0);
>> rand(2)
ans =

   0.84442   0.42057
   0.75795   0.25892
>> psom_set_rand_seed(0);
>> rand(2)
ans =

   0.84442   0.42057
   0.75795   0.25892
```