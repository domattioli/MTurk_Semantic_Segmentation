function [success, resultTable] = gradeTurkerSubmissions( resultTable, T )
%GRADETURKERSUBMISSIONS Return metrics for each turker wrt their STAPLE.
%   [success, resultTable] = GRADETURKERSUBMISSIONS( resultTable, T )
%   returns an updated 'resultTable' of height N, where N is the number of
%   images submitted as a batch to MTurk. the inputted 'resultsTable' must
%   contain columns called 'TurkerDecoded', 'Stapled', and 'Grades', and
%   must contain rownames corresponding to the image names sampled for the
%   batch. The 'Stapled' column must be an NxM double array, where M is the
%   number of pixels in the image and is assumed to be the same for all
%   image (targetSize variable in the 'decodeBatchResults' function. The
%   'Grades' column will be updated to be a subtable detailing the
%   Similarity, Sensitivity, and Specificity for each individual turker as
%   a function of their Stapled aggregate prediction.
%   
%   Note: similarity is computed as the dice coefficient.
%   
%   See also: DECODEBATCHRESULTS, STAPLE, DICE.
%==========================================================================

% Check I/O.
narginchk( 1, 2 );
if nargin == 1
    T = 0.95;
end
nargoutchk( 0, 2 );

try
    % Predefine the Grades' variable table.
    gradeVarNames = { 'Similarity', 'Sensitivity', 'Specificity' };
    gradeVarTypes = { 'double', 'double', 'double' };
    numVars = numel( gradeVarNames );

    % Staple the results and grade individuals against it.
    for idx = 1:height( resultTable )
        % Preallocate table.
        numSubmissions  = size( resultTable.TurkerData( idx ).Decodings, 2 );
        resultTable.TurkerData( idx ).Grades = table( 'Size', [numSubmissions, numVars],...
        'VariableNames', gradeVarNames, 'VariableTypes', gradeVarTypes );
        resultTable.TurkerData( idx ).Grades.Properties.RowNames = resultTable.TurkerData( idx ).IDs;
        
        % Compute weights, sensitivities, specificities.
        [W, p, q] = STAPLE( resultTable.TurkerData( idx ).Decodings );
        resultTable.TurkerData( idx ).Weights = W( : );
        resultTable.TurkerData( idx ).Grades.Sensitivity = transpose( p );
        resultTable.TurkerData( idx ).Grades.Specificity = transpose( q );

        % Threshold weights and compute similarities.
        threshedW = resultTable.TurkerData( idx ).Weights >= T;
        while ~any( threshedW )
            disp('hello!')
            newT = T - 0.01;
            threshedW = resultTable.TurkerData( idx ).Weights >= newT;
            warning( ['Needed to reduce thresh by 1% for: ', resultTable.Properties.RowNames{idx} ])
        end
        for jdx = 1:numSubmissions
            resultTable.TurkerData( idx ).Grades.Similarity( jdx ) = dice(...
                threshedW, resultTable.TurkerData( idx ).Decodings( :, jdx ) );
        end
        resultTable.Stapled( idx, : ) = threshedW;
    end
    success = true;
catch
    success = false;
    warning( 'Something failed while attempting to grade the turker submissions.' );
end

