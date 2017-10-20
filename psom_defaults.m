function opt = psom_defaults(def,opt,flag_warning)

if ~isstruct(def)
  error('DEF needs to be a structure')
end

if nargin<2
  opt = struct();
end

if ~isstruct(opt)
  error('OPT needs to be a structure')
end

if nargin < 3
  flag_warning = true;
end

%% Check the fields
list_def = fieldnames(def);
list_opt = fieldnames(opt);
if flag_warning&&any(~ismember(list_opt,list_def))
  warning('The following fields are not expected in the structure %s \n',inputname(1))
  list_opt(~ismember(list_opt,list_def))
end

%% Set defaults
list_val = struct2cell(def);
opt = psom_struct_defaults(opt,list_def,list_val,false);

%% Recursively set defaults inside substructures
for ff = 1:length(list_def)
  if isstruct(def.(list_def{ff}))
    opt.(list_def{ff}) = psom_defaults(def.(list_def{ff}),opt.(list_def{ff}),flag_warning);
  end
end
