waitfor(warndlg('Select Oirinal Image Folder'));
original_directory = uigetdir([],'Select Original Image Path');

waitfor(warndlg('Select Folder to Save Reformatted Images'));
save_directory = uigetdir([],'Select Save Path');

original_files=dir([original_directory '/*.tiff']);

 for k=1:length(original_files)
    filename=[original_directory '/' original_files(k).name];
    imBuff = imread(filename);
    imBuff_intensity_scaled = im2uint16(imBuff);
    [~,basename,~] = fileparts(original_files(k).name);
    imwrite(imBuff_intensity_scaled,[save_directory '/' basename '.png']);
    %disp('Im Saved')
 end
disp('Done');