function []=psom_quarentine_svn(quarentine_path,svn_rev_libs)



if ~exist('quarentine_path','var')
    error(strcat('You need to specify the quarentine path!'))
    return;
end

% Remove any filesep at the end of the path
if strcmp(quarentine_path(end),filesep)
    quarentine_path = quarentine_path(1:end-1);
end

% Create destination path
if ~exist(quarentine_path)
    psom_mkdir(quarentine_path);
end

% Get the SVN root repositories
vers = psom_version_svn();
if exist('svn_rev_libs','var')
    
    if ~isstruct(svn_rev_libs)
        error(strcat('The quarentine path must be a struct: .name and .version'))
        return;
    end
    
    for k=1:size(vers,2)
        
        for i=1:size(svn_rev_libs,2)
            
            if ~isfield(svn_rev_libs(i),'name')
                error(strcat('You need to specify the .name field'))
                return;
            end
            if ~isfield(svn_rev_libs(i),'version')
                error(strcat('You need to specify the .version field'))
                return;
            end
            
            if isequal(vers(k).name,svn_rev_libs(i).name)
                % Check if version is a number
                if isnumeric(svn_rev_libs(i).version)
                    svn_rev_libs(i).version = num2str(svn_rev_libs(i).version);
                end

                % Create destination folder
                destination_folder = cat(2,filesep,svn_rev_libs(i).name,svn_rev_libs(i).version);

                % Execute the svn export command
                fprintf('%s\n',cat(2,'Exporting the quarentine of "',svn_rev_libs(i).name,'" Version: ',svn_rev_libs(i).version,' ...'))
                [status,output]=system(cat(2,'svn export -r ',svn_rev_libs(i).version,' ',vers(k).path,' ',quarentine_path,destination_folder,' 2>&1'));
                fprintf('%s\n',cat(2,svn_rev_libs(i).name,': ',output))
            end
        end
    end
else
        
    for k=1:size(vers,2)

        %Clean the version string
        vers(k).version(strfind(vers(k).version,':')) = '-';
        vers(k).version(regexp(vers(k).version,'\n')) = '';

        % Create destination folder
        destination_folder = cat(2,filesep,vers(k).name,vers(k).version);

        % Execute the svn export command
        fprintf('%s\n',cat(2,'Exporting the quarentine of "',vers(k).name,'" ...'))
        [status,output]=system(cat(2,'svn export ',vers(k).path,' ',quarentine_path,destination_folder,' 2>&1'));
        fprintf('%s\n',cat(2,vers(k).name,': ',output))

    end
end

end