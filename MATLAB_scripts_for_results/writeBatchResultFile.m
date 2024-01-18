function success = writeBatchResultFile( resultTable, resultFFN )
%WRITEBATCHRESULTFILE Write result table as .mat file in batch directory.
%   success = WRITEBATCHRESULTFILE( resultTable, resultFFN ) returns binary
%   'success' to indicate a successful writing of the resultTable variable
%   as a .mat file to the path of the batch result file 'resultFFN'.
%   
%   See also: DECODEBATCHRESULTS, WRITEINPUTCSV, VISUALIZERESULTS.
%==========================================================================

narginchk( 1, 2 );
nargoutchk( 0, 1 );

% TODO - revise this to be a more specific function than just bootstrapping
% the 'save' function.
[pn, fn] = fileparts( resultFFN );
saveFFN = fullfile( pn, strcat( fn, '-graded.mat' ) );
try
    save( saveFFN, 'resultTable' );
    success = true;
catch
    success = false;
    warning( 'Save failed' );
end