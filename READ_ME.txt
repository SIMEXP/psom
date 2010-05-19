=﻿Pipeline System for Octave and Matlab (PSOM), version 0.8.5=

A pipeline is a collection of matlab or octave codes with a well identified set of options that are using files as inputs and are producing files as outputs. PSOM is a framework to implement, run and re-run pipelines in Matlab or Octave :
  * Describe the pipeline using a straightforward structure representation.
  * Automatically generate log files and keep track of the pipeline description.
  * Handle job failures : successful completion of jobs is checked and failed jobs can be restarted.
  * Handle updates of the pipeline : change options or add jobs and let PSOM figure out what to reprocess !
  * Automatically run jobs in parallel whenever possible using multiple CPUs or within a distributed computing environment.

PSOM is an opensource project distributed under an [http://www.opensource.org/licenses/mit-license.php MIT opensource license]. It is currently in a beta-testing stage and has been tested under Linux (in Matlab and Octave) and windows (in Matlab). To install PSOM, just extract the [http://code.google.com/p/psom/downloads/list archive] in a folder and add that folder to your matlab or octave search path. You're done ! You may have to adapt the [http://code.google.com/p/psom/wiki/ConfigurationPsom configuration] to your local production environment. To use PSOM, you can have a look at the code of `psom_demo_pipeline`, or read [http://code.google.com/p/psom/wiki/HowToUsePsom the tutorial].

PSOM was implemented by Pierre [http://wiki.bic.mni.mcgill.ca/index.php/PierreBellec Bellec] in the lab of [http://www.bic.mni.mcgill.ca/~alan/ Alan Evans] at the !McConnell Brain Imaging Center, Montreal Neurological Institute, !McGill University, Canada, 2008-10. Core ideas have been inspired by the [http://wiki.bic.mni.mcgill.ca/index.php/PoorMansPipeline Poor Man's Pipeline (PMP) project] developed by Jason Lerch, which was itself based on [http://www.bic.mni.mcgill.ca/~jason/rppl/rppl.html RPPL] by Alberto Jimenez and Alex Zijdenbos. 

Please visit http://code.google.com/p/psom/ for updates.

----
LICENSE

Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-10.
Maintainer : pbellec@bic.mni.mcgill.ca

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

----
=News=
*May 19th, 2010* : Release 0.8.5. Main new features : 
  * Removing the lock file in the log folder will now kill the pipeline in any mode. 
  * The random number generator is now initialized based on the clock for each job, while before it was using the default state (in matlab this state is identical for evey session). 
A more detailed list of changes can be found in the [ReleaseNotes release notes].

*January 12th, 2010* : PSOM has just been registered in [http://www.nitrc.org/projects/psom/ NITRC]. Development of the project (subversion+bug tracker) is still going to be hosted by google code in the future, but the activity of the project should be updated on NITRC as well. Eventually the plan is to use the forum and mailing list at NITRC.

*December 12th, 2009* : Release 0.8.4. Support of PSOM in Matlab for windows, in `session` and `batch` modes. This is an unstable version, any feedback will be greatly appreciated.

*October 8th, 2009* : There is now a [http://code.google.com/p/psom/wiki/ConfigurationPsom tutorial] which describes in details how to configure PSOM.

*May 15th, 2009* : Release 0.8.3. 
  * A new flag `opt.flag_verbose` allows to get rid of all the verbose.
  * A new flag `opt.flag_pause` allows to get rid of the pauses in the initialization stage.
  * PSOM has now been tested with Octave 3.0.1 and 3.0.4
  * A new execution mode : `msub`. The options of msub are passed through `opt.qsub_options`. 
  * Verbose of all pipeline updates when restarting the pipeline manager. The pipeline execution now makes a pause and asks for the user's approval before anything is actually processed.
  * A 'time' option in `psom_pipeline_visu` to display the computation time of all jobs.
  * A new function `psom_write_dependencies` to write dependency graphs in pdf format using the opensource graphviz package.  
  * Several minor bug fix.  

*February 1st, 2009* : Release 0.8.1/2. Minor bug fixes and improvements.

*January 26th, 2009* : Release 0.8. Differences with version 0.7 are minor, but the demo `psom_demo_pipeline` is now complete and the [http://code.google.com/p/psom/wiki/HowToUsePsom PSOM tutorial] is available.

*December 29th, 2008* : Release 0.7. The update feature is now working, which means that `psom_run_pipeline` can be executed multiple times in the same log folder, and should deal in a sensible way with changes made to the pipeline. There is also a new logo for the PSOM project.

*December 13th, 2008* : Release 0.6.0.3. The way the pipeline manager deals with job status has been completely revised. The pipeline manager is now able to deal easily with pipelines of up to 5000 jobs and probably more.

*November 20th, 2008* : Release 0.6.0.2. A first successful test on a big pipeline (>5000 jobs with a complex dependency graph) has been done. Learning from that test, a number of improvements have been made to speed up the pipeline manager.

*November 11th, 2008* : Already a bunch of bug fixes that needed to be done. Release 0.6.0.1 has been tested on Linux and should work. Still a couple features missing though.

*November 10th, 2008* : First public release (0.6) of the PSOM project, see the [http://code.google.com/p/psom/wiki/Milestones milestones page] for features. The tests have been limited so far to Linux. 
