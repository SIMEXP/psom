=﻿Pipeline System for Octave and Matlab (PSOM), version 0.8=

PSOM is a tool to manage pipelines under Matlab or Octave, both within a single session or within a parallel computing environment. A pipeline is a collection of jobs, i.e. some matlab or octave codes that are using files as inputs and are producing files as outputs. PSOM is automatizing all the boring tasks for you: 
  * Create folders for outputs
  * Keep track of all options
  * Generate log files
  * Job failure will not crash the pipeline. The pipeline manager identifies the jobs that have failed to produce their expected outputs, and will be able to restart these failed jobs latter.
  * If the pipeline is restarted while some jobs have been modified, the pipeline manager will restart only the jobs that these changes will impact.
  * Determine which jobs can run in parallel by examining the dependencies between inputs and outputs of jobs. The same code can run a pipeline locally or in parallel on multiple PCs, three execution modes being available:
    * in a single matlab/octave session, on a single machine
    * in multiple matlab/octave sessions through batch, on a single machine with multiple CPUs.
    * in multiple matlab/octave sessions trough qsub (pbs and sge are supported), on multiple computers.

The pipeline system was implemented by Pierre [http://wiki.bic.mni.mcgill.ca/index.php/PierreBellec Bellec] at the !McConnell Brain Imaging Center, Montreal Neurological Institute, !McGill University, Canada, 2008. Core ideas for PSOM have been inspired by the [http://wiki.bic.mni.mcgill.ca/index.php/PoorMansPipeline Poor Man's Pipeline (PMP) project], that was coded in PERL. 

PSOM is an opensource project distributed under an [http://www.opensource.org/licenses/mit-license.php MIT opensource license]. It is possible to download the project on this [http://code.google.com/p/psom/downloads/list website]. To install PSOM, just extract the archive in a folder and add that folder to your matlab or octave search path. You're done ! To use PSOM, you can have a look at the code of `psom_demo_pipeline`, or read [http://code.google.com/p/psom/wiki/HowToUsePsom the tutorial].

Please visit http://code.google.com/p/psom/ for updates.

----
=News=

==January 26th, 2009==
Release 0.8. Differences with version 0.7 are minor, but the demo `psom_demo_pipeline` is now complete and the [http://code.google.com/p/psom/wiki/HowToUsePsom PSOM tutorial] is available.

==December 29th, 2008==
There is now a logo for the PSOM project.

==December 13th, 2008==
Release 0.6.0.3. The way the pipeline manager deals with job status has been completely revised. The pipeline manager is now able to deal easily with pipelines of up to 5000 jobs and probably more.

==November 20th, 2008==
Release 0.6.0.2. A first successful test on a big pipeline (>5000 jobs with a complex dependency graph) has been done. Learning from that test, a number of improvements have been made to speed up the pipeline manager.

==November 11th, 2008==
Already a bunch of bug fixes that needed to be done. Release 0.6.0.1 has been tested on Linux and should work. Still a couple features missing though.

==November 10th, 2008==
First public release (0.6) of the PSOM project, see the [http://code.google.com/p/psom/ milestones page] for features. The tests have been limited so far to Linux. 
