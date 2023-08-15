/*
 * QISHA_GenSeedImage.ijm
 * Created by JFranco, 14 AUG 2023
 * 
 * The purpose of this ImageJ code is to generate a seed image that will be used by
 * Cellpose to segment the original image into regions of interest (ROIs). 
 * In order for Cellpose to achive optimal results, and for the segmentation to be 
 * based off of the most accurate seed image possible, this semi-automated code
 * asks the user to verify the seed image before completion.  
 * 
 * REQUIRES: 
 * 		- Images to be analyzed must be stored in an experiment specific directory
 *      	within a subfolder titled, "RawImageFiles."
 * 			Example:/Users/Myname/Myfolder/Data/QIA_001/RawImageFiles/QIA_001.01.01.01.Zs.4C.czi
 * 			Where RawImageFiles/ will contain one or more imagefiles to be processed.
 * 		- Channel used for segmentation must be the same for all images in the experiment
 * 		
 * IDEALLY: The RawImageFiles subdirectory will be stored within a folder named after the experimentID		
 * as shown above. 
 * * Note * At the time of initial writing, this code is made for working with .czi files.
 * Other file formats will require independent testing.
 */

/* 
 ************************** MACRO QISHA_GenSeedImage.ijm ******************************
 */
 
// *** SELECT FILE TO PROCESS *** 
// Housekeeping: Close irrelevant images that might be open
run("Close All");	

// *** GET USER CHOICE ***

// Ask the user if they want to run in batch mode or if they want to open a 
// . single image. Batch mode will mean iterating through all of the files in a foler. 
// . Single file mode will mean allowing the user to choose a single file to open
Dialog.create("Welcome to QISHA_GenSeedImage.ijm");
Dialog.addMessage("This macro open your Zstacks and generate seed images for segmentation with Cellpose.");
Dialog.addChoice("Do you want to open a single file or run batch mode for multiple files?", Array.concat("Single File", "Batch Mode"));
Dialog.addString("ExperimentNo", "QIA_###", 7);
Dialog.addNumber("Segmentation Channel", 1);
Dialog.addNumber("Starting Slice for Substack", 1);
Dialog.addNumber("Ending Slice for Substack", 20);
Dialog.show();
choiceRun = Dialog.getChoice();
expID = Dialog.getString();
ch = Dialog.getNumber();
ss = Dialog.getNumber();
fs = Dialog.getNumber();

// Set iteration number based on the user choice for run mode
if (choiceRun == "Single File"){
	iterate = 1;
}else {
	iterate = 2;
} 

init = 0; 	 // Variable used for tracking loop iteration 
// If Iteration number is greater than 1, continue asking the user to open a new file  
// Settting the truth test to 2 ensures the loop will run at least once regardless of choice.
while (iterate > 0) {
	// Kick off - Ask the user to choose the file and begin process
	Dialog.create("Choose file to process");
	Dialog.addMessage("Please select the image to process on the following screen.\n"+
					  "Make sure to unselect all boxes and use default settings.\n"+
					  "Select cancel to exit.");
	Dialog.show();
	run("Bio-Formats Importer");
	self = getInfo("image.filename");
	selfDir =getInfo("image.directory");
	parent = substring(selfDir, 0,lastIndexOf(selfDir, "RawImageFiles"));
	dirSI = parent+"SeedImages/";
	
	// Setup directory for saving the seed images if it doesn't already exist
	if(File.exists(dirSI)==0){
		File.makeDirectory(dirSI);
	}
	
	// Begin processing
	getDimensions(width, height, channels, slices, frames);
	run("Make Substack...", "channels="+ch+" slices="+ss+"-"+fs);
	close("\\Others");
	run("Z Project...", "projection=[Sum Slices]");
	run("Smooth");
	run("Despeckle");
	run("Gaussian Blur...", "sigma=2");
	
	// Save the seedimage
	saveAs("PNG", dirSI+self+".SI.png");
	close();
	
	// Be sure to close open images before proceeding to the next one
	run("Close All");	
	
	// Wrap things up
	//dirMain = ;
	if (iterate == 1){
		exit;
	} 
	iterate = iterate+1;
	// Engineering a safety for the while loop so that it exits automatically after 20 runs. 
	if (iterate == 20){
		iterate = 0;
	}
}