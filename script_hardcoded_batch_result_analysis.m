% Hardcoded
targetSize = [512,512];
batchFolderName = 'C:\Users\dmattioli\Projects\MTurk\PSHF_Humerus_Segmentation\Batches\2023_12_19';
resultFileName = 'Batch_5169454_batch_results.csv';
varNames = {'HITId','HITTypeId','Title','Description','Keywords','Reward',...
    'CreationTime','MaxAssignments','RequesterAnnotation','AssignmentDurationInSeconds',...
    'AutoApprovalDelayInSeconds','Expiration','NumberOfSimilarHITs','LifetimeInSeconds',...
    'AssignmentId','WorkerId','AssignmentStatus','AcceptTime','SubmitTime',...
    'AutoApprovalTime','ApprovalTime','RejectionTime','RequesterFeedback',...
    'WorkTimeInSeconds','LifetimeApprovalRate','Last30DaysApprovalRate',...
    'Last7DaysApprovalRate','Input.image_url',...
    'Answer.humerusSemSeg.inputImageProperties.height',...
    'Answer.humerusSemSeg.inputImageProperties.width',...
    'Answer.humerusSemSeg.labelMappings.Humerus.color',...
    'Answer.humerusSemSeg.labeledImage.pngImageData,Approve,Reject'};

 addpath( genpath( pwd ));

 thres = 0.95;

%% Ground truth data
gtFilename = 'testing-motivation for batches.xlsx';
gtData = readtable( gtFilename );
numFiles = height( gtData );

% prep a new table for aggregating all data.
columnNames = ["ImageID", "srcImage", "gtImage", "TurkerIDs", "HITId"....
    "TurkerEncoded", "TurkerDecoded", "Stapled", "Grades"];
variableTypes = {'cell', 'cell', 'cell', 'cell', 'logical', 'cell'};
% myAnalysis = table('Size', [0, numel(columnNames)], 'VariableNames', columnNames, 'VariableTypes', variableTypes);
myTable = cell( numFiles, numel( columnNames ) );
myTable( :, 1 ) = gtData.Image;

% Read in and resize images.
folderName = fullfile( batchFolderName, 'png_images' );
fileList = dir(fullfile(folderName, '*.png'));  % Adjust the file extension as needed
imageDataCellArray = cell( numFiles, 1);
fid = fopen(tempFilePath, 'w');
for i = 1:numFiles
    imageData = imread( fullfile(folderName, fileList(i).name ) );
    myTable{ i, 2 } = imresize( imageData, targetSize );
    if ~isnan( gtData.PNGData(i) )
        decodedBytes = typecast( matlab.net.base64decode( gtData.PNGData{i} ), 'uint8');
        fwrite(fid, decodedBytes, 'uint8');
        bw = bwareafilt( logical( imread( tempFilePath ) ), 1 );
        myTable{ i, 3 } = imresize( bw, targetSize );
    end
end
fclose(fid);
delete( tempFilePath );

myCellTable = myTable;
myTable = cell2table( myTable( :, 2:end ), 'VariableNames', columnNames( 2:end ) );
myTable.Properties.RowNames = myCellTable( :, 1 );


%% Turker data
% preprocess it
folderName = fullfile( batchFolderName, 'results' );
filePath = fullfile( batchFolderName, 'results',...
    strrep( resultFileName, '.csv', '-processed.csv' ) );
success = convertResultsCsvToTabDelimited( resultFileName, filePath );

turkTable = readtable( filePath, 'delimiter', '\t' );
turkTable.Properties.VariableNames = varNames;
encodedVarName = 'Answer.humerusSemSeg.labeledImage.pngImageData,Approve,Reject';

% Find the turker results for each of our image
figure;cla;

set(gcf,'Color','w')
nTs = NaN( numImages, 1 );
for i = 1:height( myTable )
    r = myTable.Properties.RowNames{i};
    iTurkers = find( strcmp( turkImageNames, r ) );
    numTurkers = numel( iTurkers );
    nTs( i ) = numTurkers;
    myTable{ r, 'TurkerIDs' }{1} = transpose( table2cell( turkTable( iTurkers, 'WorkerId' ) ) );
    myTable{ r, 'HITId' }{1} = transpose( table2cell( turkTable( iTurkers, 'HITId' ) ) );
    turkerSubmissions = turkTable( iTurkers, encodedVarName );
    encodedBWs = transpose( table2cell( turkerSubmissions ) );
    myTable{ r, 'TurkerEncoded' }{1} = encodedBWs;
    turkerBW = cell( 1, numTurkers );
    if numTurkers == 0
        continue
    elseif numTurkers > 1
        unrolledBWs = nan( targetSize(1 ) * targetSize( 2 ), numTurkers );
        for j = 1:numTurkers
            tempFilePath = tempname;
            fid = fopen(tempFilePath, 'w');
            decodedBytes = typecast( matlab.net.base64decode( encodedBWs{ j } ), 'uint8' );
            fwrite( fid, decodedBytes, 'uint8');
            bw = bwareafilt( logical( imread( tempFilePath ) ), 1 );
            turkerBW{ j } = imresize( bw, targetSize );
            unrolledBWs( :, j ) = turkerBW{ j }( : );
            fclose(fid);
            delete( tempFilePath );
        end
        disp('hello--------')
        % Staple em up dawg
        [W, p, q] = STAPLE( unrolledBWs );
        myTable{ r, 'Stapled' }{1} = reshape( W, targetSize );
    else
        decodedBytes = typecast( matlab.net.base64decode( encodedBWs{1} ), 'uint8');
        fwrite( fid, decodedBytes, 'uint8');
        bw = bwareafilt( logical( imread( tempFilePath ) ), 1 );
        turkerBW{ 1 } = imresize( bw, targetSize );
        W = turkerBW{ 1 };
        myTable{ r, 'Stapled' }{1} = W;
    end
    myTable{ r, 'TurkerDecoded' }{1} = turkerBW;
    
    % Grades
    dscs = NaN( 1, numTurkers );
    for j = 1:numTurkers
        guessBW = turkerBW{ j };
        avgBW = myTable{ r, 'Stapled' }{1} > thres;
        dscs( j ) = dice( guessBW, avgBW );
    end
    myTable{ r, 'Grades' }{ 1 } = dscs;

    randomColors = rand( numTurkers, 3);
    randomColors(randomColors(:, 1) > 0.6, :) = rand(sum(randomColors(:, 1) > 0.6), 3);

    tmp = myTable{ r, 'srcImage' }{1};
    % cla;subplot(1,2,1);
    for k = 1:numTurkers
        tmp = imoverlay( tmp, boundarymask( turkerBW{ k } ), randomColors( k, : ) );
        % imshow( tmp );hold on;
    end
    % imshow( imoverlay( tmp, boundarymask( myTable{ r, 'Stapled' }{1} > thres ), 'r') );
    % imName = myTable.Properties.RowNames{ i };
    % title( [imName, ': Turker Submissions'],'FontSize',25,'Interpreter','Latex')
    % subplot(1,2,2);
    % imshow( imoverlay( myTable{ r, 'srcImage' }{1}, boundarymask( myTable{ r, 'Stapled' }{1} > thres ), 'r' ))
    % title( [imName, ': Stapled Result'],'FontSize',25,'Interpreter','Latex')
    % pause;
end


close



% Create a figure for the bar plot
data = NaN( height( myTable ), 10 );
for i = 1:height( myTable ) 
    % Extract data from the cell array
    dataTmp = cell2mat( myTable{ i , 'Grades'} );
    data( i, 1:length( dataTmp ) ) = dataTmp;
end

% Rejecting some by hand...
[r,c]=find(data==0)
myTable( r, : )
any(any( myTable{ r(2),"TurkerDecoded"}{1}{3} > 0 ))

myTable{ r(2),"TurkerIDs"}{1}{3}
myTable{ r(2),"HITId"}{1}{3} 

figure;
myBins = 1:height(myTable);
imageDSC = bar( myBins, data, 'stacked' );
bp = boxplot( transpose( data ) )
xlabel( 'Image', 'FontSize', 15,  'Interpreter', 'latex' )
ylabel( 'Num Turkers', 'FontSize', 15, 'Interpreter', 'latex')
title( 'Difficult of Images - Stacked by Turker', 'FontSize', 25, 'Interpreter', 'latex')
xticklabels( myTable.Properties.RowNames )



figure;
mybinEdges = 0:0.1:1;
myBins = ( mybinEdges(1:end-1) + mybinEdges(2:end) ) / 2;
numBins = length(mybinEdges);
hcounts = zeros( height( myTable ), numBins-1 );
legendLabels = cell( height( myTable ), 1 );
for k = 1:height( myTable )
    hcounts( k, : ) = histcounts( data( k, : ), mybinEdges );
    legendLabels{ k } = myTable.Properties.RowNames{ k };
end
stackedHist = bar( myBins, hcounts, 'stacked' );
faceColors = colorcube( height( myTable ) );
for k = 1:height( myTable )
    stackedHist( k ).FaceColor = faceColors( k, : );
end
xlabel( 'Similarity', 'FontSize', 15, 'Interpreter', 'latex' )
ylabel( 'Frequency', 'FontSize', 15, 'Interpreter', 'latex')
title( 'Performance of Turkers - Stacked by Image', 'FontSize', 25, 'Interpreter', 'latex')
L = legend(legendLabels,'Orientation','Horizontal', 'Interpreter', 'latex','Location','Northwest' );
L.NumColumns = 8;




figure;
allGrades = [];
for i=1:height( myTable )
    allGrades = horzcat( allGrades, cell2mat( myTable{ i , 'Grades'}));
end
histogram( allGrades );
xlabel( 'Similarity', 'FontSize', 15, 'Interpreter', 'latex' )
ylabel( 'Frequency', 'FontSize', 15, 'Interpreter', 'latex')
title( 'Performance of Turkers Overall', 'FontSize', 25, 'Interpreter', 'latex')



% Access specific group or rows using indexed cell array, e.g., grouped_rows{1}
