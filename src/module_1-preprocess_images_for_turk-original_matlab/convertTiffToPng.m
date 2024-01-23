function [pngImgs, pngDir] = convertTiffToPng( inDir, targetSize )
%CONVERTTIFFTOPNG Convert (write copies of) select png images to tiff format.
%   [pngImgs, pngDir] = convertTiffToPng( inDir, targetSize ) returns an
%   RxCxN image data matrix pngImgs corresponding to the reformatted copies
%   of images specified in the inputted inDdir and the target image
%   dimensions specified by targetSize, which must be [R C].
%
%   Note that the default of targetSize is [512 512].
%
%   See also
%==========================================================================

% Check I/O.
narginchk( 1, 2 );
nargoutchk( 0, 2 );
assert( ischar( inDir ), 'Inputted inDir must be a char.' );
assert( isfolder( inDir ), 'Inputted subdirectory does not exist.' );

tiffImagesDir = fullfile( inDir, 'tiff_images' );
if ~isfolder( tiffImagesDir )
    mkdir( tiffImagesDir );
end

if nargin == 1
    targetSize = 512;
else
    assert( isnumeric( targetSize ) & numel( targetSize ) == 2,...
        'The inputted targetSize must be a numeric verctor of length 2.' );
end


% Create 'png_images' subdirectory if it doesn't exist
pngDir = fullfile( inDir, 'png_images' );
if ~isfolder( pngDir )
    mkdir( pngDir );
end


% Convert each TIFF file to PNG and save in 'png_images'
tiffFiles = dir( fullfile( tiffImagesDir, '*.tiff' ) );
targetSize = horzcat( targetSize, targetSize, numel( tiffFiles ) );
pngImgs =  NaN( targetSize );
for i = 1:length( tiffFiles )
    % Read the TIFF image, convert to PNG.
    tiffFilePath = fullfile(tiffImagesDir, tiffFiles(i).name);
    pngImgs( :, :, i ) = im2double( imresize( imread( tiffFilePath), targetSize( 1:2 ) ) );
    [~, imageName, ~] = fileparts(tiffFiles(i).name);
    pngFilePath = fullfile( pngDir, [imageName, '.png']);
    imwrite( pngImgs( :, :, i ), pngFilePath);
end

