function M = NDcell2Mat( C, V )
%NDCELL2MAT Cell2mat for an array-cell structure of any length.
%   M = NDCELL2MAT( C ) converts a unidimensional cell array C with
%   contents of the same data type into a single matrix M. There is no
%   need for the dimensions of the cell's contents to match.
%
%   M = NDCELL2MAT( C, V ) fills in incongruent dimensions specified by V.
%   V must be a numeric value that specified the values that fill in the
%   output M where values did not expist in that dimension of input C.
%   Acceptable inputs for V are: nan, 0, or 1.
%
%   NDCELL2MAT currently only supports numeric data.
%   
%   % Example:  5x1
%   C = { [0]; [1 2 3]; [4; 5]; NaN; [6 7 8 9 10] };
%   M = NDCELL2MAT( C )
%
%   % Example:  3x2x1
%   C = { 0, [1,2,3]; [4;5], NaN; [6,7,8,9], Inf };
%   M = NDCELL2MAT( C, inf )
%
%   % Example:  Random cell input.
%   C = cell( randi( 100, 1, 2 ) );
%   for idx = 1:numel( C )
%       C{ idx } = randi( 100, randi( 100, 1 ) );
%   end
%   M = NDCELL2MAT( C, eps );
%   disp( size( M ) );
%   disp( size( C ) );
%   disp( max( cellfun( @numel, C( : ) ) ) );
%
%   % Example:  Practical application via graph vertices' degree.
%   A = [0 10 20 30; 10 0 2 0; 20 2 0 1; 30 0 1 0];
%   G = graph( A );
%   C = cell( G.numnodes(), 1 );
%   for idx = 1:G.numnodes()
%       C{ idx } = G.neighbors( idx );
%   end
%   M   = NDCELL2MAT( C, randi( 100, 1 ) ) % View all nodes' neighbors at once.
%
%
%   Written by: Dominik Mattioli
%   Functionality revisions suggested by: Stephen Cobeldick
%   (https://www.mathworks.com/matlabcentral/profile/authors/3102170).
%
%   See also cell2mat.
%==========================================================================

% Check input.
narginchk( 1, 2 );
nargoutchk( 0, 1 );
if nargin == 2
    if isstring( V ) || ischar( V )
        warning( ['Inputted filler value ''%s'' detected as string when numeric was expected; ',...
            'output may not be as expected/error may result.'], V );
        if strcmpi( V, 'NaN' ) || strcmpi( V, 'NaNs' )
            V   = NaN;
        elseif strcmpi( V, 'Zero' ) || strcmpi( V, 'Zeros' ) || strcmpi( V, '0' )
            V   = 0;
        elseif strcmpi( V, 'Inf' ) || strcmpi( V, 'Infinity' )
            V   = Inf;
        elseif numel( str2num( V ) ) == 1 %#ok<*ST2NM>
            V   = str2num( V );
        else
            V   = Inf;
        end
    else
        if ~isnumeric( V )
            V   = Inf;
        end
    end
end
assert(all(cell2mat(cellfun(@isnumeric, C(:), 'UniformOutput', false))), ...
    ['Inputted cell array contains elements that are non-numeric.',...
    'Check that C does not contain nested cells or non-numeric data.'] );


% Pre-assign output.
S	= horzcat( size( C ), 1 );
X	= find( S == 1, 1, 'first' );
N	= max( cellfun( @numel, C( : ) ) );
S( X )	= N;
if nargin < 2
    M	= NaN( S );
else
    M	= zeros( S ) + V;
end

% Walk across cells, converting to numeric values.
Y	= num2cell( S );
for k = 1:numel( C )
    [Y{:}]  = ind2sub( size( C ), k );
    Y{ X }	= 1:numel( C{ k } );
    M( Y{ : } ) = C{ k }( : );
end

