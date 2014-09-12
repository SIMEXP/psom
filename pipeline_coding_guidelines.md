###Introduction
A **pipeline** is a series of **jobs**, i.e. a Matlab/Octave code that takes files as inputs and produces files as outputs. To use PSOM, it is necessary to generate a matlab representation of these jobs using a specific pipeline structure. In order to keep the generation of the pipeline concise, re-usable and readable, some coding guidelines have been developed both for coding the jobs, the modules used by the jobs (aka **bricks**) and finally the pipeline itself.

###Jobs

####How to set the job parameters

There is no strict framework to set the default of the input arguments in
Octave/Matlab. The following approach has several advantages over a more traditional method consisting in passing each parameter one
by one. All parameters are passed as fields of a single structure `opt`. A generic function `psom_struct_defaults` can be used to check for the presence of mandatory input arguments, set default values, and issue warnings for unkown arguments. The following example shows how to set the input arguments of a function using that approach:
```matlab
>> opt.order = [1 3 5 2 4 6];
>> opt.slic = 1;
>> opt.timing = [0.2,0.2];
>> list_fields   = { 'method' , 'order' , 'slice' , 'timing' , 'verb' };
>> list_defaults = { 'linear' , NaN     , []      , NaN      , true   };
>> opt = psom struct defaults(opt,list fields,list defaults)
warning: The following field(s) were ignored in the structure : slic
opt = {
   method = linear
   order = [1 2 3 4 5 6]
   slice = [](0x0)
   timing = [0.20000 0.20000]
   verb = 1 }
```
Note that only three lines of code are used to set all the defaults, and that a warning was automatically issued for the typo `slic` instead of `slice`. Such unlisted fields are simply ignored. Also, the default value `NaN` can be used to indicate a mandatory argument (an error will be issued if this field is absent). This approach will scale up well with a large number of parameters. It also facilitates the addition of extra parameters in future developments while maintaining backwards compatibility. As long as a new parameters is optional, a code written for old specifications will remain functional.

####How to create temporary files

There are two functions to generate temporary files or folders in PSOM:
```matlab
>> file_tmp = psom_file_tmp('_suffix')
file_tmp = /tmp/psom_tmp_359007_suffix
>> path_tmp = psom_path_tmp ('_suffix')
path_tmp = /tmp/psom_tmp_44068_suffix/
```
PSOM will generate a random name, using the specified suffix. Before attributing the name, PSOM will check that this name is not already used (in which case it will generate another random name). As soon as the name has been selected, an empty file name or directory is automatically created. Moreover, if these commands are called as part of a job, the job name is automatically added in the temporary name. All these features ensure that there will be no conflict of temporary names between jobs, even if the same pipeline is executed multiple times on a single machine. By default, the name of the temporary folder is the default of the system (as defined by the `tempdir` variable). This can be changed using the `gb_psom_tmp` variable defined in `psom_gb_vars.m`.

####Random number generator 
When running Monte Carlo simulations, it is critical to take a great care setting up the state of the random number generator. There is a PSOM command called `psom_set_rand_seed` which will set the state of the Gaussian and uniform random number generator:
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
The way to perform this operation has changed with versions of Matlab, and is not currently the same in Matlab and Octave. `psom_set_rand_seed` will work in all versions and languages. If called without an input, the function uses the clock to set the state of the generator. By default, this is what PSOM does for each job. 

If the results of the pipeline have to be reproducible, it is possible to add an option `seed_rand` to the job, and use the `psom_set_rand_seed` command to set a fixed seed (ex 0) for each job. However, in some Monte Carlo simulations, the only thing that changes from one job to another is exactly the seed of the random number generator. In that case, it is possible to use `psom_set_rand_seed` once, then generate a list of random (but reproducible) seeds. Each one of these seeds are saved in an individual .mat file, which are then fed into the jobs as an input parameter.
 
###Bricks

####The syntax of a brick

The bricks are a special type of M function which take files as inputs and
outputs, along with a structure to describe some options. The command used to call a brick always follows the same syntax:
```matlab 
[files_in,files_out,opt] = brick_name(files_in,files_out,opt) 
```
See the following  [template](https://github.com/SIMEXP/psom/blob/master/psom_template_brick.m) for an example of code.

####Input/output files
`files_in` and `files_out` can be a string array, cells of string array or nested structures where each terminal field is of the preceding type. Examples :
```matlab
files_in1 = '/path/my_file.mnc'

files_in2 = {'/path/my_file1.mnc','/path/my_file2.mnc'}

files_in3.data = {'/path/my_file1.mnc','/path/my_file2.mnc'}; 
files_in3.anat = '/path/my_t1_image.mnc';

files_in4.data.session1 = '/path/my_file1.mnc'; 
files_in4.data.session2 = '/path/my_file2.mnc'; 
files_in4.anat = '/path/my_t1_image.mnc';
```

`files_in` and `files_out` define the input and output files of the brick, respectively. They are important fields for the pipeline system, which use those names to determine the dependencies between bicks. 

To facilitate the combination of bricks into another brick or a pipeline, the following behavior is expected to set up default output names and to select a subset of possible inputs/ouputs. If a file name is present, but is an empty string, a default value will be specified if possible. If a field is absent in a structure, or if the file name is `gb_niak_omitted`, then the ouput will not be generated. In the case of an input files, the input values will be estimated if possible.

####Options
`opt` is a structure used to specify arguments. A number of fields are generally present in `opt` :
* `folder_out` If this field exist and is not empty, all outputs will be generated in this folder. By default, `folder_out` is the same directory as the one where the inputs live.
* `flag_test` : If this field exist and is non-zero, the brick is not doing anything but updating the default values of `inputs`, `outputs` and `opt` and sending back these values. See below
* `flag_verbose` :  if this field exist and is non-zero, then the function prints some infos during the processing.

####Running a test
The key mechanism of a brick is`opt.flag_test` which allows the programmer to make a test, or dry-run. If that (boolean) option is true, the brick will not do anything but update the default parameters and file names in its three arguments. Using this mechanism, it is possible to use the brick itself to generate an exhaustive list of the brick parameters, and test if a subset of parameters are acceptable to run the brick. In addition, if a change is made to the default parameters of a brick, this change will be apparent to any piece of code that is using a test to set the parameters,
without a need to change the code.

####Example

Building `files_in`, `files_out` and `opt` for the brick `niak_brick_time_filter` (from the [NIAK](https://github.com/SIMEXP/niak) package):
```matlab
>> files_in  = '/media/hda3/database/data_niak/minc2/func_motor_subject1.mnc';
>> files_out.filtered_data = '';  
>> files_out.var_high = '';
>> files_out.var_low = '';
>> opt.tr = 2.33;
>> opt.lp = 0.1;
>> opt.hp = 0.01;
>> opt.folder_out = '/media/hda3/database/data_niak/minc2/filtered_data/';
```

Let's have a look at the default values assigned to these inputs:
```matlab
>> opt.flag_test = 1;
>> [files_in,files_out,opt] = niak_brick_time_filter(files_in,files_out,opt)

files_in =

/media/hda3/database/data_niak/minc2/func_motor_subject1.mnc

files_out = 

         filtered_data: '/media/hda3/database/data_niak/minc2/filtered_data//func_motor_subject1_f.mnc'
         var_high: '/media/hda3/database/data_niak/minc2/filtered_data//func_motor_subject1_var_high.mnc'
          var_low: '/media/hda3/database/data_niak/minc2/filtered_data//func_motor_subject1_var_low.mnc'
        beta_high: 'gb_niak_omitted'
         beta_low: 'gb_niak_omitted'
          dc_high: 'gb_niak_omitted'
           dc_low: 'gb_niak_omitted'

opt = 
      
     flag_test: 1
            tr: 2.3300
            lp: 0.1000
            hp: 0.0100
    folder_out: '/media/hda3/database/data_niak/minc2'
      flag_zip: 0
```

Note how the default output names have been built based on the inputs. An extension has been added to the base name, the same extension as the input is used, and the output folder is the one specified in `opt`. Also note that a number of possible outputs (`beta_high`, `beta_low`, `dc_high`, `dc_low`) have been assigned the tag `gb_niak_omitted`, which means that they will not be generated.

###Pipelines 

####Pipeline description

Pipelines are described using a matlab-type structure:
```matlab
pipeline =
               anat_subject1: [1x1 struct]
               anat_subject2: [1x1 struct]
  motion_correction_subject1: [1x1 struct]
  motion_correction_subject2: [1x1 struct]
         coregister_subject1: [1x1 struct]
         coregister_subject2: [1x1 struct]
  slice_timing_subject1_run1: [1x1 struct]
```

Each field of the pipeline structure is itself a structure, which is describing one job:
```matlab
pipeline.slice_timing_subject1_run1 =
    command: ’niak_brick_slice_timing(files_in,files_out,opt)’
   files_in: ’/fmri_preprocess/subject1/motion_correction/func_motor_subject1_mc.mnc’
  files_out: ’/fmri_preprocess/subject1/slice_timing/func_motor_subject1_mc_a.mnc’
  files_out: {}
        opt: [1x1 struct]
```

For each field `pipeline.<job_name>`, the subfield `command` is the matlab command which will be executed by the job, the subfields `files_in` and `files_out` respectively describe the input and output files of the jobs, `files_clean` it the list of files deleted by the command, and `opt` describes the option. As for bricks, `files_in`, `files_out` (and `files_clean`) can be a string, a cell of string, a structure whose fields are strings or cells of strings, or a nested structure of the preceeding type. The `opt` field can be of any type. The command will be executed with nothing in memory but `files_in`, `files_out`, `files_clean` and `opt`, which will be loaded in memory as variables.

Note that this format is extremely flexible, and it is not necessary to use bricks to build a pipeline. Here is an example of a job with standard commands:
```matlab
pipeline.samp_tseries.files_in = ''; % No input
pipeline.samp_tseries.files_out = '/home/pbellec/demo_niak/gaussian_tseries.mat';
pipeline.samp_tseries.opt.nt = 100;
pipeline.samp_tseries.opt.nb_roi = 10;
pipeline.samp_tseries.command = 'tseries = randn([opt.nt opt.nb_roi]); save(files_out,''tseries'');';
```

####Pipeline generator

A pipeline generator is a function that, starting from a minimal description of a file collection and some options, generates a full pipeline. Because a pipeline can potentially create a very large number of outputs, it is difficult to implement a generic system that is as flexible as a brick in terms of output selection. Instead, the organization of the output of the pipeline will follow some canonical, well-structured predefined organization. As a consequence, the pipeline generator only takes two input arguments, files in and opt (similar to those of a job), and does not feature files out. The following example shows how to invoke the CORSICA pipeline, implemented in NIAK:
```matlab
pipeline = niak_pipeline_corsica(files_in,opt)
```
where `pipeline` is the final pipeline structure and `files_in` is a description of the dataset to process:
```matlab
%% Subject 1
files_in.subject1.fmri{1} = '/home/pbellec/demo_niak/func_motor_subject1.mnc';
files_in.subject1.fmri{2} = '/home/pbellec/demo_niak/func_rest_subject1.mnc';
files_in.subject1.transformation = '/home/pbellec/demo_niak/transf_subject1_funcnative_to_stereonl.xfm';

%% Subject 2
files_in.subject2.fmri{1} = '/home/pbellec/demo_niak/func_motor_subject2.mnc';
files_in.subject2.fmri{2} = '/home/pbellec/demo_niak/func_rest_subject2.mnc';
files_in.subject2.transformation = '/home/pbellec/demo_niak/transf_subject2_funcnative_to_stereonl.xfm';
```

The argument `opt` will generally include the following standard fields:
* `opt.folder_out`: name of the folder where the outputs of the pipeline will be generated (possibly organized into subfolders).
* `opt.size_output`: this parameter can be used to vary the amount of  outputs generated by the pipeline (e.g. `'all'`: generate all possible outputs; `'minimum'`, clean all intermediate outputs, etc).
* `opt.brick1`: all the parameters of the first brick used in the pipeline.
* `opt.brick2`: all the parameters of the second brick used in the pipeline.
* etc

Inside the code of the pipeline generator, adding a job to the pipeline will typically involve a loop similar to the following example:
```matlab
% Initialize the pipeline to a structure with no field
pipeline = struct();
% Get the list of subjects from files in
list_subject = fieldnames(files_in);
% Loop over subjects
for num_s = 1:length(list_subject)
    % Plug the 'fmri' input files of the subjects in the job
    job_in = files in.(list subject{num_s}).fmri;
    % Use the default output name
    job_out = '';
    % Force a specific folder organization for outputs
    opt.fmri.folder_out = [opt.folder_out list_subject{num_s} filesep];
    % Give a name to the jobs
    job_name = ['fmri ' list subject{num_s}];
    % The name of the employed brick
    brick = 'brick_fmri';
    % Add the job to the pipeline
    pipeline = psom_add_job(pipeline,job_name,brick,job_in,job_out,opt.fmri);
    % The outputs of this brick are just intermediate outputs :
    % clean these up as soon as possible
    pipeline = psom_add_clean(pipeline,[job_name '_clean'],pipeline.(job_name).files_out);
end
```

The command psom add job first runs a test with the brick to update the
default parameters and file names, and then adds the job with the updated
input/output files and options. By virtue of the “test” mechanism, the brick is itself defining all the defaults. The coder of the pipeline does not actually need to know which parameters are used by the brick. Any modification made to a brick will immediately propagate to all pipelines, without changing one line in the pipeline generator. Moreover, if a mandatory parameter has been omitted by the user, or if a parameter name is not correct, an appropriate error or warning will be generated at this stage, prior to any work actually being performed by the brick. The command psom add clean adds a clean-up job to the pipeline, which deletes the specified list of files. Because the jobs can be specified in any order, it is possible to add a job and its associated clean-up at the same time. 

####Combining pipelines

In case two pipelines need to be combined (say for example `pipeline2` uses some of the outputs of `pipeline1`), all that needs to be done is to merge all the jobs into one structure. There is a NIAK function which does that : 
```matlab
pipeline = psom_merge_pipeline(pipeline1,pipeline2),
```
If for some reason the same job names are used in `pipeline1` and `pipeline2`, it is possible to add a prefix the all the job names from `pipeline2`:
```matlab
pipeline = psom_merge_pipeline(pipeline1,pipeline2,'test2_');
```