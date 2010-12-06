function [] = psom_visu_dependencies(pipeline)
%
% _________________________________________________________________________
% SUMMARY OF PSOM_VISU_DEPENDENCIES
%
% Visualize the graph of dependencies of a pipeline
%
% SYNTAX:
% [] = PSOM_VISU_DEPENDENCIES(PIPELINE)
%
% _________________________________________________________________________
% INPUTS:
%
% PIPELINE
%       (structure) a pipeline structure, see PSOM_RUN_PIPELINE
%
% _________________________________________________________________________
% OUTPUTS:
% 
% None. The function draws a graph where the nodes are jobs and the arrows
% dependencies based on the list of input/output files.
%
% _________________________________________________________________________
% SEE ALSO:
%
% PSOM_BUILD_DEPENDENCIES, PSOM_RUN_PIPELINE
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, pipeline, fMRI, PMP

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

if exist('biograph')
    
    [graph_deps,list_jobs,files_in,files_out,files_clean,deps] = psom_build_dependencies(pipeline);
    bg = biograph(graph_deps,list_jobs);
    dolayout(bg);
    view(bg);

else
    
    warning('I could not find the BIOGRAPH command. This probably means that the Matlab bioinformatics toolbox is not installed. Sorry dude, I can''t plot the graph. The command PSOM_WRITE_DEPENDENCIES may be an alternative.')
    
end

