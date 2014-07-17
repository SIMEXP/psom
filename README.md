###Overview
A "pipeline" is the application of several operations (or jobs) on a dataset, stored in files, sometimes sequentially, sometimes in parallel. The quick-and-dirty way to run a pipeline is to manually apply operations to files, either by calling programs in a terminal or using a graphical interface. 

For example, in SPM, you can click buttons to apply slice timing correction to a fMRI dataset, generate "corrected" images, and then click other buttons to apply a spatial smoothing on those "corrected" images in order to generate "smoothed, corrected images". This method is prone to errors, and cannot be traced or reproduced. And, most importantly, it is slow. So, although some people have a weird attraction towards boring and repetitive tasks, the lazy, efficient people will turn to scripts (which will save them time to play mine sweeper). 

Scripts are text files generally written in a high-level language that automate the execution of the jobs. However, long scripts including many jobs are sometimes very inefficient: if a brain needs to be extracted independently on 100 subjects and you happen to have 100 computers lying around in your living room, why not run these operations in parallel ? But this can become tricky, especially if parts of the pipeline cannot run in parallel, and need to wait for many operations to complete before they can be started.

Also, many of the tasks involved in scripting a pipeline are extremely repetitive and boring (which is, again, taking us time away from mine sweeper): these include logging the verbose of the job as well as basic information such as the time of start/end, the name of the machine/user, etc. So, while the ultimate aim of writing a pipeline script is to automatize the execution of a bunch of jobs, the real lazy people will want to automatize the writing of the script too.

The pipeline system for Octave and Matlab (PSOM) is a small library that was designed to help script pipelines using a high-level popular language for scientific computing called matlab, as well as its open-source, GNU equivalent, called Octave. With PSOM, the following services come for free to the user:
  * Automatically detect and execute jobs that can run in parallel, using multiple CPUs or within a distributed computing environment.
  * Generate log files and keep track of the pipeline execution. These logs are detailed enough to fully reproduce the analysis.
  * Handle job failures : successful completion of jobs is checked and failed jobs can be restarted.
  * Handle updates of the pipeline : change options or add jobs and let PSOM figure out what to reprocess !

You can have a look at the [wiki](https://github.com/SIMEXP/psom/wiki) for tutorials and more info. There is also a [paper](http://www.frontiersin.org/neuroinformatics/10.3389/fninf.2012.00007/abstract) in Frontiers in Neuroinformatics that provides an overview of PSOM features and implementation. 

###Installation
PSOM is currently in stable production stage and has been tested under Linux, Windows and Mac OSX (see the [test page](https://github.com/SIMEXP/psom/wiki/PSOM-tests)). To install PSOM, just download the latest [release](https://github.com/SIMEXP/psom/releases), extract the archive in a folder and add that folder to your matlab or octave search path. 
You're done ! You may have to adapt the [configuration](https://github.com/SIMEXP/psom/wiki/PSOM-configuration) to your local production environment. To use PSOM, you can have a look at the code of `psom_demo_pipeline`, or read the [tutorial](https://github.com/SIMEXP/psom/wiki/How-to-use-PSOM).

###Contributions
PSOM is maintained by Pierre [Bellec](http://simexp-lab.org/brainwiki/doku.php?id=pierrebellec), "[Unité de Neuroimagerie Fonctionnelle](http://www.unf-montreal.ca/)" (UNF), "[Centre de Recherche de l'Institut de Gériatrie de Montréal](http://www.criugm.qc.ca/)" (CRIUGM), "[Département d'Informatique et de Recherche Opérationnelle](http://www.iro.umontreal.ca/)" (DIRO), [Université de Montréal](http://www.umontreal.ca/). 
The project was started by Pierre Bellec in the lab of [Alan Evans](http://www.bic.mni.mcgill.ca/~alan/) at the [McConnell Brain Imaging Center](http://www.bic.mni.mcgill.ca/), [Montreal Neurological Institute](http://www.mni.mcgill.ca/), [McGill University](http://www.mcgill.ca/), Canada. 
Core ideas have been inspired by the Poor Man's Pipeline (PMP) project developed by Jason Lerch, which was itself based on [RPPL](http://www.bic.mni.mcgill.ca/~jason/rppl/rppl.html) by Alberto Jimenez and Alex Zijdenbos. Other contributors include Mr Sebastien Lavoie-Courchesne and Mr Christian Dansereau.

###News
####July, 12th, 2014
The repository of the PSOM project was moved from google code to github: https://github.com/SIMEXP/psom

