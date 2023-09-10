/*
 * QISHA_GenROIs.ijm
 * Created by JFranco, 10 SEP 2023
 * 
 * This script reads in a "Flows" image generated with QISHA_Segment.ipynb 
 * and processes it to create an ROI set for downstream analysis.
 */

/* 
 ************************** QISHA_GenROIs.ijm ******************************
 */

// Housekeeping: Close irrelevant images that might be open
run("Close All");	
 
// Parameters for analysis
minSize = 1500;				// Minimum area of an ROI to include in analysis (based on a 1024x1024 image at 40x--get the NA)
maxSize = 15000;
minCirc = 0.65;				// Minimum circularity to include in analysis 
 
// *** SELECT FILE TO PROCESS *** 
Dialog.create("Welcome");
Dialog.addMessage("Welcome to QISHA_GenROIs.ijm\nSelect the Flow image to process.");
Dialog.show();
impath = File.openDialog("Choose image to open");    	// Ask user to find file 
open(impath);											// Open the image	

// *** SETUP FILE AND DIRECTORY INFO BASED ON IMAGE *** 
self = getInfo("image.filename");
fnBase = substring(self,0,lastIndexOf(self,".Flows"));
selfDir = getInfo("image.directory");
parent = substring(selfDir, 0,lastIndexOf(selfDir, "Flows"));
dirROIs = parent+"ROIs/";
dirRIms = dirROIs+"Images/";
dirRZps = dirROIs+"ROIZips/";

// Setup directory for saving the seed images if it doesn't already exist
if(File.exists(dirROIs)==0){
	File.makeDirectory(dirROIs);
	File.makeDirectory(dirRIms);
	File.makeDirectory(dirRZps);
}

// *** GEN ROIS *** 
// Process the image & gen ROIs using size and circularity inclusion parameters
selectImage(self);
run("8-bit");
run("Enhance Contrast", "saturated=0.35");
run("Apply LUT");
run("Convert to Mask");
run("Erode");
run("Fill Holes");
run("Watershed");
run("Analyze Particles...", "size="+minSize+"-Infinity circularity="+minCirc+"-1.00 display clear summarize overlay add");
saveAs("PNG", dirRIms+fnBase+".ROIs.png");
roiManager("Save", dirRZps+fnBase+".ROIs.zip");

exit;