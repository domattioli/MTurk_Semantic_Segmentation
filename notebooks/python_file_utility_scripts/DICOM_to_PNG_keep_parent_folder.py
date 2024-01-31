# Opens a file explorer dialog for you to choose a folder containing subfolders (one level down)
# with DICOMs (at any level in that subfolder), converts the DICOMs to PNGs, and copies the PNGs
# to a selected directory with the same subfolder names
# Ignores files not in a subdirectory in the input folder
# Useful when you have a directory full of cases that have DICOMs but the DICOMs are not
# at a single file level
from os import path
import os
from tkinter.filedialog import askdirectory
from tkinter import messagebox
from shutil import copyfile
from pydicom import dcmread
from PIL import Image
import numpy as np

scriptDir = path.dirname(path.abspath(__file__))

# Start by prompting user to select folder with subfolders
inFold = askdirectory(
    title="Select the folder with subfolders containing DICOMs:",
    initialdir=scriptDir,
)
if inFold == "":
    print("No data folder selected. Exiting...")
    exit()
inFold = path.abspath(inFold)

# Compile subfolder names in chosen folder to list
# fullFiles = os.listdir(inFold)
subFolds = []
for f in os.listdir(inFold):
    if path.isdir(path.join(inFold, f)):
        subFolds.append(f)
# subFolds = list()
# for fullDir, dirs, files in os.dir(inFold):
#     for dir in dirs:
#         subFolds.append(path.abspath(path.join(fullDir, dir)))
# print("Data folder: " + inFold + " (" + str(len(subFolds)) + " subfolders)")

# Prompt user for second folder for PNGs of subfolder DICOMs
outFold = askdirectory(
    title="Select the output folder for the converted PNGs:",
    initialdir=scriptDir,
)
if outFold == "":
    print("No output folder selected. Exiting...")
    exit()
outFold = path.abspath(outFold)

# Go through each subfolder, find DICOMs, convert each to PNG, and put them in a folder in the output folder
numCases = len(subFolds)
totalDcms = 0
totalSuccesses = 0
for subFold in subFolds:
    # Create output folder
    pngFold = path.join(outFold, subFold)
    if not path.exists(pngFold):
        os.mkdir(pngFold)

    print(
        "Converting DICOMs in "
        + path.join(inFold, subFold)
        + " to PNGs and saving in "
        + pngFold
    )
    numDcms = 0
    successes = 0
    for fullDir, dirs, files in os.walk(path.join(inFold, subFold)):
        for file in files:
            # if path.splitext(file)[1] == ".dcm":
            if (
                path.splitext(file)[1] == ".dcm" or path.splitext(file)[1] == ""
            ):  # experiment for extensionless DICOMs
                numDcms += 1
                dcmFname = path.join(fullDir, file)
                pngFname = path.join(
                    pngFold, path.splitext(path.basename(dcmFname))[0] + ".png"
                )

                # Convert dcm to png and save
                try:
                    dcm = dcmread(dcmFname)
                    dImg = dcm.pixel_array.astype(float)
                    dImg_uint16_array = np.uint16(
                        (np.maximum(dImg, 0) / dImg.max()) * 65535.0
                    )
                    dImg_uint16 = Image.fromarray(dImg_uint16_array)

                    dImg_uint16.save(pngFname)
                    successes += 1
                except:
                    print(
                        "Conversion/save operation failed for "
                        + path.join(fullDir, file)
                    )
    print(
        "Successfully converted and saved "
        + str(successes)
        + " PNGs out of "
        + str(numDcms)
        + " DICOMs."
    )
    totalDcms += numDcms
    totalSuccesses += successes

print(
    "Finished. Converted "
    + str(totalSuccesses)
    + " of "
    + str(totalDcms)
    + " DICOMs found to PNGs in total"
)
