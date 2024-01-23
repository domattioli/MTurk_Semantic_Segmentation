function [success, resultTable] = decodeBatchResults( fullFileName, targetSize, T )
%DECODEBATCHRESULTS Interpret csv formetted results data from MTurk
%   Input the fullFileName of the result file saved within the 'results'
%   subdirectory. The directory format is expected to follow a specific
%   architecture; refer to the README.md file in this folder for more info.
%   targetSize variable is optional and will default to [512 512].
%   
%   See also STAPLE, PREPROCESSIMAGESFORMTURKBATCHES, DECODETURKENCODINGS,
%   GRADETURKERSUBMISSIONS, WRITEBATCHRESULTFILE.
%==========================================================================


% Check I/O.
narginchk( 1, 3 );
nargoutchk( 0, 2 );
if nargin == 1
    targetSize = [512 512];
    T = 0.95;
elseif nargin == 2
    T = 0.95;
end


colNameReferenceFileName = 'batch_csv_col_names.txt'; % hardcoded
try
    % Discern names of folders, subfolders, file.
    [rfp, rfn, e] = fileparts( fullFileName );
    batchFullFolderName = fileparts( rfp );
    pngFullFolderName = fullfile( batchFullFolderName, 'png_images' );
    projectFullFolderName = fileparts( fileparts( fileparts( batchFullFolderName ) ) );
    resultFileName = strcat( rfn, e );
    modifiedResultFileName = strcat( rfn, '-modified', e );
    
    % Read in reference file for column names for reading batch data.
    colNameReferenceFFN = fullfile( projectFullFolderName, colNameReferenceFileName );
    fid = fopen( colNameReferenceFFN, 'r' );
    headerStr = fgetl( fid );
    fclose( fid );
    elements = regexp( headerStr, '"(.*?)"', 'tokens' );
    colNames = cellfun( @(x) x{1}, elements, 'UniformOutput', false );

    % Read in batch data. Num col names - 2 bc they are empty fields for
    % accepting and rejecting the turker data. NOTE: possible bug causer
    modifiedFullFileName = fullfile( rfp, modifiedResultFileName );
    success = convertResultsCsvToTabDelimited( fullFileName, modifiedFullFileName );
    assert(success, 'Failed to delimit batch result csv file.');
    
    turkTable = readtable( modifiedFullFileName, 'delimiter', '\t',...
        'ExpectedNumVariables', numel( colNames )-2 );
    delete( modifiedFullFileName ); % TO-DO: function above should be renamed and designed to output the table and delete the new temp file.
    turkTable.Properties.VariableNames = colNames( 1:end-2 );
    
    % Preallocate data using info in input.csv file.
    inputCSVFFN = fullfile( batchFullFolderName, 'input.csv' );
    inputCSVTable = readcell( inputCSVFFN );
    numImages = size( inputCSVTable, 1 ) - 1;
    imageNames = cell( numImages, 2 );
    if size( inputCSVTable, 2 ) == 3
        fid = fopen( inputCSVFFN );
        idx = 1;
        while 1
            tline = fgetl( fid );
            if ~ischar( tline ), break, end
            if idx > 1
                [imageNames{ idx-1, 1 }, imageNames{ idx-1, 2 }] = fileparts( tline );
            end
            idx = idx + 1;
        end
        fclose( fid );
    else
        for idx = 1:numImages
            imageNames{ idx, 1 } = strcat( inputCSVTable{ idx+1, 1 }, inputCSVTable{ idx+1, 2 } );
            [~,imageNames{ idx, 2 }] = fileparts( imageNames{ idx, 1 } );
        end
    end
    resultColNames = ["srcImage", "TurkerData", "Stapled", "s3url"];
    variableTypes = { 'double', 'struct', 'logical', 'string' };
    resultTable = table( 'Size', [numImages, numel( resultColNames )],...
        'VariableNames', resultColNames, 'VariableTypes', variableTypes);
    resultTable.Properties.RowNames = imageNames( :, 2 );
    resultTable.s3url = vertcat( imageNames{ :, 1 } );
    
    % Preallocate for known variable data.
    numPixels = prod( targetSize );
    resultTable.srcImage = NaN( numImages, numPixels );
    resultTable.TurkerData = repmat( struct( 'IDs', char(), 'Encodings', [],...
        'Decodings', [], 'WorkTimes', [], 'Grades', table(), 'Weights', zeros( numPixels, 1 ) ),...
        numImages, 1 );
    resultTable.Stapled = false( numImages, numPixels );
    jobName = turkTable.Properties.VariableNames{ end };
    searchSpace = table2cell( turkTable( : , 'Input.image_url' ) );
    bw = false( targetSize );
    
    % Iterate through each row (submission) to aggregate the data.
    for idx = 1:numImages
        pngName = strcat( imageNames{ idx, 2 }, '.png' );
        resultTable.srcImage( idx, : ) = reshape( imresize( imread( fullfile(...
            pngFullFolderName, pngName ) ), targetSize ), 1, numPixels );

        % Grab data from turkers who worked on this image.
        it = contains( searchSpace, pngName );
        numSubmissions = sum( it );
        resultTable.TurkerData( idx ).IDs = table2array( turkTable( it, 'WorkerId' ) );
        resultTable.TurkerData( idx ).Encodings = table2array( turkTable( it, jobName ) );
        resultTable.TurkerData( idx ).Decodings = false( numPixels, numSubmissions );
        resultTable.TurkerData( idx ).WorkTimes = table2array( turkTable( it, 'WorkTimeInSeconds' ) );
        for jdx = 1:numSubmissions
            [s, tmp, ~,fidMsg] = decodeTurkEncodings( resultTable.TurkerData( idx ).Encodings{ jdx } );
            if s == false
                warning( ['Turker ''', resultTable{ idx, 'TurkerIDs' }{1}{jdx},...
                    ''' decoding was not successfully decoded.'] )
            end
            bw( : ) = imresize( tmp, targetSize );
            resultTable.TurkerData( idx ).Decodings( :, jdx ) = bw( : );
        end

        % Check if any turkers performed HIT twice (batch posted > 1x).
        [uniqueValues, ~, jdx] = unique( resultTable.TurkerData( idx ).IDs );
        counts = histcounts( jdx, 1:numel(uniqueValues)+1);
        nonUniqueIndices = find(counts > 1);
        if any( nonUniqueIndices )
            for i = nonUniqueIndices % Append '_M' to non-unique elements
                indices = find( jdx == i );
                for j = 2:numel(indices) % Don't overwrite original name
                    resultTable.TurkerData( idx ).IDs{indices(j)} =...
                        [resultTable.TurkerData( idx ).IDs{indices(j)}, '_', num2str(j)];
                end
            end
        end
    end

    % Compute individual grades.
    [s, resultTable] = gradeTurkerSubmissions( resultTable, T );
    if s == false
        warning( ['Failed to grade all turker submissions for:\n',...
            resultTable.Properties.RowNames{ idx }] )
    end
    success = true;
catch
    success = false;
    resultTable = [];
end