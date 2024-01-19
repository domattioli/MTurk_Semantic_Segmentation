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

 thres = 0.95; % **** This will be a monte carlo variable

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
    disp([' iteration: ', num2str( i ) ])
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


%% Monte Carlo
% Variables:
%   1. image
%       - all (15)
minImgInd = 1;
maxImgInd = 15;
rangeImages = minImgInd:1:maxImgInd;
%   2. # of turkers
%       - 2 to 10
minTurkers = 2;
maxTurkers = 10;
rangeTurkers = minTurkers:1:maxTurkers;
%   3. thresholded Staple
%       - 0.5 to 0.99
minThresh = 0.50;
maxThresh = 0.99;
rangeThresh = minThresh:0.05:maxThresh;
numThreshs = numel( rangeThresh );

% Compute all possible turker combos.
turkerCombos = cell( maxTurkers - minTurkers, 1 );
turkerCombosM = [];
for groupSize = 2:maxTurkers
    turkerCombos{ groupSize-1 } = nchoosek(1:maxTurkers, groupSize);
    tmp = size( turkerCombos{ groupSize-1 } );
    if tmp( 1 ) > 1
        turkerCombosM = vertcat( turkerCombosM,...
            mat2cell( turkerCombos{ groupSize-1 }, ones( tmp( 1 ), 1 ), tmp( 2 ) ) );
    else
        turkerCombosM = vertcat( turkerCombosM, turkerCombos{ groupSize-1 } );
    end
end
turkerCombosM( end ) = [];
numCombos = length( turkerCombosM );

numIter = maxImgInd * numCombos;
rng('shuffle')

% Prep table.
MCvarNames = {'srcImageName', 'NumTurkers', 'TurkerIDs','TurkerDecoded','LocalStaple','Grade'};
MCvarTypes = {'cell', 'double', 'cell', 'cell', 'cell','cell'};
MCT = table( 'Size', [numIter, numel(MCvarNames)],...
    'VariableNames', MCvarNames, 'VariableTypes', MCvarTypes );
% MCT.Thresh = iterData( :, :, 1 );
% MCT.NumTurkers = iterData( :, 2 );
% MCT.srcImageName = myTable.Properties.RowNames( iterData( :, end ) );

% prep figure
figure;
set(gcf,'color','w');
hp = scatter( NaN( numIter, 1 ), NaN( numIter, 1 ),'Marker','.');
title( 'DSC v num Turkers','FontSize',25);
xlabel('num turkers','FontSize',15);
ylabel('DSC wrt 10-Turker STAPLE','FontSize',15);
xlim([1.5 9.5])
ylim([0.35,1.05])
cmap = jet( maxImgInd );
grid on
hp.CData = NaN( numIter, 3 );

% Simulate
grades = nan( 1, numThreshs );
W = NaN( targetSize );
H = waitbar(0,'progress: 0%');
ir = 1;
for img = 1:maxImgInd
    gt = imbinarize( myTable{img,'Stapled'}{1} );
    for tcom = 1:numCombos
        MCT.srcImageName( ir ) = myTable.Properties.RowNames( img );
        MCT.TurkerIDs{ ir } = turkerCombosM{ tcom };
        numT = length( MCT.TurkerIDs{ ir } );
        MCT.NumTurkers( ir ) = numT;
        try
            decodedImgs = myTable{...
                MCT.srcImageName( ir ), 'TurkerDecoded' }{1}( MCT.TurkerIDs{ ir } );
        catch
            ir = ir+1;
            continue
        end
        unrolledBWs = nan( targetSize(1 ) * targetSize( 2 ), numT );
        for jdx = 1:numT
            unrolledBWs( :, jdx ) = decodedImgs{jdx}(:);
        end
        W(:) = STAPLE( unrolledBWs );
        % MCT.LocalStaple{ ir } = W;
        for t = 1:numThreshs
            grades( t ) = dice( gt, W >= rangeThresh(t ) );
        end
        MCT.Grade{ ir } = grades;
        newX = numT + ( -0.25 + 0.5 .* rand( 1, 1 ) );
        hp.XData(ir) = newX;
        hp.YData(ir) = grades(end);
        hp.CData(ir,:) = cmap( img, :);
        ir = ir + 1;

        waitbar( ir/numIter, H );
        H.Children.Title.String= num2str( round( ir/numIter * 100, 2 ) );
    end
end

xData = round( hp.XData, 0 );
yData = hp.YData();
xEndD = xData( numThreshs:numThreshs:length( xData ) );
yEndD = yData( numThreshs:numThreshs:length( xData ) );
cEndD = hp.CData( numThreshs:numThreshs:length( xData ), : );
figure;
set(gcf,'color','w');
hp2 = scatter( hp.XData( numThreshs:numThreshs:length( xData ) ) ,yEndD, marker='.');
hp2.CData = cEndD;
title( 'DSC v num Turkers - Only 90% Thresh','FontSize',25);
xlabel('num turkers','FontSize',15);
ylabel('DSC wrt 10-Turker STAPLE','FontSize',15);
xlim([1.5 9.5])
ylim([0.35,1.05])
grid on

figure;
set(gcf,'color','w');
hp3 = scatter( hp.XData( numThreshs:numThreshs:length( xData ) ) ,yEndD, marker='.');
hp3.CData = cEndD;
hp3.CData( : ) = 0;
hp3.SizeData = 1;
title( 'DSC v num Turkers - Only 90% Thresh','FontSize',25);
xlabel('num turkers','FontSize',15);
ylabel('DSC wrt 10-Turker STAPLE','FontSize',15);
grid on
groupedData = NaN( 356, numTurkers );
meanmedian = NaN( 2, numTurkers );
for idx = 2:numTurkers
    tmp = yEndD( xEndD == idx );
    groupedData( 1:numel(tmp ), idx ) = tmp;
    meanmedian( :, idx ) = vertcat( mean(tmp),median(tmp));
end
hold on;
bp = boxplot( groupedData,'OutlierSize', 5 );
meanp = plot( 2:numTurkers-1, meanmedian( 1, 2:9 ), 's','markerfacecolor', 'g', 'MarkerEdgeColor','g');
medianp = plot( 2:numTurkers-1, meanmedian( 2, 2:9 ), 'o','markerfacecolor', 'b' );
xlim([1.5 9.5])
ylim([0.4,1.05])




%% Statistical Analysis

subT = MCT( :, {'srcImageName','NumTurkers'} );
gradeV = nan( height( subT ), 1 );
for idx = 1:height(subT)
    try
    gradeV(idx) = MCT{idx,'Grade'}{1}(end);
    catch
    end
end
subT = addvars( subT, gradeV, 'NewVariableNames', 'Grade' )

% ANOVA, batching by image.
mdl = fitlm( subT, 'Grade ~ NumTurkers*srcImageName' )



