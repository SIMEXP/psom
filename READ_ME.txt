=Pipeline System for Octave and Matlab (PSOM), version 0.8.9=

A pipeline is a collection of jobs, i.e. matlab or octave codes with a well identified set of options that are using files as inputs and are producing files as outputs. PSOM is a framework to implement, run and re-run pipelines in Matlab or Octave :
  * Describe the pipeline using a straightforward structure representation.
  * Automatically run jobs in parallel whenever possible using multiple CPUs or within a distributed computing environment.
  * Automatically generate log files and keep track of the pipeline description.
  * Handle job failures : successful completion of jobs is checked and failed jobs can be restarted.
  * Handle updates of the pipeline : change options or add jobs and let PSOM figure out what to reprocess !

PSOM is an opensource project distributed under an [http://www.opensource.org/licenses/mit-license.php MIT opensource license]. It is currently in a beta-testing stage and has been tested under Linux (in Matlab and Octave) and windows (in Matlab). To install PSOM, just extract the [http://code.google.com/p/psom/downloads/list archive] in a folder and add that folder to your matlab or octave search path. You're done ! You may have to adapt the [http://code.google.com/p/psom/wiki/ConfigurationPsom configuration] to your local production environment. To use PSOM, you can have a look at the code of `psom_demo_pipeline`, or read [http://code.google.com/p/psom/wiki/HowToUsePsom the tutorial].

PSOM was implemented by Pierre [http://simexp-lab.org/brainwiki/doku.php?id=pierrebellec Bellec] in the lab of [http://www.bic.mni.mcgill.ca/~alan/ Alan Evans] at the !McConnell Brain Imaging Center, Montreal Neurological Institute, !McGill University, Canada, 2008-10. Core ideas have been inspired by the [http://wiki.bic.mni.mcgill.ca/index.php/PoorMansPipeline Poor Man's Pipeline (PMP) project] developed by Jason Lerch, which was itself based on [http://www.bic.mni.mcgill.ca/~jason/rppl/rppl.html RPPL] by Alberto Jimenez and Alex Zijdenbos. 

----
LICENSE

Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-10.
Département d'informatique et de recherche opérationnelle
Centre de recherche de l'institut de Gériatrie de Montréal
Université de Montréal, 2010-2011
Maintainer : pierre.bellec@criugm.qc.ca

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

See http://code.google.com/p/psom/wiki/ReleaseNotes for a list of changes made 
since the last release.
