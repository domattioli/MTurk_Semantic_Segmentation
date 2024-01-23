function [finalStaple, indices] = HITL_TurkAppraisal( baseImg, individualBWs, stapledBW, T )
%HITL_TurkAppraisal is a work in-progress applet prototype for graphically
%displaying turker submissions and their aggregate STAPLE outline. The
%applet allows the user to remove the former and update the latter.
%
% TO-DO:Eventually use Label property and some radiobuttons so user can toggle  on/off instead of deleting.
% TO-DO: autocompute locations of radio buttons.
% To-do: toggle switch should compute (and store) dice coefficient and
% display to user.


% Check I/O.
narginchk( 4, 4 );
nargoutchk( 0, 2 );

% Prep outputs.
[targetSize(1), targetSize(2), numTurkers] = size( individualBWs );
finalStaple = NaN( targetSize );
indices = false( numTurkers, 1 );

% Create a figure with a callback for right-click
f = uifigure( 'WindowState', 'Maximized', 'DeleteFcn' ); %TO-DO closing callback of fig
g = uigridlayout( f, [5 3] );
g.RowHeight =   {'1x','1x','1x','1x','1x'};
g.ColumnWidth = {'1x','1x','1x','1x'};
mainAx = uiaxes(g);
mainAx.Layout.Row = [1 4];
mainAx.Layout.Column = [1 3];
rbg = uibuttongroup( g, 'BackgroundColor', repmat(0.5,1,3), 'Units', 'Normalized' );
rbg.Layout.Row = 5;
rbg.Layout.Column = [1 3];
secAx = uiaxes( g, 'Tag', 'secAx' );
secAx.Layout.Row = [1 2];
secAx.Layout.Column = 4;
thrdAx = uiaxes( g );
thrdAx.Layout.Row = [3 4];
thrdAx.Layout.Column = 4;
fb = uibutton(g, "Text","Finish", 'FontWeight', 'bold', 'FontSize', 50,...
    "ButtonPushedFcn", @( src ) finishButtonPushed( mainAx ) );
fb.Layout.Row = 5;
fb.Layout.Column = 4;

% Plot og img in d.
imshow( baseImg, [], 'Parent', secAx );

% Plot img and overlay rois.
imshow( baseImg, [], 'Parent', mainAx );
bROIs = cell( 1, numTurkers );
randomColors = parula( numTurkers );
numPoints = 18; % hardcoded -- probably not a bottleneck unlike the roi
toggles = gobjects( 1, numTurkers );
for i = 1:numTurkers
    % % Find boundaries using bwboundaries
    bndry = bwboundaries( individualBWs( :, :, i ) );
    bxy = interparc( numPoints, bndry{ 1 }( :, 2 ), bndry{ 1 }( :, 1 ) );
    val = ['Turker_',num2str( i )];
    icolor = randomColors( i, : );
    bROIs{i} = images.roi.Polyline( mainAx, 'Position', bxy,...
        'Color', randomColors( i, : ), 'Tag', num2str( i ),...
        'Label', val, 'LabelTextColor', 'k', 'LabelVisible', 'hover' );
    addlistener( bROIs{i}, 'DeletingROI', @roiDeletedCallback );
    toggles( i ) = uiswitch( rbg, 'slider', 'Value', val, 'UserData', bROIs{ i },...
        'FontColor', icolor, 'FontSize', 15, 'FontWeight', 'bold',...
        'Items', { val, 'Off'},...
        'ValueChangedFcn',@switchMoved );
end

% Arrange buttons into 8 columns (empirical).
pos = repmat( [0 0 45 20], numTurkers, 1 );
numCols = 8;
numRows = ceil( numTurkers / numCols );
width = 45;
maxX = 1325 - width;
maxY = 150;
xSpacing = linspace( 70, maxX - width, numCols );
ySpacing = linspace( 20, maxY, numRows );
[X,Y] = meshgrid( xSpacing, ySpacing );
pos( 1:numTurkers, 1 ) = X( 1:numTurkers );
pos( 1:numTurkers, 2 ) = Y( 1:numTurkers );
for i = 1:numTurkers; toggles( i ).set( 'Position', pos( i, : ) ); end
hold( mainAx );
L = legend( mainAx );

% Plot current staple as a line plot.
stapleBnd = bwboundaries( stapledBW );
bxy = interparc( 100, stapleBnd{ 1 }( :, 2 ), stapleBnd{ 1 }( :, 1 ) );
stPlt = plot( bxy( :, 1 ), bxy( :, 2 ), 'r.-', 'Parent', mainAx,...
    'LineWidth', 4, 'LineStyle', '--', 'Tag', 'Current' );
L.set( 'String', 'Stapled Result', 'FontSize', 15, 'FontWeight', 'Bold', 'Location', 'south' );

% Update plot in secondary axis.
hold( secAx );
stPlt2 = copyobj( stPlt, secAx );
stPlt2.set( 'LineWidth', 2, 'LineStyle', ':', 'Color', [1 0 0 0.5] );
currentStp2 = copyobj( stPlt2, secAx );
currentStp2.set( 'LineWidth', 3.5, 'LineStyle', '-', 'Color', [1 0 0 1], 'Tag', 'Original' );
L2 = legend( secAx );
L2.String = {'Original', 'Current'};
imshow( baseImg, [], 'Parent', thrdAx );

% Insert output variables into userdata for callback reference.
maxPossibleCombos = factorial( numTurkers ) / (2 * factorial( numTurkers - 2));
dataStruct = struct( 'States', {cell( maxPossibleCombos, 3 )},... % i:{Indices, weights, dice}
    'StaplePlot', stPlt,'CurrentWeights', stapledBW, 'indices', indices, 'Thresh', T );
mainAx.set( 'UserData', dataStruct );
end


function updateROI( src, eventData )
% Index to polyline object
mainAx = src.Parent.Parent.Children(1);
mainAxChildren = mainAx.Children;
allROIs = findobj( mainAxChildren, 'Type', 'images.roi.polyline' );
% ipolyObj = allROIs == src.UserData;
ipolyObj = strcmpi( allROIs.get( 'Visible' ), 'off' );
ind = find( ipolyObj );

% Find secondary axis handle.
secAx = findobj( mainAx.Parent.Children, 'Tag', 'secAx' );
currentStaplePlt = findobj( secAx.Children, 'Tag', 'Current' );

% Update flagged indices.
mainAx.UserData.indices( ipolyObj ) = 1;

% If state has already existed, just use that staple & dice.
cm = NDcell2mat( mainAx.UserData.States( :, 1 ) );
if isempty( cm )
    stateAlreadyExists = false;
    iFirstEmpty = 1;
else
    stateAlreadyExists = any( sum( ismember( cm, ipolyObj ), 2 ) );
    iFirstEmpty = find( sum( ~isnan( cm ), 2 ), 1 );
end
stateAlreadyExists = false;%**********
if stateAlreadyExists
    bxy = mainAx.UserData.States{ iFirstEmpty, 2 };
    mainAx.UserData.StaplePlot.set( 'XData', bxy( :, 1 ), 'YData', bxy( :, 2 ) );
    currentStaplePlt.set( 'XData', bxy( :, 1 ), 'YData', bxy( :, 2 ) );
    % to-do: Show dice?
else
    % Recompute staple on new state without flagged indices.
    srcImg = mainAxChildren( end );
    [m, n] = size( srcImg.CData );
    iTurkers = find( ~ipolyObj );
    numTurkers = numel( iTurkers );
    unrolledBWs = zeros( m*n, numTurkers );
    for i = 1:numTurkers
        [x, y] = deal( allROIs( iTurkers( i ) ).Position( :, 1 ),...
            allROIs( iTurkers( i ) ).Position( :, 2 ) );
        bw = poly2mask( x, y, m, n );
        unrolledBWs( :, i ) = bw( : );
    end
    W = STAPLE( unrolledBWs );
    WT = reshape( W >= mainAx.UserData.Thresh, [m n] );
    mainAx.UserData.CurrentWeights = WT;
    stapleBnd = bwboundaries( mainAx.UserData.CurrentWeights );
    bxy = interparc( 100, stapleBnd{ 1 }( :, 2 ), stapleBnd{ 1 }( :, 1 ) );
    mainAx.UserData.StaplePlot.set( 'XData', bxy( :, 1 ), 'YData', bxy( :, 2 ) );
    currentStaplePlt.set( 'XData', bxy( :, 1 ), 'YData', bxy( :, 2 ) );
    
    % Store state.
    mainAx.UserData.States( iFirstEmpty, : ) = { ind, bxy, WT };
end

end
% function roiDeletedCallbackOld( src, eventData )
% % Identify indice of individual contribution to be removed.
% ax = src.Parent;
% otherROIs = findobj( ax.Children, 'Type', 'images.roi.polyline' );
% otherROIs( otherROIs == src ) = [];
% srcImg = findobj( ax.Children, 'Type', 'Image' );
% ind = str2double( src.get( 'Tag' ) );
% ax.UserData.indices( ind ) = true;
% 
% % Recompute staple and update relevant plot.
% [m, n] = size( srcImg.CData );
% iTurkers = find( ~ax.UserData.indices );
% numTurkers = numel( iTurkers );
% unrolledBWs = zeros( m*n, numTurkers );
% for i = 1:numTurkers
%     [x, y] = deal( otherROIs( i ).Position( :, 1 ), otherROIs( i ).Position( :, 2 ) );
%     bw = poly2mask( x, y, m, n );
%     unrolledBWs( :, i ) = bw( : );
% end
% W = STAPLE( unrolledBWs );
% stapleBnd = bwboundaries( reshape( W >= ax.UserData.Thresh, [m n] ) );
% bxy = interparc( 100, stapleBnd{ 1 }( :, 2 ), stapleBnd{ 1 }( :, 1 ) );
% ax.UserData.Staple.set( 'XData', bxy( :, 1 ), 'YData', bxy( :, 2 ) );
% delete( src );
% end

function switchMoved( src, eventData )
switch src.get( 'Value' )
    case 'Off'
        src.UserData.set( 'Visible', 'off' );
    otherwise
        src.UserData.set( 'Visible', 'on' );
end
updateROI( src, eventData );
end

function finishButtonPushed( ax )

end