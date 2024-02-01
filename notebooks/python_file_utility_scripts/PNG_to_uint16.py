# Convert folder full of uint24 PNGs to uint16 PNGs
from os import path
import os
from tkinter.filedialog import askdirectory
from tkinter import messagebox
from shutil import copyfile
from pydicom import dcmread
from PIL import Image
import numpy as np

scriptDir = path.dirname(path.abspath(__file__))

# Start by prompting user to select folder with PNGs
inFold = askdirectory(
    title="Select the folder with PNGs with bit depth 24",
    initialdir=scriptDir,
)
if inFold == "":
    print("No data folder selected. Exiting...")
    exit()
inFold = path.abspath(inFold)

# Prompt user for second folder for converted PNGs
outFold = askdirectory(
    title="Select the output folder for the converted uint16 PNGs:",
    initialdir=scriptDir,
)
if outFold == "":
    print("No output folder selected. Exiting...")
    exit()
outFold = path.abspath(outFold)

for f in os.listdir(inFold):
    if path.splitext(f)[1] == ".png":
        png = Image.open(path.join(inFold, f))
        png.load()
        data_uint24 = np.asarray(png)
        data_uint16 = np.uint16(
            (np.maximum(data_uint24, 0) / data_uint24.max()) * 65535.0
        )
        png_uint16 = Image.fromarray(data_uint16, "RGB")
        png_uint16.save(path.join(outFold, f))
