# Copies files from one folder (fullFold) to another (outFold) that have extensionless basenames matching those
# in a list of files in a third folder (subsetFold)
from os import path
import os
from tkinter.filedialog import askdirectory
from tkinter import messagebox
from shutil import copyfile

scriptDir = path.dirname(path.abspath(__file__))

# Start by prompting user to select folder with full set of data from which to copy a subset of files
fullFold = askdirectory(
    title="Select the folder with the full set of data from which to copy:",
    initialdir=scriptDir,
)
if fullFold == "":
    print("No data folder selected. Exiting...")
    exit()
fullFold = path.abspath(fullFold)

# shows dialog box and return the path


# Compile filenames in chosen folder to list
# fullFiles = os.listdir(fullFold)
fullFiles = list()
for fullDir, dirs, files in os.walk(fullFold):
    for file in files:
        fullFiles.append(path.abspath(path.join(fullDir, path.basename(file))))
print("Data folder: " + fullFold + " (" + str(len(fullFiles)) + " files)")

# Prompt user for second folder with subset of first folder's filenames
subsetFold = askdirectory(
    title="Select the folder with the subset of similar file basenames that you would like to pull from the first folder:",
    initialdir=scriptDir,
)
if subsetFold == "":
    print("No basename folder selected. Exiting...")
    exit()
subsetFold = path.abspath(subsetFold)

# Combine basenames (less extensions) of files to copy to a list
basenames = list()
for fullDir, dirs, files in os.walk(subsetFold):
    for file in files:
        basenames.append(path.splitext(file)[0])

print("Basename folder: " + subsetFold + " (" + str(len(basenames)) + " files)")

# Find the similar basenames
matchedFiles = list()
for srcFile in fullFiles:
    srcBaseNoExt = path.splitext(path.basename(srcFile))[0]
    if srcBaseNoExt in basenames:
        matchedFiles.append(srcFile)

if len(matchedFiles) == 0:
    print(
        "No names matched. Check your folders and try again, or debug the script. Exiting..."
    )
    exit()

skipMatches = messagebox.askquestion(
    "Skip Matches", "Do you want to skip right to copying non-matches?"
)

numCopyOps = 0

if skipMatches == "no":
    # Prompt user for third folder for where to copy files to
    outFold = askdirectory(
        title="Select the folder you would like the "
        + str(len(matchedFiles))
        + " matched files to be copied to.",
        initialdir=scriptDir,
    )
    if outFold == "":
        print("No output folder selected. Exiting...")
        exit()
    outFold = path.abspath(outFold)

    print("Output folder: " + outFold)
    if len(os.listdir(outFold)) != 0:
        yesNoResponse = messagebox.askquestion(
            "Existing files! Continue?",
            "There are "
            + str(len(os.listdir(outFold)))
            + " files in the selected output folder! Continue? (Existing files will NOT get deleted, but similar filenames WILL get OVERWRITTEN!)",
        )
        if not yesNoResponse == "yes":
            print("Did not respond 'Yes' to Existing Files prompt: Exiting...")
            exit()

    # Copy the similar files from first directory to third directory
    for fname in matchedFiles:
        try:
            copyfile(fname, path.join(outFold, os.path.basename(fname)))
            numCopyOps += 1
        except:
            print("Copy operation failed for " + fname)

    if numCopyOps == 0:
        print("All copy operations failed! Stop to debug! Exiting...")
        exit()
    print(
        "Successfully copied "
        + str(numCopyOps)
        + ' files from "'
        + str(fullFold)
        + '" ('
        + str(len(fullFiles))
        + " files) to "
        + outFold
        + " matching "
        + str(len(matchedFiles))
        + " of "
        + str(len(basenames))
        + " input names"
    )
    if not numCopyOps == len(matchedFiles):
        print(
            str(len(matchedFiles) - numCopyOps)
            + " failed to copy -- check the terminal!"
        )

if (not len(matchedFiles) == len(fullFiles)) or (
    skipMatches and not len(matchedFiles) == len(fullFiles)
):
    yesNoResponse2 = ""
    if skipMatches == "no":
        yesNoResponse2 = messagebox.askquestion(
            "Copy Files Without Match",
            "Would you like to copy "
            + str(len(fullFiles) - len(matchedFiles))
            + " files that were not in the subset to a separate directory? "
            + "This includes all files that were in the originally specified "
            + "directory but that weren't found in the subset folder.",
        )
    if yesNoResponse2 != "no":
        nonMatchFold = askdirectory(
            title="Select folder to which to copy files that did not match the sublist",
            initialdir=scriptDir,
        )
        if len(os.listdir(nonMatchFold)) != 0:
            yesNoResponse3 = messagebox.askquestion(
                "Existing files! Continue?",
                "There are "
                + str(len(os.listdir(nonMatchFold)))
                + " files in the selected output folder! Continue? (Existing files will NOT get deleted, but similar filenames WILL get OVERWRITTEN!)",
            )
            if not yesNoResponse3 == "yes":
                print(
                    "Did not respond 'Yes' to Existing Files prompt for dissimilar files: Exiting..."
                )
                exit()

        print("Writing dissimilar files...")

        # Find the dissimilar basenames
        nonMatchNames = list()
        for srcFile in fullFiles:
            srcBaseNoExt = path.splitext(path.basename(srcFile))[0]
            if srcBaseNoExt not in basenames:
                nonMatchNames.append(srcFile)

        # Copy dissimilar files from first directory to fourth (just specified) directory
        numCopyOps2 = 0
        for fname in nonMatchNames:
            try:
                copyfile(fname, os.path.join(nonMatchFold, os.path.basename(fname)))
                numCopyOps2 += 1
            except:
                print("Copy operation failed for " + fname)
        print(
            "Successfully copied "
            + str(numCopyOps2)
            + ' files from "'
            + str(fullFold)
            + '" ('
            + str(len(fullFiles))
            + " files) to "
            + nonMatchFold
            + " matching "
            + str(len(nonMatchNames))
            + " of "
            + str(len(fullFiles) - numCopyOps)
            + " originally unmatching input names"
        )
