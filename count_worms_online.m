%% Setup with preliminary questions

plates_per_condition = input('How many plates per condition? ');
spots_per_plate = input('How many spots per plate? ');
column_names = cell(1, spots_per_plate);
for spot_ix = 1:spots_per_plate
    column_names{spot_ix} = input(sprintf('Enter name for column %d: ', spot_ix), 's');
end

%% Image acquisition setup

% We only need mono, but the preview function looks choppy for mono for
% some reason, thus we use RGB.
vid_obj = videoinput('qimaging', 1, 'BAY8_2560x1920');

% You can change the exposure to get the best constrast:
vid_src = getselectedsource(vid_obj);
set(vid_src, 'Exposure', 0.2);

%% Acquisition loop
result = horzcat({''}, column_names);

while true
    condition = input('Enter the condition name (nothing to quit): ', 's');
    if isempty(condition)
        break;
    end
    
    for condition_ix = 1:plates_per_condition
        result(end+1,:) = horzcat({condition}, cell(1, length(column_names)));
        
        for spot_ix = 1:spots_per_plate
            % Present the GUI to the user:

            fprintf('Acquiring data for condition %s, plate %d, spot %s...', ...
                condition, condition_ix, column_names{spot_ix});

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
                                condition, condition_ix, column_names{spot_ix}),...
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
            imwrite(imcomplement(rgb2gray(getsnapshot(vid_obj))),...
                '_temp.tiff', 'tiff');
            [worm_size, worm_num] = count_worms_image('_temp.tiff', 150, 450);
            fprintf('Avg worm size: %.1f; counted %d worms.\n', worm_size, worm_num);
            
            manual_add = input('Worms to add manually (nothing means 0): ');
            if isempty(manual_add)
                manual_add = 0;
            end
            
            result{end, spot_ix+1} = num2str(worm_num + manual_add);
        end
    end
end

% csvwrite/xlswrite can't handle cells in Matlab 2012...
out_file = fopen('result.csv', 'w');
[rows, cols] = size(result);
for row_ix = 1:rows
    for col_ix = 1:cols
        fprintf(out_file, '%s', result{row_ix, col_ix});
        
        if col_ix < cols
            fprintf(out_file, ',');
        end
    end
    
    fprintf(out_file, '\r\n');
end