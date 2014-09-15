#Overview
The pipeline system for [Octave](http://www.gnu.org/software/octave/) and [Matlab](http://www.mathworks.com/) (PSOM) is a lightweight open-source library, under [MIT license](http://opensource.org/licenses/MIT), that was designed to help script complex multistage data processing, or "pipelines".

#Features
PSOM offers generic solutions for the main tasks involved in pipeline scripting. Please read the [tutorial](how_to_use_psom.html) and [guidelines](pipeline_coding_guidelines.html) to learn how to script pipelines with PSOM. There is also a [paper](http://www.frontiersin.org/neuroinformatics/10.3389/fninf.2012.00007/abstract) in Frontiers in Neuroinformatics that provides an overview of PSOM features and implementation.
 
> * Automatically detect and execute jobs that can run in parallel, using multiple CPUs or within a distributed computing environment.
> * Generate log files and keep track of the pipeline execution. These logs are detailed enough to fully reproduce the analysis.
> * Handle job failures : successful completion of jobs is checked and failed jobs can be restarted.
> * Handle updates of the pipeline : change options or add jobs and let PSOM figure out what to reprocess !

#Installation
PSOM 1.0.2 is at a stable, production stage, and has been tested under Linux, Windows and Mac OSX. To install PSOM, click the download button, extract the archive in a folder, and add that folder to your matlab or octave search path. 
You're basically done ! Feel free to bundle PSOM in your own projects.
> * How to [configure](psom_configuration.html) PSOM for your production environment.
> * All [releases](https://github.com/SIMEXP/psom/releases) can be found on github.
> * If a feature is missing, fork [PSOM](https://github.com/SIMEXP/psom) on github !

#Contributions
PSOM is maintained by the laboratory of Pierre [Bellec](http://simexp-lab.org/brainwiki/doku.php?id=pierrebellec), "[Unité de Neuroimagerie Fonctionnelle](http://www.unf-montreal.ca/)" (UNF), "[Centre de Recherche de l'Institut de Gériatrie de Montréal](http://www.criugm.qc.ca/)" (CRIUGM), "[Département d'Informatique et de Recherche Opérationnelle](http://www.iro.umontreal.ca/)" (DIRO), [Université de Montréal](http://www.umontreal.ca/). Other contributors include Mr Sebastien Lavoie-Courchesne, [Mr Sebastian Urchs](https://github.com/surchs) and Mr [Christian Dansereau](https://github.com/cdansereau).
![UDM and CRIUGM](logos_criugm_udm.png)
>The project was started by Pierre Bellec when he worked as a post-doctoral fellow in the lab of [Alan Evans](http://www.bic.mni.mcgill.ca/~alan/) at [McGill University](http://www.mcgill.ca/), Canada. 
>Core ideas have been inspired by the Poor Man's Pipeline (PMP) project developed by Jason Lerch, which was itself based on [RPPL](http://www.bic.mni.mcgill.ca/~jason/rppl/rppl.html) by Alberto Jimenez and Alex Zijdenbos. 

#News
##September, 12th, 2014
Release of this website.

##July, 12th, 2014
The repository of the PSOM project was moved from google code to github: https://github.com/SIMEXP/psom
