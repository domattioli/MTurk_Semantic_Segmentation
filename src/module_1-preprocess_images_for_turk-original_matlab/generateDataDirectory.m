function newFolderNames = generateDataDirectory( newTurkJobName )
%GENERATEDATADIRECTORY Create subdirectory hierarchy for new job.
%   [success, newFolderNames] = GENERATEDATADIRECTORY( newTurkJobName )
%   returns the newFolderNames corresponding to alle new subfolders
%   generated for a new turk job and subsequent batches.
%
%   NOTE that GENERATEDATADIRECTORY assumes the following format for the
%   newTurkJobName input: Header-Future_Comp_Vision_Task, e.g., data for
%   training a wire segmentation model for dynamic hip screw (DHS)
%   surgeries should be denoted by the input 'DHS-Wire_Segmentation'.
%
%   See also: GENERATEBATCHDIRECTORY, WRITEINPUTCSV.
%==========================================================================

% Check I/O.
narginchk( 1, 1 );
nargoutchk( 0, 1 );
assert( ischar( newTurkJobName ), 'Inputted job name must be a string.' );

% Construct the folder hierarchy based on the newTurkJobName
dataFolder = fullfile( pwd, 'data' );
folderNames = strsplit(newTurkJobName, '-');
assert( numel( folderNames ) == 2, 'Inputted turk job string must be in the format Header-Future_Comp_Vision_Task.' )
folderNames = horzcat( folderNames, {'Batches'} );

% Create subdirectories
placeHolderPath = dataFolder;
newFolderNames = cell(1, numel(folderNames));
for idx = 1:numel(folderNames)
    placeHolderPath = fullfile( placeHolderPath, folderNames{idx} );
    newFolderNames{idx} = placeHolderPath;

    % Check if the directory already exists before creating it
    if ~isfolder(placeHolderPath)
        mkdir(placeHolderPath);
    end
end

% Ensure all new folders are on the matlab path.
subDirPaths = strsplit( genpath( dataFolder) , ';' );
subDirPathsNotOnPath = subDirPaths( ~contains( subDirPaths, path ) );
addpath( subDirPathsNotOnPath{ : } );

% Return the variable containing the paths to the created folders
newFolderNames = transpose( newFolderNames );
