function flag_dag = psom_is_dag(adj)
%
% _________________________________________________________________________
% SUMMARY PSOM_IS_DAG
%
% Test if a sparse binary matrix is the adjacency matrix of a directed
% acyclic graph
%
% SYNTAX :
% FLAG_DAG = PSOM_IS_DAG(ADJ)
%
% _________________________________________________________________________
% INPUTS :
%
% ADJ         
%       (sparse binary matris) ADJ(I,J) == 1 only if there is an edge from
%       J to I.
%
% _________________________________________________________________________
% OUTPUTS :
%
% FLAG_DAG
%       (boolean) FLAG_DAG == 1 only if ADJ is the adjacency matrix of an
%       acyclic directed graph.
%
% _________________________________________________________________________
% COMMENTS : 
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : string

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

%% SYNTAX
if ~exist('adj','var')
    error('SYNTAX: FLAG_DAG= PSOM_IS_DAG(ADJ). Type ''help psom_is_dag'' for more info.')
end

flag_dag = true;
list_term_old = [];

while (max(adj(:)) > 0) && flag_dag
    list_term_new = find(max(adj,[],1) == 0); % find terminal nodes
    mask_new = ~ismember(list_term_new,list_term_old);
    
    if max(mask_new)==0
        %% There is no new terminal node, but the matrix is not empty,
        %% there must be a cycle
        flag_dag = false;
    else
        adj(list_term_new(mask_new),:) = 0; % kill all edges pointing at terminal nodes
    end
    list_term_old = list_term_new;
end
    
    