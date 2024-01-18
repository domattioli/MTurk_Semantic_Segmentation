function [success, outputFolder] = writeInputCSV( inputFolder, s3Folder, pngFolder )
% Inputs:
%   inputFolder -- directory location of source images (usually .tiff).
%                   Images must be png. e.g.,
%   inputFolder = 'C:\Users\dmattioli\Projects\MTurk\PSHF_Humerus_Segmentation\Batches\2024_01_02\tiff_images'
%   
%   s3Folder    -- s3 bucket parent folder where images are hosted. Need
%                   this for writing the batch's text file. e.g.,
%   s3Folder = 'https://fluoros-mturk-instructions.s3.amazonaws.com/Femur/Batches/YYYY_MM_DD/imageName.png'
% 
% Outputs:
%   success -- binary informing whether the process was fully completed.
%   outputFolder -- directory location where png images are saved. e.g.,
%   outputFolder = 'C:\Users\dmattioli\Projects\MTurk\PSHF_Humerus_Segmentation\Batches\2024_01_02\png_images'

narginchk( 3, 3 )

try
    % Create the output folder if it doesn't exist
    [parentFolder, ~, ~] = fileparts( inputFolder );
    % if nargin == 2
    %     pngFolder = fullfile( parentFolder, 'png_images' );
    % end
    if ~exist(pngFolder, 'dir')
        mkdir(pngFolder);
    end
    if isempty( s3Folder )
        error('s3Folder variable cannot be an empty string');
    end
    if s3Folder(end) == '/' || s3Folder(end) == '\'
        warning('s3Folder input should not end with a fileseparator variable / or \. Output may be incorrect.');
        s3Folder = s3Folder( 1:end-1 );
    end

    % Loop through all files
    files = dir(fullfile(inputFolder, '*.*'));
    numFiles = length( files ) - 2;
    batchWriteFFN = cell( numFiles, 1 );
    for i = 1:length(files)
        filename = files(i).name;

        inputPath = fullfile(inputFolder, filename);

        % Check if the file is an image
        [~, ~, ext] = fileparts(filename);
        supportedFormats = {'.png', '.jpg', '.jpeg', '.bmp', '.gif', '.tiff'};
        if any(strcmpi(ext, supportedFormats))
            % Read the image
            img = imread(inputPath);

            % Construct the output path
            [~, name, ~] = fileparts(filename);
            newFileName = horzcat( name, '.png' );
            if i > 2 % my gosh
                batchWriteFFN{i-2} = horzcat( s3Folder, '/', newFileName );
            end
            outputPath = fullfile(pngFolder, newFileName );

            % Write the image as PNG
            imwrite(img, outputPath);
        end
    end

    % Write file names with s3folder prefix to CSV
    csvFilePath = fullfile( parentFolder, 'input.csv');
    fileNamesTable = table( batchWriteFFN, 'VariableNames', {'image_url'} );
    writetable(fileNamesTable, csvFilePath);
    success = true;
    disp('Success -- True!')
catch
    success = false;
    warning( 'Success -- False!')
end