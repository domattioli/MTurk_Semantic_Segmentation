function turkerTable = aggregateIndividualTurkerData( resultTable )
%AGGREGATEINDIVIDUALTURKERDATA Reorganize result table by individual turker
%   turkerTable = aggregateIndividualTurkerData( resultTable ) returns a
%   table whos rows correspond to the unique individual contributions of
%   each turker who completed a HIT. The turkerTable is just a
%   re-representation of the inputted resultTable.
%   
%   Note: this function assumes that all images are of the same size!
%   Note2: this was designed with the intention of simplifying an analysis
%   on individual turker accuracy and for determining the min # of turkers
%   needed to approximate a larger group.
%   
%   See also: DECODEBATCHRESULTS, turkerAccuracyMonteCarloAnalysisRoutine.
%==========================================================================

% Input check.
narginchk( 1, 1 );
numResults = height( resultTable );
if numResults == 0
    warning( 'Inputted result table has no rows -- function exiting.' );
    turkerTable = [];
    return
end
nargoutchk( 0, 1 );

% Gather unique of all contributing turkers in resultTable.
allIDs = vertcat( resultTable.TurkerData(:).IDs );
uniqueIDs = unique( allIDs );

% Query resultTable for each unique turker ID.
numRows = numel( uniqueIDs );
varNames = { 'resultTableIdxs', 'Grades', 'Decodings'};
varTypes = { 'logical', 'cell', 'cell' };
turkerTable = table( 'Size', horzcat( numRows, numel( varTypes ) ),...
    'RowNames', uniqueIDs, 'VariableNames', varNames, 'VariableTypes', varTypes );
turkerTable.resultTableIdxs = false( numRows, numResults );
numPixPerImg = size( resultTable.TurkerData( 1 ).Decodings, 1 );
turkerGradeSubTableVarNames = resultTable.TurkerData( 1 ).Grades.Properties.VariableNames;
for idx = 1:numRows
    turkerID = uniqueIDs{ idx };
    gradesTmp = nan( numResults, 3 );
    decodingsTmp = false( numPixPerImg, numResults );
    for jdx = 1:numResults
        iTurker = contains( resultTable.TurkerData( jdx ).IDs, turkerID );
        if ~any( iTurker )
            continue
        end
        turkerTable.resultTableIdxs( idx, jdx ) = true;
        gradesTmp( jdx, : ) = table2array( resultTable.TurkerData( jdx ).Grades( turkerID, : ) );
        decodingsTmp( :, jdx ) =  resultTable.TurkerData( jdx ).Decodings( :, iTurker );
    end
    
    % Create local grades table from array.
    iHIT = turkerTable.resultTableIdxs( idx, : );
    turkerTable.Grades{ idx } = array2table( gradesTmp( iHIT, : ) );
    turkerTable.Grades{ idx }.Properties.VariableNames = turkerGradeSubTableVarNames;
    turkerTable.Grades{ idx }.Properties.RowNames = resultTable.Properties.RowNames( turkerTable.resultTableIdxs( idx, : ) );

    % Retrieve decodings but keep them unrolled.
    turkerTable.Decodings{ idx } = decodingsTmp( :, iHIT );
end


