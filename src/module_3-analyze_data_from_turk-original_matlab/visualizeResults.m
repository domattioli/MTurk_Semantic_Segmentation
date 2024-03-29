function [visTable, overlaidPN, otherPlotsPN] = visualizeResults(...
    resultTable, turkerTable, thresh, resultFFN, targetSize )
%VISUALIZERESULTS Visualize overlays of individual submissions on gt.
%   visTable = visualizeResults( resultTable, thresh, resultFFN, targetSize ) returns binary
%   'success' to indicate a successful writing of the resultTable variable.
%
%   visTable = visualizeResults( resultTable, thresh, resultFFN, targetSize )
%   returns a table contining the visualizations for the respective rows in
%   the inputted resultTable.
%   Notes:
%       - Each individual segmentation are overlaid onto its base image.
%       - STAPLED (aggregated) segmentation probabilities are computed.
%       - The consensus segmentation is computed via thresholding (thresh).
%       - Consensus segmentation is overlaid onto base image with and
%       without the individual turker segmentations.
%       -  Resulting images arewritten to the batch's result dir resultFFN.
%
%   See also: STAPLE, DECODEBATCHRESULTS, WRITEBATCHRESULTFILE, 
%   GENERATEPOWERPOINTRESULTS.
%==========================================================================

% Check I/O.
narginchk( 4, 5 );
nargoutchk( 0, 3 );

pn = fileparts( fileparts( resultFFN ) );
tn = num2str( thresh );
analysisPN = fullfile( pn, strcat( 'Analysis-Thresh_', tn(3:end) ) );
overlaidPN = fullfile( analysisPN, 'Individual_Overlaid' );
otherPlotsPN = fullfile( analysisPN, 'Other_Plots' );
stapledPN = fullfile( analysisPN, 'Staple_Overlaid' );
if ~isfolder( analysisPN )
    mkdir( overlaidPN );
    mkdir( otherPlotsPN );
    mkdir( stapledPN );
end

% Prepare a table for storing visualizations.
[numImages, numPixels]   = deal( height( resultTable ), 3 * prod( targetSize ) );
visVars = {'Individuals', 'Stapled', 'All', 'Stats' };
visVarTypes = { 'uint8', 'uint8', 'uint8', 'struct' };
visTable = table('size',[numImages, numel( visVars )], 'VariableTypes', visVarTypes, 'VariableNames', visVars );
visTable.Properties.RowNames = resultTable.Properties.RowNames;
visTable.Properties.Description = 'Individual turker submissions overlaid onto base image, along with STAPLED aggregate.';
visTable.Individuals = zeros( numImages, numPixels, 'uint8' );
visTable.Stapled = visTable.Individuals;
visTable.All = visTable.Individuals;
statStruct = struct( 'Outliers', [], 'Lower_Whisker', [], 'Mean', [],...
    'Median', [], 'Variance', [], 'IQR', [], 'Box', [], 'Upper_Whisker', [] );
visTable.Stats = repmat( statStruct, numImages, 1 );

% Iterate through each image, creating overlays with individuals and with staple.
stapledBW  = false( targetSize );
srcImg = zeros( targetSize );
bpData = cell( numImages, 1 );
fov = figure('visible', 'off', 'color', 'w', 'WindowState', 'maximized' );
subplot( 1, 2, 1 );
for idx = 1:numImages
    % Random colors for individual turkers -- red reserved for staple.
    numTurkers = numel( resultTable.TurkerData( idx ).IDs );
    randomColors = parula( numTurkers );
    % randomColors( randomColors( :, 1 ) > 0.6, : ) = rand( sum( randomColors( :, 1 ) > 0.6 ), 3 );

    % Overlay individuals onto base image one at a time.
    srcImg( : ) = resultTable.srcImage( idx, : ) ./255;
    tmp = reshape( srcImg, targetSize );
    for jdx = 1:numTurkers
        turkerBW = reshape( resultTable.TurkerData( idx ).Decodings( :, jdx ), targetSize );
        tmp = imoverlay( tmp, boundarymask( turkerBW ), randomColors( jdx, : ) );
    end

    % Overlay stapled.
    stapledBW( : ) = boundarymask( resultTable.Stapled( idx, : ) );
    overlaidStaple = imoverlay( srcImg, stapledBW, 'r' );
    overlaidAll = imoverlay( tmp, stapledBW, 'r' );
    visTable.Individuals( idx, : ) = reshape( tmp, 1, numPixels );
    visTable.Stapled( idx, : ) = reshape( overlaidStaple, 1, numPixels );
    visTable.All( idx, : ) = reshape( overlaidAll, 1, numPixels );

    % Create montage of staple with individuals.
    imName = visTable.Properties.RowNames{ idx };
    subplot( 1, 2, 1 ); imshow( overlaidAll, 'Parent', gca );
    title( 'Individual Turker Submissions', 'FontSize', 15, 'Interpreter', 'Latex' );
    subplot( 1, 2, 2 ); imshow( overlaidStaple, 'Parent', gca );
    title( 'Stapled Aggregate', 'FontSize', 15, 'Interpreter', 'Latex' );
    sgtitle( imName, 'FontWeight', 'bold', 'Interpreter', 'None' );

    % Save images.
    exportgraphics( fov, fullfile( overlaidPN, [imName, '-individuals_and_stapled.tiff'] ),...
        'Resolution', 1000, 'BackgroundColor', 'w' );
    imwrite( overlaidStaple, fullfile( stapledPN, [imName, '-stapled.png'] ), 'png' );
    imwrite( overlaidAll, fullfile( stapledPN, [imName, '-stapled_and_individuals.png'] ), 'png' );

    % Prep for boxplots.
    bpData{ idx } = transpose( resultTable.TurkerData( idx ).Grades.Similarity );
end
close( fov )

% Create swarmplot of raw data, overlay boxplots.
numTurkersPerImg = cellfun( @numel, bpData );
maxNumTurkers = max( numTurkersPerImg );
bpYData = NaN( maxNumTurkers, numImages );
for idx = 1:numImages
    bpYData( 1:numTurkersPerImg( idx ), idx ) = bpData{ idx };
end
bpXData = repmat( 1:numImages, maxNumTurkers, 1 );

fbp = figure( 'visible', 'off', 'color', 'w', 'WindowState', 'maximized' );
axbp = gca;
scSize = 45;
scMarker = '.';
scJitWidth = 0.25;
sc = swarmchart( axbp, bpXData, bpYData, scSize, scMarker, XJitter='rand', XJitterWidth=scJitWidth );
hold on;
bp = boxplot( axbp, bpYData );
xlabel( 'Image', 'FontSize', 15, 'Interpreter', 'latex' );
xlim( [0.5, numImages+0.5] );
xticks( 1:numImages );
xticklabels( resultTable.Properties.RowNames );
xtickangle( 45 );
ylabel( 'Dice Coefficient', 'FontSize', 15, 'Interpreter', 'latex');
ylim([0 1.05]);
yticks( 0:0.1:1);
title( 'Summary Statistics of Turker Submissions', 'FontSize', 20, 'Interpreter', 'latex' )
grid on;

% Assign boxplot data to visualization table.
for idx = 1:numImages
    isout = isoutlier( bpYData( :, idx ) );
    visTable.Stats( idx ).Outliers = bpYData( isout, idx );
    visTable.Stats( idx ).Median = median( bpYData( ~isout, idx ), 'omitnan' );
    visTable.Stats( idx ).Mean = mean( bpYData( ~isout, idx ), 'omitnan' );
    visTable.Stats( idx ).Variance = var( bpYData( ~isout, idx ), 'omitnan' );
    visTable.Stats( idx ).Box = quantile( bpYData( ~isout, idx ), [.25 .75] );
    visTable.Stats( idx ).IQR = iqr( bpYData( ~isout, idx ) );
    [visTable.Stats( idx ).Lower_Whisker,...
        visTable.Stats( idx ).Upper_Whisker] = bounds( bpYData( ~isout, idx ), 'omitnan' );
end

%-----------------------------------------
% Histogram of turker individual grades
turkerDiceScores = cellfun( @table2array, turkerTable.Grades, 'uniformoutput', 0 );
allDiceScores = cell2mat( turkerDiceScores ); % Ignore sensitivity and specificity.
allDiceScores = allDiceScores( : , 1 );
fitg = figure( 'visible', 'off', 'color', 'w', 'WindowState', 'maximized' );
subplot( 4, 1, 4 );
axitgh = gca;
allDiceScoresHist = histogram( allDiceScores, 'Parent', axitgh );
xlabel( 'Individual Accuracies w.r.t. Group', 'FontSize', 15, 'Interpreter', 'latex' );
axitgh.YLim( 2 ) = round( max( allDiceScoresHist.Values ), -2 );
axitgh.XLim = [-0.025 1.025];
ylabel( 'Count', 'FontSize', 15, 'Interpreter', 'latex' );
% title( 'Histogram of Individual Turker Performance Across All Images' , 'FontSize', 20, 'Interpreter', 'latex' );

% Individual boxplots and swarm of turker data.
subplot( 4, 1, 1:3 );
axitbp = gca;
box on;
grid on;
turkerBoxPlotData = transpose( NDcell2mat( turkerDiceScores ) );
turkerBoxPlotData = turkerBoxPlotData( 1:3:end, : ); % Ignore sensitivity and specificity.
[maxNumImages, numUniqueTurkers] = size( turkerBoxPlotData );
tbps = boxplot( axitbp, turkerBoxPlotData );
hold on;
itbpXData = repmat( 1:numUniqueTurkers, maxNumImages, 1 );
size( itbpXData )
size(turkerBoxPlotData  )
itsp = swarmchart( axitbp, itbpXData, turkerBoxPlotData, scSize, scMarker, XJitter='rand', XJitterWidth=scJitWidth );
xlabel( 'Unique Turker', 'FontSize', 15, 'Interpreter', 'latex' );
axitbp.YLim = [-0.05 1.05];
ylabel( 'Accuracy of Submission (Dice Coefficient)', 'FontSize', 15, 'Interpreter', 'latex' );
title( 'Individual Turker Performance Across All Images' , 'FontSize', 20, 'Interpreter', 'latex' );


% Save visualization(s).
exportgraphics( fbp, fullfile( otherPlotsPN, 'Dice_Accuracy-Per_Image.tiff' ) );
savefig( fbp, fullfile( otherPlotsPN, 'Dice_Accuracy-Per_Image.fig' ), 'compact' );
exportgraphics( fitg, fullfile( otherPlotsPN, 'Dice_Accuracy-Per_Turker.tiff' ) );
savefig( fitg, fullfile( otherPlotsPN, 'Dice_Accuracy-Per_Turker.fig' ), 'compact' );
close( fbp );
close( fitg );

