function [summary_results, all_results] = count_worms_directory(varargin)
% COUNT_WORMS_DIRECTORY analyzes sets of images and estimates worm count
%   
%   [SUMMARY_RESULTS, ALL_RESULTS] = count_worms_directory() allows gui
%       selection of the directory to analyze.  The directory must contain
%       sets of images numbered 1 to N where N is number of trials.
%
%           e.g. eth1.png, but1.png, ori1.png, tot1.png
%
%       SUMMARY_RESULTS is a Nx5 cell array with the counts for each trial
%           This is saved in a file named 'worm_counts_summary.csv' in the
%           directory specified.
%
%       ALL_RESULTS outputs one row per image, indicating the treatment,
%           trial number, the size of a worm, and the worm count.  This is
%           saved in a file named 'worm_counts_stats.csv'.
%
%   [SUMMARY_RESULTS, ALL_RESULTS] = count_worms_directory(directory)
%
%   [SUMMARY_RESULTS, ALL_RESULTS] = count_worms_directory(directory, minsize, maxsize)
%       minsize - Regions smaller than min_size will be discarded
%           default = 10
%       maxsize - Regions smaller than max_size will be used to determine 
%            the size of a single worm
%           default = 80

p = inputParser;
p.FunctionName = 'count_worms_directory';
p.addOptional('inputDir', '', @isdir);
p.addOptional('minsize',150,@isnumeric); % Regions smaller than this will be discarded
p.addOptional('maxsize',450,@isnumeric); % Regions smaller than this will determine single worm size
p.parse(varargin{:});
min_worm_size = p.Results.minsize; 
max_worm_size = p.Results.maxsize; 

if ( (isfield(p.Results,'inputDir')) && ~strcmp(p.Results.inputDir,''))
    input_dir = p.Results.inputDir;
else
    input_dir = uigetdir([],'Select Directory');
end

% First, create a table to store data in:
but_images = dir([input_dir filesep '*_processed.tif']);
indexes = {};
row_names = {};
col_names = {'Trial_name'};
trial_names = {};
for i=1:size(but_images,1)
    tokens = regexpi(but_images(i).name, '(\d+)_(.*?)_(.*?)[._]', 'tokens');
    tokens = tokens{1}; % TBD: why do we need the extra {1}?
    %n = str2double(tokens{1});
    ix = tokens{1};
    row_name = tokens{2};
    col_name = strrep(tokens{3}, ' ', '_');
    
    if ~any(strcmp(indexes, ix))
        indexes{end+1} = ix;
        trial_names{end+1} = row_name;
    end
    
    row_names{end+1} = row_name;
    if ~any(strcmp(col_names, col_name))
        col_names{end+1} = col_name;
    end
end

output = array2table(nan*ones(length(indexes), length(col_names)), 'VariableNames', col_names);
output.Properties.RowNames = indexes;
output.Trial_name = trial_names';

% Add 'debug' columns:
filenames = cell(length(indexes), 1);
for i=1:length(filenames)
    filenames{i} = '';
end

for i = 2:length(col_names)
    col_name = col_names{i};
    
    output(:, [col_name '_external']) = num2cell(zeros(length(indexes), 1));
    output(:, [col_name '_manual']) = num2cell(zeros(length(indexes), 1));
    output(:, [col_name '_filename']) = filenames;
end

% Count the worms:
for i=1:size(but_images,1)
    disp(but_images(i).name);
    tokens = regexpi(but_images(i).name, '(\d+)_(.*?)_(.*?)[._]', 'tokens');
    tokens = tokens{1}; % TBD: why do we need the extra {1}?
    ix = tokens{1};
    col_name = strrep(tokens{3}, ' ', '_');
    
    [worm_size, num_worms] = count_worms_image([input_dir filesep but_images(i).name], 'minsize', min_worm_size, 'maxsize', max_worm_size);
    
    if isnan(num_worms)
        num_worms = 0;
    end
    
    manual_worms = input('How many worms to add manually (nothing means 0)? ');
    if isempty(manual_worms)
        manual_worms = 0;
    end
    
    out_of_field_worms = 0;
    out_of_field_worms_match = regexpi(but_images(i).name, '_p(\d+)', 'tokens');
    if ~isempty(out_of_field_worms_match)
        t_ = out_of_field_worms_match{1};
        out_of_field_worms = str2double(t_);
    end
    
    output{ix, [col_name '_external']} = out_of_field_worms;
    output{ix, [col_name '_manual']} = manual_worms;
    output{ix, [col_name '_filename']} = {but_images(i).name};
    output{ix, col_name} = num_worms + manual_worms + out_of_field_worms;
end

writetable(output, [input_dir filesep 'worm_counts_summary.csv']);
end