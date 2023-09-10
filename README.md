# QISHA
Quantitative In Situ Hybridization Analysis
Author: Joy Franco

This repository is for a collection of tools meant to assist with quantifying in situ hybridization data. The tools are a combination of Python and ImageJ code. They are listed below in the order that they should be run. 

Important Notes:
- Cellpose can take a long time to run depending on the seed image and the hardware used.
- Cellpose does better with smaller size images. This is why images are downsampled before segmentation.

Requires:
- Code is written for images acquired as 2048x2048 that will be binned during processing.

Workflow:
1. QISHA_GenSeedImage.ijm - This ImageJ code reads in a confocal stack using BioFormats importer and generates a seed image to be use for segmentation.

2. QISHA_Segment.ipynb - This Python notebooks segments the seed images from step #1 and generates a collection of files to document the identified masks. This includes a "Flows" image that will be read by QISHA_GenROIs.ijm

3. QISHA_GenROIS.ijm - This ImageJ code processes the Flows image and generates a list of acceptable ROIs that are saved as a .zip file for use in downstream analysis. It also saves an image of the identified ROIs. 