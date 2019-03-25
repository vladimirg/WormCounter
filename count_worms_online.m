%% Setup with preliminary questions

output_file_name = input('Enter the output file name including the extension (usually .csv): ', 's');
plates_per_condition = input('How many plates per condition? ');
spots_per_plate = input('How many spots per plate? ');
spot_names = cell(1, spots_per_plate);
column_names = cell(1, spots_per_plate*5);
for spot_ix = 1:spots_per_plate
    spot_name = input(sprintf('Enter name for column %d: ', spot_ix), 's');
    spot_names{spot_ix} = spot_name;
    column_names((spot_ix-1)*5+1:spot_ix*5) = {...
        [spot_name, ' - total worm pixels'], ...
        [spot_name, ' - worm size'], ...
        [spot_name, ' - raw worm count'], ...
        [spot_name, ' - manually added worms'], ...
        [spot_name, ' - final worm pixels'], ...
    };
end

%% Image acquisition setup

% We only need mono, but the preview function looks choppy for mono for
% some reason, thus we use RGB.
vid_obj = videoinput('qimaging', 1, 'BAY8_2560x1920');

% You can change the exposure to get the best constrast:
vid_src = getselectedsource(vid_obj);
set(vid_src, 'Exposure', 0.2);

%% Acquisition loop
% We use sequential writing because our setup crashes occasionally and we
% don't want to lose the work.
out_file = fopen(output_file_name, 'w');

for i=1:length(column_names)
    fprintf(out_file, [',', column_names{i}]);
end
fprintf(out_file, '\r\n');

while true
    condition = input('Enter the condition name (nothing to quit): ', 's');
    if isempty(condition)
        break;
    end
    
    fprintf(out_file, condition);
    
    for condition_ix = 1:plates_per_condition        
        for spot_ix = 1:spots_per_plate
            % Present the GUI to the user:

            fprintf('Acquiring data for condition %s, plate %d, spot %s...', ...
                condition, condition_ix, spot_names{spot_ix});

            % This code was borrowed from
            % https://www.mathworks.com/help/imaq/previewing-data.html#f11-76067
            % It has more examples to add widgets, for example if we need to
            % change the exposure in the future.

            % Create the image object in which you want to
            % display the video preview data.
            vidRes = vid_obj.VideoResolution;
            imWidth = vidRes(1);
            imHeight = vidRes(2);
            nBands = vid_obj.NumberOfBands;
            
            
            % Create a figure window. This example turns off the default
            % toolbar and menubar in the figure.
            hFig = figure('Toolbar','none',...
                   'Menubar', 'none',...
                   'NumberTitle','Off',...
                   'Name',...
                        sprintf('Condition %s, plate %d, spot %s', ...
                                condition, condition_ix, spot_names{spot_ix}),...
                   'OuterPosition', [100 100 imWidth/2 imHeight/2]);
               
            hImage = image( zeros(imHeight, imWidth, nBands) );

            % Specify the size of the axes that contains the image object
            % so that it displays the image at the right resolution and
            % centers it in the figure window.
            figSize = get(hFig,'Position');
            figWidth = figSize(3);
            figHeight = figSize(4);
            gca.unit = 'pixels';
            gca.position = [ ((figWidth - imWidth)/2)... 
                           ((figHeight - imHeight)/2)...
                           imWidth imHeight ];

            preview(vid_obj, hImage);
            uiwait(hFig);

            % Acquire image and process it:
            [worm_size, worm_num] = count_worms_image(imcomplement(rgb2gray(getsnapshot(vid_obj))), 150, 450);
            fprintf('Avg worm size: %.1f; counted %d worms.\n', worm_size, worm_num);
            
            manual_add = input('Worms to add manually (nothing means 0): ');
            if isempty(manual_add)
                manual_add = 0;
            end

            fprintf(out_file, ',%d,%d,%d,%d,%d', ...
                worm_size * worm_num, worm_size, worm_num, manual_add, ...
                worm_size * worm_num + worm_size * manual_add);
            
            % This should flush the output file stream.
            drawnow update;
        end
        
        fprintf(out_file, '\r\n');
    end
end

fclose(out_file);