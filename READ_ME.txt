Summary of the project : Pipeline System for Octave and Matlab (PSOM).
This is PSOM v. 0.6.0.3 Please visit http://code.google.com/p/psom/ for more details.

==What is PSOM ?==
The PSOM project is a small set of .m Matlab/octave functions to manage pipelines, both within a single session or in a parallel computing environment. A pipeline is a collection of jobs, i.e. some matlab or octave code that uses files as inputs and produce files as outputs. PSOM is automatizing all the boring tasks for you: 
  * Determine which jobs can run in parallel by examining the dependencies between inputs and outputs of jobs. Note that it is possible to specify the number of processes that can be started in parallel.
  * Take care of processing each job. Three modes are available:
    * in a single matlab/octave session, on a single machine
    * in multiple matlab/octave sessions through batch, on a single machine with multiple CPUs.
    * in multiple matlab/octave sessions trough qsub (pbs and sge are supported), on multiple computers.
  * Job failure will not crash the pipeline. The pipeline manager identifies the jobs that have failed to produce their expected outputs, and will be able to restart these failed jobs latter.
  * Update the options of a pipeline, and restart only the jobs that these new options will impact.
  * Generate log files
  * Keep track of options
  * Create folders for outputs

----
==Why use PSOM ?==
Here comes the propaganda. Using PSOM compared to a 'quick-and-dirty' script has the following critical advantages : 
  * Parallelize your code with no effort !The same code can run a pipeline locally or in parallel on multiple PCs. Just change one option.
  * Save time : no need to write the 'quick-and-dirty' script. That limits the possibility for bugs, too.
  * All steps of processing are precisely tracked. 
  * The pipeline manager makes viability checks on the pipeline BEFORE starting it. If one gets mixed up with file names, it is better to know sooner than latter. Looking at the graph of the pipeline also helps a lot to debug.
  * Deal with failed jobs in a smart and safe way.
  * Deal with pipeline updates in a smart and safe way.

----
==Who has contributed to PSOM ?==
The pipeline system was implemented by Pierre [http://wiki.bic.mni.mcgill.ca/index.php/PierreBellec Bellec] at the !McConnell Brain Imaging Center, Montreal Neurological Institute, !McGill University, Canada, 2008. Core ideas for PSOM have been inspired by the [http://wiki.bic.mni.mcgill.ca/index.php/PoorMansPipeline Poor Man's Pipeline (PMP) project], that was coded in PERL. 

----
==How to use PSOM ?==

To install PSOM, just extract the archive in a folder and add that folder to you matlab search path. You're done ! To use PSOM, you can have a look at the code of PSOM_DEMO_PIPELINE, or read [http://code.google.com/p/psom/w/list the wiki pages].

----
==Is PSOM opensource ?==

Sure ! it is distributed under an MIT opensource license (see below).

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





