function success = convertResultsCsvToTabDelimited(inputFilePath, outputFilePath)

% Check I/O.
narginchk( 2, 2 );
nargoutchk( 0, 1 );

% Read the raw text data
try
    rawText = fileread(inputFilePath);

    % Replace commas with tabs before opening parentheses
    modifiedText = regexprep(rawText, ',"', '\t"');

    % Write the modified text to a new file
    fid = fopen(outputFilePath, 'w');
    fprintf(fid, '%s', modifiedText);
    fclose(fid);
    success = true;
catch
    success = false;
end
end
