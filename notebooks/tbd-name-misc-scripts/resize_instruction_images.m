%% Change the following 4 lines accordingly:
gifD = 'C:\Users\dmattioli\Projects\MTurk_Semantic_Segmentation\docs\instruction_images\lateral-PSHF\gif_source_images';
d = fullfile( gifD, 'example-real_lat2' );
targetSize = 4.*[512 512]
% targetSize = [1875 1532]


%% Shouldn't need to change anything in this section:
[pn,folderName] = fileparts( d );
targetWrite2D = strcat( folderName, '-resized' );
targetFFN = fullfile( gifD, targetWrite2D );
if ~isfolder( targetFFN )
    mkdir( targetFFN )
end
dd = dir(d);
ffn = transpose(fullfile( d, {dd.name} ) );
ffn(1:2) = [];
numImgs = numel( ffn );
for idx = 1:numImgs
    i=imread(ffn{idx});
    [~,fn,ex]=fileparts(ffn{idx});
    imwrite(imresize(i, targetSize), fullfile( targetFFN, [fn, ex]));
end

