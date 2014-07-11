=Pipeline System for Octave and Matlab (PSOM), version 1.0.2=

The pipeline system for Octave and Matlab (PSOM) is a lightweight library to manage complex multi-stage data processing. 
A pipeline is a collection of jobs, i.e. Matlab or Octave codes with a well identified set of options that are using files for inputs and outputs. 
To use PSOM, the only requirement is to generate a description of a pipeline in the form of a simple Matlab/Octave structure. 
PSOM then automatically offers the following services:
  * Run jobs in parallel using multiple CPUs or within a distributed computing environment.
  * Generate log files and keep track of the pipeline execution. These logs are detailed enough to fully reproduce the analysis.
  * Handle job failures : successful completion of jobs is checked and failed jobs can be restarted.
  * Handle updates of the pipeline : change options or add jobs and let PSOM figure out what to reprocess !

PSOM is an opensource project distributed under an [http://www.opensource.org/licenses/mit-license.php MIT opensource license].  
There is a [http://www.frontiersin.org/neuroinformatics/10.3389/fninf.2012.00007/abstract paper] in Frontiers in Neuroinformatics that provides an overview of PSOM features and implementation. 
It is currently stable production stage and has been tested under Linux, Windows and Mac OSX (see the [http://code.google.com/p/psom/wiki/TestPsom test] page). 
To install PSOM, just extract the [http://code.google.com/p/psom/downloads/list archive] in a folder and add that folder to your matlab or octave search path. 
You're done ! You may have to adapt the [http://code.google.com/p/psom/wiki/ConfigurationPsom configuration] to your local production environment. 
To use PSOM, you can have a look at the code of `psom_demo_pipeline`, or read [http://code.google.com/p/psom/wiki/HowToUsePsom the tutorial].

PSOM is maintained by Pierre [http://simexp-lab.org/brainwiki/doku.php?id=pierrebellec Bellec], "[http://www.unf-montreal.ca/ Unité de Neuroimagerie Fonctionnelle]" (UNF), "[http://www.criugm.qc.ca/ Centre de Recherche de l'Institut de Gériatrie de Montréal]" (CRIUGM), "[http://www.iro.umontreal.ca/ Département d'Informatique et de Recherche Opérationnelle]" (DIRO), [http://www.umontreal.ca/ Université de Montréal]. 
The project was started by Pierre Bellec in the lab of [http://www.bic.mni.mcgill.ca/~alan/ Alan Evans] at the [http://www.bic.mni.mcgill.ca/ McConnell Brain Imaging Center], [http://www.mni.mcgill.ca/ Montreal Neurological Institute], [http://www.mcgill.ca/ McGill University], Canada. 
Core ideas have been inspired by the Poor Man's Pipeline (PMP) project developed by Jason Lerch, which was itself based on [http://www.bic.mni.mcgill.ca/~jason/rppl/rppl.html RPPL] by Alberto Jimenez and Alex Zijdenbos.
