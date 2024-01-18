function [success, visTable] = visualizeResults( resultTable, resultFFN, targetSize )
%VISUALIZERESULTS Visualize overlays of individual submissions on gt.
%   success = visualizeResults( resultTable, resultFFN, targetSize ) returns binary
%   'success' to indicate a successful writing of the resultTable variable.
%   Each individual segmentation will be overlaid onto the base image, and
%   then their aggregated staple will be overlaid onto that. Resulting
%   images will be written to the batch's result directory.
%
%   [~, visTable] = visualizeResults( resultTable, resultFFN, targetSize )
%   also returns a table contining the visualizations for the respective
%   rows in resultTable.
%
%   See also: DECODEBATCHRESULTS, WRITEBATCHRESULTFILE.
%==========================================================================

narginchk( 2, 3 );
nargoutchk( 0, 2 );

try
    [pn, ~] = fileparts( resultFFN );
    analysisPN = fullfile( pn, 'Analysis' );
    overlaidPN = fullfile( analysisPN, 'Overlaid_Images' );
    otherPlotsPN = fullfile( analysisPN, 'Other_Plots' );
    if ~isfolder( analysisPN )
        mkdir( overlaidPN );
        mkdir( otherPlotsPN );
    end

    % Prepare a table for storing visualizations.
    [numImages, numPixels]   = deal( height( resultTable ), 3 * prod( targetSize ) );
    visVars = {'Individuals', 'Stapled', 'All' };
    visVarTypes = { 'uint8', 'uint8', 'uint8' };
    visTable = table('size',[numImages, numel( visVars )], 'VariableTypes', visVarTypes, 'VariableNames', visVars );
    visTable.Properties.RowNames = resultTable.Properties.RowNames;
    visTable.Properties.Description = 'Individual turker submissions overlaid onto base image, along with STAPLED aggregate.';
    visTable.Individuals = zeros( numImages, numPixels, 'uint8' );
    visTable.Stapled = visTable.Individuals;
    visTable.All = visTable.Individuals;

    % Iterate through each image, creating overlays with individuals and with staple.
    stapledBW  = false( targetSize );
    srcImg = zeros( targetSize );
    bpData = cell( numImages, 1 );
    fov = figure('visible', 'on', 'color', 'w', 'WindowState', 'maximized' );
    axov = gca;
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
        visTable.Individuals( jdx, : ) = reshape( tmp, 1, numPixels );
        visTable.Stapled( jdx, : ) = reshape( overlaidStaple, 1, numPixels );
        visTable.All( jdx, : ) = reshape( overlaidAll, 1, numPixels );
        
        % Save images.
        imName = visTable.Properties.RowNames{ idx };
        imwrite( tmp, fullfile( overlaidPN, [imName, '-individual_turkers.png'] ), 'png' )
        imwrite( overlaidStaple, fullfile( stapledPN, [imName, '-stapled.png'] ), 'png' )
        imwrite( overlaidAll, fullfile( indAndStapledPN, [imName, '-stapled_and_individuals.png'] ), 'png' )

        % Prep for boxplots.
        bpData{ idx } = transpose( resultTable.TurkerData( idx ).Grades.Similarity );
    end

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
    sc = swarmchart( axbp, bpXData, bpYData, 45, '.', XJitter='rand', XJitterWidth=0.25 );
    hold on;
    bp = boxplot( axbp, bpYData );
    xlabel( 'Image', 'FontSize', 15, 'Interpreter', 'latex' );
    xlim( [0.5, numImages+0.5] );
    xticks( 1:numImages );
    xticklabels( resultTable.Properties.RowNames );
    xtickangle( 45 );
    ylabel( 'Dice Coefficient', 'FontSize', 15, 'Interpreter', 'latex');
    ylim([0 1.05]);
    title( 'Summary Statistics of Turker Submissions', 'FontSize', 20, 'Interpreter', 'latex' )
    grid on;

    % Save visualization(s).
    exportgraphics( fbp, fullfile( otherPlotsPN, 'Box_and_Swarm_plots.tiff' ) );
    savefig( fbp, fullfile( otherPlotsPN, 'Box_and_Swarm_plots.fig' ), 'compact' );
    close( fbp );
    success = true;
catch
    visTable = [];
    success = false;
end

