function versions = niak_version_svn()
% Retrieve the svn version of all root library in the matlab PATH 
%
% SYNTAX :
% VERSIONS = PSOM_VERSION_SVN()
%
% _________________________________________________________________________
% INPUTS :
%
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


%%%%%%%%%%%%%%%%%
%%     SVN     %%
%%%%%%%%%%%%%%%%%
    k=0;

    svn_repositories = find_svn_rootdir();

    if ~isempty(svn_repositories)

        for svn_rep_idx = 1:size(svn_repositories,2)
            k=k+1;
            [status,version]=system(cat(2,'svnversion ',svn_repositories{svn_rep_idx}));
            [status,info]=system(cat(2,'svn info ',svn_repositories{svn_rep_idx}));
            [pathstr,name,ext,versn] = fileparts(svn_repositories{svn_rep_idx});

            versions.svn(k).name = name;
            versions.svn(k).version = version;
            versions.svn(k).path = svn_repositories{svn_rep_idx};
            versions.svn(k).info = info;
        end
    end

end


%% sub function
function svn_repositories=find_svn_rootdir()
 
 k=0;
 
 output=path;
 svn_repositories=[];
 
 idx_line = strfind(output,':');
 
 for nb_line=1:size(idx_line,2)
    
    str_path=[];
    if nb_line == 1 
        str_path = output(1:idx_line(nb_line)-1);
    else
        str_path = output(idx_line(nb_line-1)+1:idx_line(nb_line)-1);
    end
    
    % Look if the folder contain a .svn folder
    found_root_dir = dir(str_path);
    for a=1:size(found_root_dir,1)
        
        % if a .svn is found
        if isequal(found_root_dir(a).name,'.svn')
            
            % Look if is the root svn folder
            [pathstr,name,ext,versn] = fileparts(str_path);
            found_dir = dir(pathstr);

            flag_not_rootdir = false;
            for a=1:size(found_dir,1)

                if isequal(found_dir(a).name,'.svn')
                        flag_not_rootdir = true;
                        break
                end

            end

            if ~flag_not_rootdir 
                k=k+1;
                svn_repositories{k} = str_path;
            end
            break
            
        end
    
    end
    
    
    
 end
 
end
 
