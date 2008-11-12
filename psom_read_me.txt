Summary of the project : Pipeline System for Octave and Matlab (PSOM).
This is PSOM v. 0.6. Please visit http://code.google.com/p/psom/ for more details.

==What is PSOM ?==

The PSOM project is a small set of functions to manage pipelines, that works both under Matlab and Octave. A pipeline is a collection of jobs, i.e. some matlab or octave code that uses files as inputs and produce files as outputs. PSOM is automatizing all the boring tasks : it generate log files, keeps track of options, tests if a job failed, is able to restart the failed jobs only, create folders for outputs, among others.

More importantly, by examining the names of inputs and outputs, PSOM is able to determine which jobs can run in parallel. That can be useful on a single machine with multiple processors, and even more useful in a supercomputing environment with a large number of machines (sge and pbs qsub systems are supported). 

==What do the PSOM exactly do ?==

The current realease includes : 
  * A pipeline manager that initializes, runs and monitors the execution of a pipeline, which can be done in different modes :
    * in the current session.
    * in independent sessions using batch.
    * in independent sessions using a qsub system (compatible with SGE and PBS).
  * A tool to represent the pipeline as a graph.
  * A simple demonstration script.
  * A stub of documentation, see [http://code.google.com/p/psom/ the wiki page].

==Who has contributed to the NIAK ?==

The pipeline system was implemented by Pierre [http://wiki.bic.mni.mcgill.ca/index.php/PierreBellec Bellec] at the !McConnell Brain Imaging Center, Montreal Neurological Institute, !McGill University, Canada, 2008. However, PSOM ports many of the ideas implemented in the Poor Man's Pipeline (PMP) project from Perl to Matlab. 

==How to use PSOM ?==
To install PSOM, just uncompress the archive in a folder and add that folder to you matlab search path. You're done !

To use PSOM, you can have a look at the code of PSOM_DEMO_PIPELINE, or read the wiki pages on [http://code.google.com/p/psom/ the PSOM project's website].

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





