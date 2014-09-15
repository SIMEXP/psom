# Code a pipeline 

## Syntax
A `job` is a Matlab/Octave command that takes files as inputs and produce files as outputs, along with some optional parameters. 
```matlab
psom_gb_vars

% Job "sample" :    No input, generate a random vector a
command = 'a = randn([opt.nb_samps 1]); save(files_out,''a'')';
pipeline.sample.command      = command;
pipeline.sample.files_out    = [gb_psom_path_demo 'sample.mat'];
pipeline.sample.opt.nb_samps = 10;
```

A `pipeline` is a just a list of jobs. You can copy/paste the code of [`psom_demo_pipeline`](https://github.com/SIMEXP/psom/blob/master/psom_demo_pipeline.m) and execute it block by block to replicate this tutorial. 
```matlab
% Job "quadratic" : Compute a.^2 and save the results
command = 'load(files_in); b = a.^2; save(files_out,''b'')';
pipeline.quadratic.command   = command;
pipeline.quadratic.files_in  = pipeline.sample.files_out;
pipeline.quadratic.files_out = [gb_psom_path_demo 'quadratic.mat']; 

% Adding a job "cubic" : Compute a.^3 and save the results
command = 'load(files_in); c = a.^3; save(files_out,''c'')';
pipeline.cubic.command       = command;
pipeline.cubic.files_in      = pipeline.sample.files_out;
pipeline.cubic.files_out     = [gb_psom_path_demo 'cubic.mat']; 

% Adding a job "sum" : Compute a.^2+a.^3 and save the results
command = 'load(files_in{1}); load(files_in{2}); d = b+c, save(files_out,''d'')';
pipeline.sum.command       = command;
pipeline.sum.files_in{1}   = pipeline.quadratic.files_out;
pipeline.sum.files_in{2}   = pipeline.cubic.files_out;
pipeline.sum.files_out     = [gb_psom_path_demo 'sum.mat'];
```

Each field of the pipeline is describing one job. The only variables available to execute the `command` are `files_in`, `files_out` and `opt`. These variables are assigned by default empty values. 
>* `command` describes the matlab/octave command line(s) executed by the job. 
>* `opt` contains any variable that is used by the job.  
>* `files_in` and `files_out` respectively describe the lists of input and output files, using either a string, a cell of strings or a nested structure whose terminal fields are strings/cell of strings.

## Dependencies

It is now possible to run the pipeline using `psom_run_pipeline`. Note that for example the inputs of the job `sum` are the outputs of the jobs `quadratic` and `cubic`. As a consequence, the jobs `quadratic` and `cubic` need to be completed before the job `sum` can start. The pipeline manager can figure that out by analyzing the input and output file names and it will build a directed graph of dependencies between the jobs (aka flowchart). It is possible to visualize this graph if the bioinformatics toolbox (or the [package](http://www.graphviz.org/ graphviz) is installed : 
```matlab
>> psom_visu_dependencies(pipeline)
      dot - graphviz version 2.26.3 (20100126.1600)
       Reorganizing inputs/outputs ... 0.03 sec
       Analyzing job inputs/outputs, percentage completed :  25 50 75 100- 0.04 sec
```

>![An example of pipeline dependency graph](https://raw.githubusercontent.com/SIMEXP/psom/master/demo_pipe1.jpg)

## Options
The only option that is really necessary to run the pipeline is the name of the logs folder (the "memory" of PSOM). That folder does not have to be created beforehand : 
```matlab
>> opt.path_logs = '/home/pbellec/svn/psom/trunk/data_demo/';
```
The pipeline manager will write (and delete) a bunch of files in the logs folder. It is therefore important that the log folder is left intact at any time or otherwise the pipeline manager may experience an unrecoverable crash. There are a couple of additional options : 
```matlab
>> opt.mode = 'background';
```
This option sets the environment where the jobs are processed. Here the jobs will run in independent Matlab/Octave sessions, in the background.  Another important option is `max_queued`, which sets the maximal number of jobs that can be processed simultaneously. See the [PSOM configuration](http://code.google.com/p/psom/wiki/ConfigurationPsom) tutorial for mode details.  
```matlab
>> opt.max_queued = 2;
```

## Execution
Now running the pipeline is straightforward, it is just a call to the pipeline manager. Note that to limit the length of the tutorial, some initial initialization infos `(...)` have not been reproduced. In particular, the pipeline manager has checked that the dependency graph is acyclic and that no output was created twice. It has also created all the folders that will store outputs, and deleted outputs that already existed prior to the pipeline execution. There are still other options for the pipeline manager, some of which will be covered in the next section of the tutorial. See the help of `psom_run_pipeline` for details.

```matlab
>> psom_run_pipeline(pipeline,opt)
(...)
*****************************************
The pipeline PIPE is now being processed.
Started on 08-Nov-2011 13:16:55
user: pbellec, host: berry, system: unix
*****************************************
08-Nov-2011 13:16:55 - The job sample    has been submitted to the queue (1 running / 0 failed / 0 finished / 3 left).
08-Nov-2011 13:17:09 - The job sample    has been successfully completed (0 running / 0 failed / 1 finished / 3 left).
08-Nov-2011 13:17:09 - The job quadratic has been submitted to the queue (1 running / 0 failed / 1 finished / 2 left).
08-Nov-2011 13:17:09 - The job cubic     has been submitted to the queue (2 running / 0 failed / 1 finished / 1 left).
08-Nov-2011 13:17:13 - The job quadratic has been successfully completed (1 running / 0 failed / 2 finished / 1 left).
08-Nov-2011 13:17:13 - The job cubic     has been successfully completed (0 running / 0 failed / 3 finished / 1 left).
08-Nov-2011 13:17:13 - The job sum       has been submitted to the queue (1 running / 0 failed / 3 finished / 0 left).
08-Nov-2011 13:17:16 - The job sum       has been successfully completed (0 running / 0 failed / 4 finished / 0 left).
*********************************************
The processing of the pipeline is terminated.
See report below for job completion status.
08-Nov-2011 13:17:17
*********************************************
All jobs have been successfully completed.
```

# Update a pipeline

## Change options

A common reason for restarting a pipeline is to change one of the jobs. If you restart the pipeline manager using the same logs folder as the first time, PSOM is going to compare the old and current pipeline and figure out by himself which jobs have changed. It is going to restart those jobs only, along with any job that uses even indirectly the outputs of a restarted job. For example, let's change the `quadratic` job (adding a bug) and restart the pipeline manager : 
```matlab
% Changing the job quadratic to introduce a bug
>> pipeline.quadratic.command = 'BUG!';
% Restart the pipeline
>> psom run pipeline(pipeline,opt pipe)
(...)
*****************************************
The pipeline PIPE is now being processed.
Started on 08-Nov-2011 13:37:41
user: pbellec, host: berry, system: unix
*****************************************
08-Nov-2011 13:37:41 - The job quadratic has been submitted to the queue (1 running / 0 failed / 2 finished / 1 left).
08-Nov-2011 13:37:43 - The job quadratic has failed                      (0 running / 1 failed / 2 finished / 1 left).

*********************************************
The processing of the pipeline is terminated.
See report below for job completion status.
08-Nov-2011 13:37:53
*********************************************
The execution of the following job has failed :

    quadratic ; 

More infos can be found in the individual log files. Use the following command to display these logs :

    psom_pipeline_visu('/home/pbellec/database/demo_psom/logs/','log',JOB_NAME)

The following job has not been processed due to a dependence on a failed job or the interruption of the pipeline manager :

    sum ; 

All jobs have been processed, but some jobs have failed.
You may want to restart the pipeline latter if you managed to fix the problems.
```

The pipeline manager is recapitulating the list of the jobs that failed, and those that could not be processed. It also kindly points out that it is possible to display the log of the failed job to understand what happened : 
```matlab
>> psom_pipeline_visu(opt.path_logs,'log','quadratic');
********************************************
  Log file of job quadratic (status failed) 
********************************************

command = BUG!
files_in = /home/pbellec/database/demo_psom/sample.mat
files_out = /home/pbellec/database/demo_psom/quadratic.mat
files_clean = {}(0x0)
opt = {}(0x0)

******************************
Log of the (octave) job : quadratic
Started on 08-Nov-2011 13:40:27
User: pbellec
host : berry
system : unix
******************************

********************
The job starts now !
********************


********************
Something went bad ... the job has FAILED !
The last error message occured was :
parse error:

  syntax error

>>> BUG!
       ^

File /home/pbellec/svn/psom/trunk/psom_run_job.m at line 203
File /home/pbellec/svn/psom/trunk/psom_run_job.m at line 125

****************
Checking outputs
****************
The output file or directory /home/pbellec/database/demo_psom/quadratic.mat has not been generated!

**********************************************
08-Nov-2011 13:40:27 : The job has FAILED
Total time used to process the job : 0.05 sec.
**********************************************
```
Of course, `BUG` is not a correct matlab command, what was I thinking ! It is now time to fix the 'quadratic' job :
```matlab
command = 'load(files_in); b = a.^2; save(files_out,''b'')';
pipeline.quadratic.command   = command;
psom_run_pipeline(pipeline,opt);
(...)
```
This time the pipeline is completing without problem. Note that the job ''sum'' is also restarted, because it depends on ''quadratic''.

## Add a job
This section deals with restarting the pipeline after adding new jobs. That would occur for example when processing a larger dataset than in the first pass. For example, This code defines a new job `cleanup` to the pipeline.
```matlab
pipeline.cleanup.command     = 'delete(files_clean)';
pipeline.cleanup.files_clean = pipeline.sample.files_out;
```
The job clean-up is using a new type of attributes 'files_clean'. This means that the job `cleanup` will delete a file, here the output of `sample`. Because `quadratic` and `cubic` are using that file, it is necessary to wait that both of these jobs have completed their execution before starting `cleanup`. The new dependency graph is shown on the right.
>![An example of pipeline dependency graph](https://raw.githubusercontent.com/SIMEXP/psom/master/demo_pipe2.jpg)

PSOM will let you add the new job without complaint. Of course the jobs that were finished will not be reprocessed. Note that it is also possible to remove jobs from the pipeline.
```matlab
>> psom_run_pipeline(pipeline,opt);
(...)
*****************************************
The pipeline PIPE is now being processed.
Started on 08-Nov-2011 13:48:10
user: pbellec, host: berry, system: unix
*****************************************
08-Nov-2011 13:48:11 - The job cleanup   has been submitted to the queue (1 running / 0 failed / 4 finished / 0 left).
08-Nov-2011 13:48:13 - The job cleanup   has been successfully completed (0 running / 0 failed / 5 finished / 0 left).

*********************************************
The processing of the pipeline is terminated.
See report below for job completion status.
08-Nov-2011 13:48:23
*********************************************
All jobs have been successfully completed.
```


## Restart a job
This last section deals with a kind of peculiar and tricky situation. Imagine that you want to change the options of a job, but the inputs of this job were deleted to save space (by the `cleanup` job). If it is still possible to rebuild the inputs using other jobs of the pipeline, PSOM will sort it out for you. Let's force the job the options of `fft`, which job is incidentally using the output of `tseries1`, and restart the pipeline : 
```matlab
>> opt.restart = {'quadratic'};
>> psom_run_pipeline(pipeline,opt);
*****************************************
The pipeline PIPE is now being processed.
Started on 08-Nov-2011 13:48:24
user: pbellec, host: berry, system: unix
*****************************************
08-Nov-2011 13:48:24 - The job sample    has been submitted to the queue (1 running / 0 failed / 0 finished / 4 left).
08-Nov-2011 13:48:26 - The job sample    has been successfully completed (0 running / 0 failed / 1 finished / 4 left).
08-Nov-2011 13:48:26 - The job quadratic has been submitted to the queue (1 running / 0 failed / 1 finished / 3 left).
08-Nov-2011 13:48:27 - The job cubic     has been submitted to the queue (2 running / 0 failed / 1 finished / 2 left).
08-Nov-2011 13:48:30 - The job quadratic has been successfully completed (1 running / 0 failed / 2 finished / 2 left).
08-Nov-2011 13:48:30 - The job cubic     has been successfully completed (0 running / 0 failed / 3 finished / 2 left).
08-Nov-2011 13:48:30 - The job sum       has been submitted to the queue (1 running / 0 failed / 3 finished / 1 left).
08-Nov-2011 13:48:31 - The job cleanup   has been submitted to the queue (2 running / 0 failed / 3 finished / 0 left).
08-Nov-2011 13:48:34 - The job cleanup   has been successfully completed (1 running / 0 failed / 4 finished / 0 left).
08-Nov-2011 13:48:34 - The job sum       has been successfully completed (0 running / 0 failed / 5 finished / 0 left).

*********************************************
The processing of the pipeline is terminated.
See report below for job completion status.
08-Nov-2011 13:48:44
*********************************************
All jobs have been successfully completed.
```
PSOM decided to restart `sample` in order to be able to reprocess `quadratic`. That behavior is actually recursive, so even indirect dependencies could have been solved. The jobs `sum` and `cubic` have also been restarted because they have (direct or indirect) dependencies on `sample`.

#Monitor a pipeline
After a pipeline has been started in a log folder, the pipeline manager is keeping track of all processing, options and logs. Those informations are stored into matlab .mat files (which is actually HDF5), and can be accessed using the command `psom_pipeline_visu`.

## Display flowchart

The flowchart of the pipeline is stored in the logs and can be visualized this way (requires the bioinformatics toolbox).
```matlab
>> psom_pipeline_visu(opt.path_logs,'flowchart');
```

>![An example of pipeline dependency graph](https://raw.githubusercontent.com/SIMEXP/psom/master/demo_pipe2.jpg)

## List the jobs

It is possible to list the jobs of the pipeline according to their current status (either `none`, `failed` or `finished`). For example, to see a list of the finished jobs : 
```matlab
>> psom_pipeline_visu(opt.path_logs,'finished')
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
As was described in the last section, it is possible to access the logs of any job (unprocessed jobs have an empty log) :
```matlab
>> psom_pipeline_visu(opt.path_logs,'log','sum')

****************************************
  Log file of job sum (status finished) 
****************************************

command = load(files_in{1}); load(files_in{2}); d = b+c, save(files_out,'d')
files_in =

{
  [1,1] = /home/pbellec/database/demo_psom/quadratic.mat
  [1,2] = /home/pbellec/database/demo_psom/cubic.mat
}

files_out = /home/pbellec/database/demo_psom/sum.mat
files_clean = {}(0x0)
opt = {}(0x0)

******************************
Log of the (octave) job : sum
Started on 08-Nov-2011 13:48:34
User: pbellec
host : berry
system : unix
******************************

********************
The job starts now !
********************
d =

   0.132715
   0.805646
   0.061853
   5.703437
   0.067863
   0.014629
   3.732021
   0.118349
  -0.205880
  -0.330022


****************
Checking outputs
****************
The output file or directory /home/pbellec/database/demo_psom/sum.mat was successfully generated!

*********************************************************
08-Nov-2011 13:48:34 : The job was successfully completed
Total time used to process the job : 0.10 sec.
*********************************************************
```
## Display computation time
It is also possible to get a summary of the effective computation time for all the jobs or a subpart of the pipeline
```matlab
>> psom_pipeline_visu(opt.path_logs,'time','')
**********
cleanup   : 0.08 s, 0.00 mn, 0.00 hours, 0.00 days.
cubic     : 0.05 s, 0.00 mn, 0.00 hours, 0.00 days.
quadratic : 0.07 s, 0.00 mn, 0.00 hours, 0.00 days.
sample    : 0.05 s, 0.00 mn, 0.00 hours, 0.00 days.
sum       : 0.10 s, 0.00 mn, 0.00 hours, 0.00 days.
**********
Total computation time :  0.35 s, 0.01 mn, 0.00 hours, 0.00 days.
```
The last argument can be used to select only a subpart of the pipeline (e.g. 'cubic').

##Monitor history
It is possible to access the pipeline history again (concatenated over all executions, and with updates) using the following command : 
```matlab
>> psom_pipeline_visu(opt.path_logs,'monitor')
(...)
```
The result of this command is not listed here, because it recapitulates everything that has been done so far in the tutorial and is therefore quite lengthy.

# Conclusion

That is the end of this tutorial, congratulations for making it here ! Beyond the toy pipeline, PSOM is able to handle smoothly pipelines with thousands of jobs involving tens of thousands of files, and distribute those amongst tens of processors. This is an opensource project : it was made to be used, copied and modified freely, so enjoy ! If you find that software useful or if you run into a bug, please do send feedback to the maintainer of this project `pierre.bellec [at] criugm.qc.ca`. 
