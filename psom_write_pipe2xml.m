function [] = psom_write_pipe2xml(pipeline, path_write, opt)
%
%
% ___________________________________________________________________________
% SUMMARY PSOM_WRITE_PIPE2XML
%
% Split a pipeline into seperate jobs and create a xml file of the pipeline.
% 
% SYNTAX:
% [] = PSOM_WRITE_PIPE2XML(PIPELINE,PATH_WRITE,OPT)
%
% ___________________________________________________________________________
% INPUTS
%
% PIPELINE
%       (structure) A formated PSOM PIPELINE.
% 
% PATH_WRITE
%       (string) String containing the folder where to save the outputs.
%
% OPT
%       (structure) with the following fields :
%       
%       XML_NAME
%           (string) Name of the xml file to save in.
% 
%       PATH_JOBS
%           (string) Path where to save the jobs.
% 
% ___________________________________________________________________________
% OUTPUTS
%
% PIPELINE.xml
% 
%       A .xml file containing the pipeline.
%       
%       If OPT.XML_NAME is specified, that filename will be used instead.
%
%   
% JOB_(NAME OF JOB).mat 
% 
%       Files for each job in the given PIPELINE.
%
%       Will be saved in PATH_WRITE folder or OPT.PATH_JOBS if defined.
% 
% _________________________________________________________________________
% COMMENTS:
%
% Empty file strings or strings equal to 'gb_niak_omitted' in the pipeline
% description are ignored in the dependency graph and checks for
% the existence of required files.
%
% If a pipeline is already running (a 'PIPE.lock' file could be found in
% the logs folder), a warning will be issued and the user may choose to
% stop the pipeline execution. Otherwise, the '.lock' file will be deleted
% and the pipeline will be restarted.
%
% If this is not the first time a pipeline is executed, the pipeline
% manager will check which jobs have been successfully completed, and will
% not restart these ones. If a job description has somehow been
% modified since a previous processing, this job and all its children will
% be restarted. For more details on this behavior, please read the
% documentation of PSOM_PIPELINE_INIT or run the pipeline demo in
% NIAK_DEMO_PIPELINE.
%
% Copyright (c) Sebastien Lavoie-Courchesne, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : pipeline, xml

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


gb_name_structure = 'opt';
gb_list_fields = {'xml_name','path_jobs'};
gb_list_defaults = {strcat(path_write,'pipeline.xml'),path_write};
niak_set_defaults;

num_jobs = 1;

[deps,deps,files_in,files_out,files_clean,deps] = psom_build_dependencies(pipeline);

[fid, msg] = fopen(xml_name,'w','native');
if (fid == -1)
  printf(msg);
  exit(-1);
end

fprintf(fid,'<?xml version="1.0" encoding="UTF-8" ?>');
fprintf(fid,'<xml>');

for [job,name] = pipeline
  list_jobs{num_jobs} = name;
  num_jobs++;
  fprintf(fid,'<job>');

  save(strcat(path_jobs,'job_',name,'.mat'),'-struct','job');

  fprintf(fid,strcat('<id>',md5sum(name,true),'</id>'));
  fprintf(fid,strcat('<name>',name,'</name>'));
  fprintf(fid,strcat('<job_file>',strcat(name,'.mat'),'</job_file>'));

  if ~isempty(deps.(name))
    for [name2,name2] = deps.(name)
      fprintf(fid,strcat('<dependencies>',md5sum(name2,true),'</dependencies>'));
    end
  end

  if ~isempty(files_in.(name))
    for num = 1:length(files_in.(name))
      fprintf(fid,strcat('<files_in>',files_in.(name){num},'</files_in>'));
    end
  end

  if ~isempty(files_out.(name))
    for num = 1:length(files_out.(name))
      fprintf(fid,strcat('<files_out>',files_out.(name){num},'</files_out>'));
    end
  end

  if ~isempty(files_clean.(name))
    for num = 1:length(files_clean.(name))
      fprintf(fid,strcat('<files_clean>',files_clean.(name){num},'</files_clean>'));
    end
  end

  fprintf(fid,'</job>');
end

fprintf(fid,'</xml>');
test = fclose(fid);
if (test == -1)
  printf('There was an error closing the xml file. It might be corrupted, or it might not.');
end