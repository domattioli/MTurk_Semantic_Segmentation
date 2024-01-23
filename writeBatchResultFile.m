function success = writeBatchResultFile( resultTable, thresh, resultFFN )
%WRITEBATCHRESULTFILE Write result table as .mat file in batch directory.
%   success = WRITEBATCHRESULTFILE( resultTable, thresh, resultFFN ) returns binary
%   'success' to indicate a successful writing of the resultTable variable
%   as a .mat file to the path of the batch result file 'resultFFN'.
%   
%   See also: DECODEBATCHRESULTS, WRITEINPUTCSV, VISUALIZERESULTS.
%==========================================================================

% Check I/O.
narginchk( 2, 3 ); % Revised to require thresh to be inputted so we can write a more descript fn.
nargoutchk( 0, 1 );

% TODO - revise this to be a more specific function than just bootstrapping
% the 'save' function.
[pn, fn] = fileparts( resultFFN );
tn = num2str( thresh );
saveFFN = fullfile( pn, strcat( fn, '-graded-Thresh_', tn(3:end), '.mat' ) );
try
    save( saveFFN, 'resultTable' );
    success = true;
catch
    success = false;
    warning( 'Save failed' );
end