function [files_in,files_out,opt] = niak_template_brick(files_in,files_out,opt)
% This is a template file for "brick" functions in PSOM
% More info on http://code.google.com/p/psom/wiki/CodingGuidelines
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = PSOM_TEMPLATE_BRICK(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN        
%   (string) a file name of a 3D+t fMRI dataset .
%
% FILES_OUT
%   (structure) with the following fields:
%       
%   CORRECTED_DATA
%      (string, default <BASE NAME FMRI>_c.<EXT>) File name for processed 
%      data.
%      If FILES_OUT is an empty string, the name of the outputs will be 
%      the same as the inputs, with a '_c' suffix added at the end.
%
%   MASK
%      (string, default <BASE NAME FMRI>_mask.<EXT>) File name for a mask 
%      of the data. If FILES_OUT is an empty string, the name of the 
%      outputs will be the same as the inputs, with a '_mask' suffix added 
%      at the end.
%
% OPT           
%   (structure) with the following fields.  
%
%   TYPE_CORRECTION       
%      (string, default 'mean_var') possible values :
%      'none' : no correction at all                       
%      'mean' : correction to zero mean.
%      'mean_var' : correction to zero mean and unit variance
%      'mean_var2' : same as 'mean_var' but slower, yet does not use as 
%      much memory).
%
%   FOLDER_OUT 
%      (string, default: path of FILES_IN) If present, all default outputs 
%      will be created in the folder FOLDER_OUT. The folder needs to be 
%      created beforehand.
%
%   FLAG_VERBOSE 
%      (boolean, default 1) if the flag is 1, then the function prints 
%      some infos during the processing.
%
%   FLAG_TEST 
%      (boolean, default 0) if FLAG_TEST equals 1, the brick does not do 
%      anything but update the default values in FILES_IN, FILES_OUT and 
%      OPT.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_CORRECT_MEAN_VAR
%
% _________________________________________________________________________
% COMMENTS:
%
% That code is just to demonstrate the guidelines for PSOM bricks. It is
% also a good idea to start a new command project by editing this file and
% saving it under the new brick name.
%
% This code is just to demonstrate the principles of a brick. It will crash
% if attempted to run (it has dependencies on the NIAK toolbox).
%
% _________________________________________________________________________
% Copyright (c) <NAME>, <INSTITUTION>, <START DATE>-<END DATE>.
% Maintainer : <EMAIL ADDRESS>
% See licensing information in the code.
% Keywords : PSOM, documentation, template, brick

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = PSOM_TEMPLATE_BRICK(FILES_IN,FILES_OUT,OPT).\n Type ''help psom_template_brick'' for more info.')
end

%% Inputs
if ~ischar(files_in)
    error('FILES_IN should be a string');
end
    
%% Options
fields   = {'type_correction' , 'flag_verbose' , 'flag_test' , 'folder_out' };
defaults = {'mean_var'        , true           , false       , ''           };
if nargin < 3
    opt = psom_struct_defaults(struct(),fields,defaults);
else
    opt = psom_struct_defaults(opt,fields,defaults);
end

%% Check the output files structure
fields    = {'corrected_data'  , 'mask'            };
defaults  = {'gb_psom_omitted' , 'gb_psom_omitted' };
files_out = psom_struct_defaults(files_out,fields,defaults);

%% Building default output names
[path_f,name_f,ext_f] = niak_fileparts(files_in(1,:)); % parse the folder, file name and extension of the input

if strcmp(opt.folder_out,'') % if the output folder is left empty, use the same folder as the input
    opt.folder_out = path_f;    
end

if isempty(files_out.corrected_data)
    files_out.corrected_data = cat(2,opt.folder_out,filesep,name_f,'_c',ext_f);
end

if isempty(files_out.mask)
    files_out.mask = cat(2,opt.folder_out,filesep,name_f,'_mask',ext_f);
end

%% If the test flag is true, stop here !
if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The core of the brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Performing temporal correction of %s on the fMRI time series in file %s',opt.type_correction,opt.files_in);
end

%% Correct the time series 
if flag_verbose
    fprintf('Correct the time series ...\n');
end
[hdr,vol] = niak_read_vol(files_in); % read fMRI data
mask = niak_mask_brain(mean(abs(vol),4)); % extract a brain mask
tseries = niak_vol2tseries(vol,mask); % extract the time series in the mask
tseries = niak_correct_mean_var(tseries,type_correction); % Correct the time series
vol = niak_tseries2vol(tseries,mask);

%% Save outputs
if flag_verbose
    fprintf('Save outputs ...\n');
end

if ~strcmp(files_out.corrected_data,'gb_psom_omitted');
    hdr.file_name = files_out.corrected_data;
    niak_write_vol(hdr,vol);
end

if ~strcmp(files_out.mask,'gb_psom_omitted');
    hdr.file_name = files_out.mask;
    niak_write_vol(hdr,mask);
end
