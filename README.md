###Overview
The pipeline system for Octave and Matlab (PSOM) is a lightweight library to manage complex multi-stage data processing. You can have a look at the [wiki](https://github.com/SIMEXP/psom/wiki) for tutorials and more info. A pipeline is a collection of jobs, i.e. Matlab or Octave codes with a well identified set of options that are using files for inputs and outputs. To use PSOM, the only requirement is to generate a description of a pipeline in the form of a simple Matlab/Octave structure. PSOM offers the following services:
  * Run jobs in parallel using multiple CPUs or within a distributed computing environment.
  * Generate log files and keep track of the pipeline execution. These logs are detailed enough to fully reproduce the analysis.
  * Handle job failures : successful completion of jobs is checked and failed jobs can be restarted.
  * Handle updates of the pipeline : change options or add jobs and let PSOM figure out what to reprocess !

There is a [paper](http://www.frontiersin.org/neuroinformatics/10.3389/fninf.2012.00007/abstract) in Frontiers in Neuroinformatics that provides an overview of PSOM features and implementation. 

###Installation
It is currently stable production stage and has been tested under Linux, Windows and Mac OSX (see the [test page](https://github.com/SIMEXP/psom/wiki/PSOM-tests)). To install PSOM, just download the latest [release](https://github.com/SIMEXP/psom/releases), extract the archive in a folder and add that folder to your matlab or octave search path. 
You're done ! You may have to adapt the [configuration](https://github.com/SIMEXP/psom/wiki/PSOM-configuration) to your local production environment. To use PSOM, you can have a look at the code of `psom_demo_pipeline`, or read [tutorial](https://github.com/SIMEXP/psom/wiki/How-to-use-PSOM).

###Contributions
PSOM is maintained by Pierre [Bellec](http://simexp-lab.org/brainwiki/doku.php?id=pierrebellec), "[Unité de Neuroimagerie Fonctionnelle](http://www.unf-montreal.ca/)" (UNF), "[Centre de Recherche de l'Institut de Gériatrie de Montréal](http://www.criugm.qc.ca/)" (CRIUGM), "[Département d'Informatique et de Recherche Opérationnelle](http://www.iro.umontreal.ca/)" (DIRO), [Université de Montréal](http://www.umontreal.ca/). 
The project was started by Pierre Bellec in the lab of [Alan Evans](http://www.bic.mni.mcgill.ca/~alan/) at the [McConnell Brain Imaging Center](http://www.bic.mni.mcgill.ca/), [Montreal Neurological Institute](http://www.mni.mcgill.ca/), [McGill University](http://www.mcgill.ca/), Canada. 
Core ideas have been inspired by the Poor Man's Pipeline (PMP) project developed by Jason Lerch, which was itself based on [RPPL](http://www.bic.mni.mcgill.ca/~jason/rppl/rppl.html) by Alberto Jimenez and Alex Zijdenbos. Other contributors include Mr Sebastien Lavoie-Courchesne and M. Christian Dansereau.

###News
####July, 12th, 2014
The repository of the PSOM project was moved from google code to github: https://github.com/SIMEXP/psom

####August, 23rd, 2013
Release of NIAK 0.7.1 "ammo". This is an update on the 0.7.0 release where the version of PSOM (1.0.1) had a bug in the update feature. See the [http://code.google.com/p/niak/wiki/ReleaseNotes release notes] for details.

####August, 17th, 2013
Release of NIAK 0.7 "ammo". Main features:
* A new pipeline for region growing. This can be used to generate a functional brain parcellation, controlling for the regions' size and/or homogeneity, at the level of an individual or a group. Methods as described in [Bellec et al., Neuroimage 2006](http://dx.doi.org/10.1016/j.neuroimage.2005.08.044).
* A new pipeline to generate connectomes, functional connectivity maps as well as graph properties. This pipeline depends on the [brain connectivity toolbox](https://sites.google.com/site/bctnet/).
* A revamp of the fMRI preprocessing pipeline. Now includes regression of average signals in the ventricles and the white matter, scrubbing, regression of the global signal "a la Carbonell", regression of the motion parameters after PCA reduction, COMPCOR, symmetric or asymmetric MNI brain template, and other goodies. 
* Lots of other minor features and bug fixes.
See the [release notes](https://github.com/SIMEXP/psom/wiki/Release-notes) for details.

####January, 19th, 2011
There will be a poster presentation (#4301) on NIAK at the Human Brain Mapping conference in Québec City, Canada, June 26th-30th 2011.

####January, 17th, 2011
Release of NIAK version 0.6.4.1. Mainly a bug-fix release. Main features :
* Bug fix in the fMRI preprocessing pipeline : the option to get rid of volumes in the motion correction corrupted the data (opt.motion_correction.suppress_vol).
* Bug fix in the fMRI preprocessing pipeline : with multi-session data, the average fMRI volumes are off. As a result, the fMRI to T1 coregistration was likely to fail.
* The pipeline manager (PSOM) is now much faster to initialize and submit jobs.
See the [release notes](https://github.com/SIMEXP/psom/wiki/Release-notes) for details.

####December, 7th, 2010
Release of NIAK version 0.6.4. Main features :
* NIAK is fully compatible with Octave.
* NIAK only depends on the opensource project called the MINC tools http://en.wikibooks.org/wiki/MINC
* A new version of the user's guide in PDF. This guide applies as of NIAK release 0.6.3.4. 
* A completely revised fMRI preprocessing pipeline. Scripts written for the old system should still work, but it would be better to update the script to conform to the new template. This will require minimal effots. Main changes : 
* There are no "styles" anymore. Most steps of the pipeline can instead be skipped using dedicated flags making the whole flowchart flexible.
* There are lots of new steps for quality control purposes. 
* The T1-fMRI coregistration should work better. 
* The parameters of the slice timing correction are much more straightforward to specify.
* the motion correction operates at the run level if possible, and is much faster. The strategy is also now fully hierarchical : within-run, between-run within-session, between-sessions.
See the [release notes](https://github.com/SIMEXP/psom/wiki/Release-notes) for details.

####November, 30th, 2010
A new version of NIAK (0.6.3.4) has been released for testing purposes. There are major bugs in this major update, which will soon be replaced by a stable release.

####October, 26th, 2010
Today, the full fMRI preprocessing ran successfully in Octave for the first time. This is opening a new world of perspectives for parallel analysis in massive supercomputing environments.

####October, 8th, 2010
Revision 1000 of the subversion repository was commited today. Happy revision-day Mr NIAK !

####May, 21st, 2010
Release of NIAK version 0.6.3 :
* The main new feature is the way temporary file names are handled. In the old system, it was possible that two jobs running on the same machine ended up using the same temporary file names, resulting into conflict and crash. That should not happen anymore. 
* Deleting the "PIPE.lock" file in the logs folder will now force the pipeline manager to stop, even if it is running in the background. 
* There have been a lot of improvements/development towards an improved preprocessing pipeline and an fMRIstat pipeline, but nothing complete yet. 
See the [release notes](https://github.com/SIMEXP/psom/wiki/Release-notes) for details.

####January, 15th, 2010
Release of NIAK version 0.6.2. There are new tools for General Linear Model (GLM) analysis, but no pipeline (yet). The main functions of the fMRIstat package of K. Worsley have now been "NIAKified". This is an important intermediate step towards release 0.7. See the [release notes](https://github.com/SIMEXP/psom/wiki/Release-notes) for details.

####March, 25th, 2009
There is now a PDF presentation of the NIAK tools and in particular the fMRI preprocessing pipeline.

####February, 1st, 2009
Release of NIAK version 0.6. A slight change in the roadmap of the project explains the absence of version 0.5. The main new feature is that the pipeline system has been redesigned and turned into an independent project called [http://code.google.com/p/psom/ psom]. Running pipelines in NIAK is now much more straightforward than it was in version 0.4. PSOM is distributed inside the NIAK package and the user's guide has been updated.

####November, 27th, 2008
Adaptation of a NIAK logo from an original work by the artist [http://mattahan.deviantart.com/ Mattahan] under a [http://creativecommons.org/licenses/by-nc-sa/3.0/ creative commons license].

####September, 12th, 2008
Release of NIAK version 0.4. The main new feature is the [CORSICA](http://dx.doi.org/10.1016/j.mri.2006.09.042) method to correct for physiological noise that have been added to the pre-processing of fMRI data.
* New bricks include individual spatial ICA (and PCA), selection of ICA components based on spatial priors, and suppression of ICA components
* A specific template for physiological noise correction.

####September, 2nd, 2008
There is now an online user's guide to the project. It is available on the McConnell Brain imaging center (BIC)'s [http://wiki.bic.mni.mcgill.ca/index.php/NeuroImagingAnalysisKit wiki].

####May, 21st, 2008
Release of NIAK version 0.3. The main new feature is a versatile pipeline for fMRI pre-processing :
* Multiple pipeline styles available, optimized for linear modeling or connectivity analysis.
* Available bricks include : slice-timing and motion correction, spatial and temporal filtering, coregistration between T1 and T2 images, linear and non-linear fit in the MNI stereotaxic space with optional resampling of fMRI data in this space.

####March 7th, 2008
The first public release (0.2) is now available for download, which features :
* reader/writer for MINC1, MINC2, NIFTI and ANALYZE files
* the pipeline system 
* A few bricks for fMRI data preprocessing (slice timing, spatial smoothing, temporal filtering). 
