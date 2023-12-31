/*
 * QISHA_ROIPunctaCounter.ijm
 * Created by JFranco, 10 SEP 2023
 * 
 * This .ijm code is the fourth module in the QISHA pipeline. It uses an ROI zip file
 * to identify single "cells" (i.e., ROIs) within a max projection image and counts
 * the puncta for that specific ROI. The data is stored in the Results table and exported
 * as a .csv for downstream analysis. 
 * 
 * Suggestions for future parameter tuning:
 * - Can add a wait prompt in the middle of the for loop and manually check the performance of findmaxima
 *   I tested the threshold for a few images and ROIs but may not be perfect
 * - Algo may benefit from tuning sigma for Gaussian filter  
 */

/* 
 ************************** QISHA_ROIPunctaCounter.ijm ******************************
 */



// *** SETUP *** 
// Housekeeping: Close irrelevant images that might be open
run("Close All");
roiManager("delete");
run("Clear Results");
run("Set Measurements...", "area mean standard min redirect=None decimal=3");
// Specify which channels in the stack to analyze 
chnsAna = Array.concat("0");
// Specify which channels to exclude from process
chnsEx = Array.concat("1","2","3");
// Minimum prominence for maxima detection
minProm = 2000;
// Specify rolling ball radius for background subtration
rolling = 8;
// Sigma for Gaussian Filter for reducing false positives due to inclusion bodies
sigma = 2;
// Substack range MUST be the same as what was used in GenSeedImage.ijm
// Specify which slices to use
ssSt = 1;
ssEnd = 20

// *** SELECT FILE TO PROCESS *** 
Dialog.create("Choose file to process");
Dialog.addMessage("Please select the Z-stack to analyze on the following screen.\n"+
				  "For BioFormats Importer, 'Split Channels' should be the only checked box.\n"+
				  "and all default settings should be used (i.e., do NOT autoscale). "+
				  "Select cancel to exit.");
Dialog.show();
run("Bio-Formats Importer");
// Get info about the image and setup necessary directories
self = getInfo("image.filename");
// fnBase here is specific to JF's filenaming system. Adjust or comment out if not applicable.
fnBase = substring(self,0,lastIndexOf(self,".01.40x."));
// Existing directories
selfDir =getInfo("image.directory");
parent = substring(selfDir, 0,lastIndexOf(selfDir, "RawImageFiles"));
dirROIs = parent+"ROIs/ROIZips/";
// Ones to make 
dirRP = parent+"ROIPuncta/";
dirPI = dirRP+"AnalyzedImages/";
dirPC = dirRP+"PunctaCounts/";

// Load the ROIs
roiManager("reset");
roiManager("Open", dirROIs+fnBase+".ROIs.zip");

// Setup directory for saving the seed images if it doesn't already exist
if(File.exists(dirRP)==0){
	File.makeDirectory(dirRP);
	File.makeDirectory(dirPI);
	File.makeDirectory(dirPC);
}

// Iterate through exlcuded channels and close
for (i = 0; i < lengthOf(chnsEx); i++) {
	selectWindow(self+" - C="+toString(chnsEx[i]));
	close();
}

// Preprocess & save analyzed image for documentation purposes
run("Make Substack...", "slices="+ssSt+"-"+ssEnd);
run("Z Project...", "projection=[Max Intensity]");
run("Bin...", "x=2 y=2 bin=Average");
run("Subtract Background...", "rolling="+rolling);
run("Gaussian Blur...", "sigma="+sigma);
saveAs("PNG", dirPI+fnBase+".AnalyzedImage.png");
close("\\Others");

// Load the ROIs and adjust
roiManager("Open", dirROIs+fnBase+".ROIs.zip");

// Beging counting maxima
n = roiManager('count');
for (i = 0; i < n; i++) {
    roiManager('select', i);
    run("Translate... ", "x=-5 y=-20");
    run("Find Maxima...", "prominence="+minProm+" strict output=Count");
    row = getValue("results.count")-1;
    setResult("ImageName", row, fnBase);
    setResult("ROI_ID", row, toString(i+1));
    
    // Get & store statistics on pixel distributions
    getStatistics(area, mean, min, max, std, histogram);
    setResult("Area", row, area);
    setResult("Mean", row, mean);
    setResult("Min", row, min);
    setResult("Max", row, max);
    setResult("Std", row, std);
    
}

// Save results on each run in case macro crashes
selectWindow("Results");
saveAs("Results", dirPC+fnBase+".PunctaCounts.csv");

// Tell the user to take a screenshot of the image with ROIs overlaid
// . There should be a better way to do this but I can't find it right now.
waitForUser("Take a screenshot of the ROIs over the puncta image then add to ROIPuncta Images folder.");
exit;
