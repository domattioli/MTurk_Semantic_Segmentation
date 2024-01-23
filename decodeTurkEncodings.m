function [success, img, ffn, fid] = decodeTurkEncodings( bitEncodingChar )
%DECODETURKENCODINGS Decode encoded image data sent by Amazon MTurk
%   [success, img, ffn] = DECODETURKENCODINGS( bitEncoding ) for a char
%   'bitEncoding' representing the basecode64 bit encoding of an image
%   formatted by Amazon's MTurk returns the binary logical 'success' to
%   indicate the exit condition of this function, a double matrix 'img'
%   representing the decoded image, and a string 'ffn' pointing to the full
%   filename used to temporarily write and read the encoding as an image.
%   
%   Note: the written image will be deleted at the end of the protocol.
%   
%   See also: DECODEBATCHRESULTS
%==========================================================================

% Check I/O.
narginchk( 1, 1 );
nargoutchk( 0, 4 );
if iscell( bitEncodingChar )
    warning( 'Input was expected to be a char but received a cell; converting to a char...' );
    bitEncodingChar = bitEncodingChar{ 1 };
end

% Current protocol: write encoding to temp file, then read it into memory.
try
    ffn = tempname; % temporary (full) filepath for img.
    [fid, msg] = fopen( ffn, 'w' );
    decodedBytes = typecast( matlab.net.base64decode( bitEncodingChar ), 'uint8' );
    fwrite( fid, decodedBytes, 'uint8');
    img = bwareafilt( logical( imread( ffn ) ), 1 );
    fclose( fid );
    delete( ffn );
    success = true;
catch
    success = false;
    img = [];
    ffn = [];
    warning( ['Something failed while attempting to decode turk encoding; here is the fopen msg:\n ', msg] )
    fclose( fid );
end