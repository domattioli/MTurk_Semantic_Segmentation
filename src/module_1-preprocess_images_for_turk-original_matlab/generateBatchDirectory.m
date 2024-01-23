function success = generateBatchDirectory( turkJobName, batchDate )
%GENERATEBATCHDIRECTORY Create subdirectory hierarchy for a new batch of job.
%   success = GENERATEBATCHDIRECTORY( turkJobName, batchDate ) returns a
%   binary success variable following the generation of a hierarchy of
%   folders to be used for future processing of the batch created on
%   batchDate. batchDate must be a string in the formate of 'YYYY-MM-DD'.
%
%   NOTE that GENERATEBATCHDIRECTORY assumes the following format for the
%   inputs:
%       1. turkJobName: Header-Future_Comp_Vision_Task, e.g., data for
%       training a wire segmentation model for dynamic hip screw (DHS)
%       surgeries should be denoted by the input 'DHS-Wire_Segmentation'.
%
%       2. batchDate: string indicated date of batch creation, i.e., 'YYYY-MM-DD'.
%
%   See also: GENERATEDATADIRECTORY, WRITEINPUTCSV.
%==========================================================================

% Check I/O.
narginchk( 2, 2 );
nargoutchk( 0, 1 );
assert( ischar( turkJobName ), 'Inputted turk job name must be a char.' );
assert( isfolder( turkJobName ), 'Inputted job must already exist.' );
assert( ischar( batchDate ), 'Inputted batch date must be a char.' );

% Check the format of batchDate
validateattributes(batchDate, {'char'}, {'nonempty', 'size', [1, 10]}, mfilename, 'batchDate');
validateDateFormat(batchDate);

% Construct directory paths
baseDir = fullfile( pwd, 'data' );
folderNames = strsplit(turkJobName, '-');
assert( numel( folderNames ) == 2, 'Inputted turk job string must be in the format Header-Future_Comp_Vision_Task.' )

jobDir = fullfile(baseDir, folderNames{ 1 }, folderNames{ 2 } );
assert( isfolder( jobDir ), 'Inputted turk job must already exist.' )
batchDir = fullfile(jobDir, 'Batches', batchDate);
resultsDir = fullfile(batchDir, 'results');
analysisDir = fullfile(batchDir, 'analysis');

% Create directories
createDirectory(batchDir);
createDirectory(resultsDir);
createDirectory(analysisDir);
end

function createDirectory(directoryPath)
% Create directory if it doesn't exist
if ~isfolder(directoryPath)
    mkdir(directoryPath);
end
end

function validateDateFormat(batchDate)
try
    datevec(batchDate, 'yyyy-mm-dd');
catch
    error('Invalid date format. Use ''YYYY-MM-DD'' format for batchDate.');
end
end