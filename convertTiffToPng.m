function [success, pngImgs, pngDir] = convertTiffToPng( inDir, targetDim )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% Check I/O.
narginchk( 1, 2 );
nargoutchk( 0, 3 );
assert( isfolder( inDir ), 'The inputted subdirectory does not exist.' );

tiffImagesDir = fullfile( inDir, 'tiff_images' );
if ~isfolder( tiffImagesDir )
    mkdir( tiffImagesDir );
end

if nargin == 1
    targetDim = 512;
end

try
    % Create 'png_images' subdirectory if it doesn't exist
    pngDir = fullfile( inDir, 'png_images' );
    if ~isfolder( pngDir )
        mkdir( pngDir );
    end


    % Convert each TIFF file to PNG and save in 'png_images'
    tiffFiles = dir( fullfile( tiffImagesDir, '*.tiff' ) );
    targetSize = horzcat( targetDim, targetDim, numel( tiffFiles ) );
    pngImgs =  NaN( targetSize );
    for i = 1:length( tiffFiles )
        % Read the TIFF image, convert to PNG.
        tiffFilePath = fullfile(tiffImagesDir, tiffFiles(i).name);
        pngImgs( :, :, i ) = im2double( imresize( imread( tiffFilePath), targetSize( 1:2 ) ) );
        [~, imageName, ~] = fileparts(tiffFiles(i).name);
        pngFilePath = fullfile( pngDir, [imageName, '.png']);
        imwrite( pngImgs( :, :, i ), pngFilePath);
    end

    success = true;
catch
    success = false;
    pngImgs = [];
end