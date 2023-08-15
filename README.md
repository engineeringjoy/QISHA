# QISHA
Quantitative In Situ Hybridization Analysis
Author: Joy Franco

This repository is for a collection of tools meant to assist with quantifying in situ hybridization data. The tools are a combination of Python and ImageJ code.

1. QISHA_GenSeedImage.ijm - This ImageJ code reads in a confocal stack using Bioformater and generates a seed image to be use for segmentation.

2. QISHA_GenROIs.ipynb - This Python notebooks sgements the seed images from step #1 and generates an ROI file that can be opened in ImageJ.