# MTurk_Semantic_Segmentation
Pre- and Post-processing image data for MTurk.

## Explanations for current modules:
**Helper functions**
- Custom and open-source matlab functions used to support code in modules.
  
**Module 1. Pre-processing**
- Prepare image data (create list of images, convert to pngs with a defined target size, push images to s3 bucket, generate input.csv).
    
**Module 2. Post-processing**
- Reformat outputted result txt file, decode (from base-64) submitted segmentation data, aggregate submissions via STAPLE algorithm.
  
**Module 3. Analysis**
- Generate images (overlay individual and staple submission onto respective base image).
- Analyze quality/agreement of turkers via dice coefficient.

## Expected directory hierarchies
**Data folder**

The following subdirectory hierarchy represents an example setup for three distinct MTurk jobs:
```
-- MTurk_Semantic_Segmentation/
   |-- data/
       |-- MTurk_Job_Family_Example_1/
           |-- Job_Name_Example_1/
               |-- Batches/
                   |-- YYYY-MM-DD/
                       |-- batch_info_tbd/
                       |-- results/
                       |-- analysis/
                       |-- input.csv
           |-- Job_Name_Example_2/
               |-- Batches/
                   |-- YYYY-MM-DD/
                       |-- batch_info_tbd/
                       |-- results/
                       |-- analysis/
                       |-- input.csv
       |-- MTurk_Job_Family_Example_2/
           |-- Job_Name_Example_3/
               |-- Batches/
                   |-- YYYY-MM-DD/
                       |-- batch_info_tbd/
                       |-- results/
                       |-- analysis/
                       |-- input.csv
```
