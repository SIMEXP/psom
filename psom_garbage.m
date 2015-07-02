function [] = psom_garbage(path_logs,opt)
% Manage the execution of a pipeline
%
% status = psom_garbage(path_logs,opt)
%
% PATH_LOGS (string) the path name to a logs folder.
% OPT.TIME_BETWEEN_CHECKS
% OPT.NB_CHECKS_PER_POINT
% OPT.MAX_QUEUED
% OPT.FLAG_VERBOSE (integer 0, 1 or 2, default 1) No verbose (0), verbose (1).
%
% See licensing information in the code.

% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
% Departement d'informatique et de recherche operationnelle
% Centre de recherche de l'institut de Geriatrie de Montreal
% Universite de Montreal, 2010-2015.
% Maintainer : pierre.bellec@criugm.qc.ca
% Keywords : pipeline
%
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

psom_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting up default values for inputs %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SYNTAX
if ~exist('path_logs','var')
    error('Syntax: [] = psom_garbage(path_logs,opt)')
end

%% Options
if nargin < 2
    opt = struct;
end
opt = psom_struct_defaults( opt , ...
   {  'flag_verbose' , 'time_between_checks' , 'nb_checks_per_point' , 'max_queued' }, ...
   {  1              , NaN                   , NaN                   , NaN          });

%% Logs folder
if ~strcmp(path_logs(end),filesep)
    path_logs = [ path_logs filesep];
end

%% File names
file_status         = [path_logs 'PIPE_status.mat'];
file_status_backup  = [path_logs 'PIPE_status_backup.mat'];
file_logs           = [path_logs 'PIPE_logs.mat'];
file_logs_backup    = [path_logs 'PIPE_logs_backup.mat'];
file_profile        = [path_logs 'PIPE_profile.mat'];
file_profile_backup = [path_logs 'PIPE_profile_backup.mat'];
file_pipe_running   = [path_logs 'PIPE.lock'];
file_heartbeat      = [path_logs 'garbarge_heartbeat.mat'];
file_kill           = [path_logs 'garbage.kill'];
path_worker         = [path_logs 'worker' filesep];
file_news           = [path_logs 'news_feed.csv'];

if opt.max_queued == 0
    % This pipeline is executed in session mode
    % log files are located in the main pipeline directory
    path_search{1} = path_logs;    
else
    for num_w = 1:opt.max_queued
        path_search{num_w} = sprintf('%spsom%i%s',path_worker,num_w,filesep);
    end
end   
   
%% Start heartbeat
main_pid = getpid;
cmd = sprintf('psom_heartbeat(''%s'',''%s'',%i)',file_heartbeat,file_kill,main_pid);
if strcmp(gb_psom_language,'octave')
    instr_heartbeat = sprintf('"%s" %s "addpath(''%s''), %s,exit"',gb_psom_command_octave,gb_psom_opt_matlab,gb_psom_path_psom,cmd);
else 
    instr_heartbeat = sprintf('"%s" %s "addpath(''%s''), %s,exit"',gb_psom_command_matlab,gb_psom_opt_matlab,gb_psom_path_psom,cmd);
end 
system([instr_heartbeat '&']);

%% Load current logs
logs   = load(file_logs);
prof   = load(file_profile);
status = load(file_status);
list_jobs = fieldnames(status);
status_cell = struct2cell(status);
mask_done = false(size(list_jobs));

%% Collect garbage
flag_last_run = false;
flag_run = false;
flag_exit = false;
flag_started = false;
nb_char_news = 0;
nb_checks = 0;
news = [];
while ~flag_exit

    %% Read the news
    new_status = struct;
    new_prof = struct;
    new_logs = struct;
    if psom_exist(file_news)
            
       %% Parse news_feed.csv for one worker
       [str_read,nb_char_news] = sub_tail(file_news,nb_char_news);
       news = [news str_read];
       [events,news] = sub_parse_news(news);
               
       %% Some verbose for the events
       for num_e = 1:size(events,1)
           %% Update status
           mask_job = strcmp(list_jobs,events{num_e,1});
           name_job = list_jobs{mask_job};
           if any(mask_job)
               status.(name_job) = events{num_e,2};
               status_cell(mask_job) = events(num_e,2);
               new_status.(name_job) = events{num_e,2};
           end
       end            
    end
    
    %% Check what jobs need cleaning up
    mask_finished = ismember(status_cell,{'failed','finished'});
    mask_todo = mask_finished&~mask_done;
    
    %% Collect garbage
    list_todo = find(mask_todo);
    flag_nothing_happened = any(mask_todo);
    for num_t = 1:length(list_todo)
        flag_found = false;
        name_job = list_jobs{list_todo(num_t)};
        for num_s = 1:length(path_search)
            file_logs_job = [path_search{num_s} name_job '.log'];
            file_profile_job = [path_search{num_s} name_job '_profile.mat'];
            if psom_exist(file_logs_job)&&psom_exist(file_profile_job)
                flag_found = true;
                logs.(name_job) = sub_read_txt(file_logs_job);
                new_logs.(name_job) = logs.(name_job);
                tmp = load(file_profile_job);
                tmp.worker = num_s;
                prof.(name_job)  = tmp;
                new_prof.(name_job) = prof.(name_job);
                psom_clean(file_logs_job,struct('flag_verbose',false));
                psom_clean(file_profile_job,struct('flag_verbose',false));
                if opt.flag_verbose
                    fprintf('Collecting logs of job %s\n',name_job)
                end
            end
        end
        if ~flag_found
            warning('Could not find logs for job %s\n',name_job)
        end
    end
    
    %% Update the status/logs/profile
    save(file_logs,'-struct','-append','new_logs');
    copyfile(file_logs,file_logs_backup,'f');
    save(file_status,'-struct','-append','new_status');
    copyfile(file_status,file_status_backup,'f');
    save(file_profile,'-struct','-append','new_prof');
    copyfile(file_profile,file_profile_backup,'f');

    %% Wait if necessary
    if flag_nothing_happened && psom_exist(file_pipe_running)
        sub_sleep(opt.time_between_checks)
         
        if (nb_checks >= opt.nb_checks_per_point)
            nb_checks = 0;
            if opt.flag_verbose
                fprintf('.');
            end
            nb_checks = nb_checks+1;
        else
            nb_checks = nb_checks+1;
        end
    end
        
    %% Test if it is time to quit
    flag_exit = flag_started&&flag_last_run;
    if flag_run
        flag_last_run = ~psom_exist(file_pipe_running);
        flag_started = true;
    end
    flag_run = psom_exist(file_pipe_running);
end
      
%% SUBFUNCTIONS

%% Read a text file
function str_txt = sub_read_txt(file_name)

hf = fopen(file_name,'r');
if hf == -1
    str_txt = '';
else
    str_txt = fread(hf,Inf,'uint8=>char')';
    fclose(hf);    
end

%% An octave version of tail
function [str_read,nb_chars] = sub_tail(file_read,nb_chars)
% Read the tail of a text file
hf = fopen(file_read,'r');
fseek(hf,nb_chars,'bof');
str_read = fread(hf, Inf , 'uint8=>char')';
nb_chars = ftell(hf);
fclose(hf);

%% Parse the news      
function [events,news] = sub_parse_news(news)
if isempty(news)
    events = {};
    return
end

% Parse the news feed
news_line = psom_string2lines(news);
if strcmp(news(end),char(10))||strcmp(news(end),char(13))
    % The last line happens to be complete
    news = ''; % we are able to parse eveything
else
    news = news_line{end};
    news_line = news_line(1:end-1);
end
nb_lines = length(news_line);
events = cell(nb_lines,2);
for num_e = 1:nb_lines
    pos = strfind(news_line{num_e},' , ');
    events{num_e,1} = news_line{num_e}(1:pos-1);
    events{num_e,2} = news_line{num_e}(pos+3:end);
end