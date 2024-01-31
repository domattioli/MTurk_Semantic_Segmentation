function saveFFNs = writeBatchResultFile( resultTable, turkerTable, thresh, resultFFN )
%WRITEBATCHRESULTFILE Write result table as .mat file in batch directory.
%   saveFFNs = WRITEBATCHRESULTFILE( resultTable, thresh, resultFFN )
%   returns the path of the batch result file 'resultFFN', written as a
%   .mat data representation of the inputted resultTable.
%
%   See also: DECODEBATCHRESULTS, WRITEINPUTCSV, VISUALIZERESULTS.
%==========================================================================

% Check I/O.
narginchk( 4, 4 ); % Revised to require thresh to be inputted so we can write a more descript fn.
nargoutchk( 0, 1 );

% TODO - revise this to be a more specific function than just bootstrapping
% the 'save' function.
[pn, fn] = fileparts( resultFFN );
tn = num2str( thresh );
saveFFNs{ 1 } = fullfile( pn, strcat( fn, '-graded-Thresh_', tn(3:end), '.mat' ) );
save( saveFFNs{ 1 }, 'resultTable' );
saveFFNs{ 2 } = fullfile( pn, strcat( fn, '-individualTurkerResults-Thresh_', tn(3:end), '.mat' ) );
save( saveFFNs{ 2 }, 'turkerTable' );

