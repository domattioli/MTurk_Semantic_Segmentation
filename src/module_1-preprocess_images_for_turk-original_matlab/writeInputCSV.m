function outFFN = writeInputCSV( s3BatchFolder )
%WRITEINPUTCSV Generate input.csv text file for turk job batch.
%   outFFN = WRITEINPUTCSV( s3BatchFolder ) returns the outputted full file
%   name for the generated csv file. Note that the inputted folder must
%   contain png files that will be used for a job batch.
%
%   To-Do: change this function to take in a list of files. Ideally, we
%   don't create copies of the png files every time we do a batch. Instead,
%   when we create a new batch, we select a list of image files, push
%   them to the s3 bucket for MTurk access, run WRITEINPUTCSV to input.csv
%   file, then progromattically create the new job on mturk.
%
%   See also: GENERATEBATCHDIRECTORY, WRITEINPUTCSV, PUSHIMAGESTOMTURK,
%   GENERATELISTOFIMAGES,PUBLISHBATCHTOTURK.
%==========================================================================


% Check I/O.
narginchk( 1, 1 );
nargoutchk( 0, 1 );

% Concatenate s3FolderName with all png file names and extensions
pngFiles = dir(fullfile(pngDir, '*.png'));
batchWriteFFN = transpose( fullfile( s3BatchFolder, {pngFiles.name} ) );

% Create a table with one variable 'image_url' to denote file header.
dataTable = table( batchWriteFFN, 'VariableNames', {'image_url'});

% Write the table as a CSV file
outFFN = fullfile( fileparts( pngDir ), 'input.csv' );
writetable( dataTable, outFFN );
