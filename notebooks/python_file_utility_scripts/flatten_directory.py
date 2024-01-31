# Takes a chosen folder with subfolders and puts all files (non-directories)
# into one chosen output directory with all files at one base level (with no subfolders)
# Useful when you have a folder full of cases and you want to pull all of the DICOMs/PNGs into
# one folder.
from os import path, walk
from tkinter.filedialog import askdirectory
from shutil import copyfile

scriptDir = path.dirname(path.abspath(__file__))

# Prompt user for parent folder
inFold = askdirectory(
    title="Select the folder with subfolders containing you would like to put into one folder:",
    initialdir=scriptDir,
)
if inFold == "":
    print("No data folder selected. Exiting...")
    exit()
inFold = path.abspath(inFold)

# Prompt user for output folder
outFold = askdirectory(
    title="Select the output folder for all found files:",
    initialdir=scriptDir,
)
if outFold == "":
    print("No output folder selected. Exiting...")
    exit()
outFold = path.abspath(outFold)

# Copy files from data folder to output folder at single directory level
numOps = 0
for fullDir, dirs, files in walk(inFold):
    for file in files:
        try:
            copyfile(path.join(fullDir,file), path.join(outFold,file))
            numOps += 1
        except:
            print("Failed to copy " + path.join(fullDir,file) + " to " + path.join(outFold,file))

print("Done. Successfully copied " + str(numOps) + " files to " + outFold)
