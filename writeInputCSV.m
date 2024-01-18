function [success, outFFN] = writeInputCSV( s3BatchFolder, pngFolder )
% Inputs:
%   pngFolder = ...'\Batches\2024_01_02\png_images'
%   
%   s3BatchFolder    -- s3 bucket parent folder where images are hosted. Need
%                   this for writing the batch's text file. e.g.,
% 
% Outputs:
%   success -- binary informing whether the process was fully completed.
%   outFFN = input.csv file's ffn, written to parent of pngFolder.

narginchk( 2, 2 );
nargoutchk( 0, 2 );

try
    % Concatenate s3FolderName with all png file names and extensions
    pngFiles = dir(fullfile(pngDir, '*.png'));
    batchWriteFFN = transpose( fullfile( s3BatchFolder, {pngFiles.name} ) );

    % Create a table with one variable 'image_url' to denote file header.
    dataTable = table( batchWriteFFN, 'VariableNames', {'image_url'});

    % Write the table as a CSV file
    outFFN = fullfile( fileparts( pngDir ), 'input.csv' );
    writetable( dataTable, outFFN );
    
    success = true;
catch
    success = false;
    outFFN = '';
end