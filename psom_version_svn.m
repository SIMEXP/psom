function [svn]= psom_version_svn(verbose)
% Retrieve the svn version of all root library in the matlab PATH 
%
% SYNTAX :
% VERSIONS = PSOM_VERSION_SVN()
%
% _________________________________________________________________________
% INPUTS :
%   VERBOSE (boolean) (default false)
%   
% _________________________________________________________________________
% OUTPUTS:
%
%   VERSIONS
%       (structure) SVN.NAME Name of the svn lib.
%                   SVN.VERSION version number of the lib.
%                   SVN.PATH path of the svn root lib.
%                   SVN.INFO information from the function svnversion.
%
% _________________________________________________________________________
% COMMENTS : 
%
%
% Copyright (c) Christian L. Dansereau, Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2011.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : svn,version

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

if ~exist('verbose','var')
    verbose = false;
end
%%%%%%%%%%%%%%%%%
%%     SVN     %%
%%%%%%%%%%%%%%%%%
    k=0;
    svn=[];
tic
    svn_repositories = find_svn_rootdir()

    if ~isempty(svn_repositories)

        for svn_rep_idx = 1:size(svn_repositories,2)
            k=k+1;
            [status,version]=system(fullfile('svnversion ',svn_repositories{svn_rep_idx}));
            [status,info]=system(fullfile('svn info ',svn_repositories{svn_rep_idx}));
            [pathstr,name,ext,versn] = fileparts(svn_repositories{svn_rep_idx});

            svn(k).name = name;
            svn(k).version = version;
            svn(k).path = svn_repositories{svn_rep_idx};
            svn(k).info = info;
            
            if verbose
                disp(fullfile(svn(k).name,': ',svn(k).version(2:end)));
            end
            
        end
    end
toc

end


%% sub function
function [svn_repositories]=find_svn_rootdir()
 
 k=0;
 
 output=path;
 svn_repositories=[];
 
 idx_line = strfind(output,':');
 
 for nb_line=1:size(idx_line,2)
    
    if nb_line == 1 
        str_path = output(1:idx_line(nb_line)-1);
    else
        str_path = output(idx_line(nb_line-1)+1:idx_line(nb_line)-1);
    end
    
    % Check if it is not a hiden path
    if isempty(strfind(str_path,'/.'))
    
    % Remove any filesep at the end of the path
        if strcmp(str_path(end),filesep)
            str_path = str_path(1:end-1);
        end

        % Look if the path contain a .svn folder
        if (exist(cat(2,str_path,filesep,'.svn'),'dir') == 7)

            % Look if it's the root svn folder
            [pathstr,name,ext,versn] = fileparts(str_path);

            if (exist(cat(2,pathstr,filesep,'.svn'),'dir') == 7)
                % Do nothing!
            else
                k=k+1;
                svn_repositories{k} = str_path;
            end

        end
    end
 end
 
end


    
