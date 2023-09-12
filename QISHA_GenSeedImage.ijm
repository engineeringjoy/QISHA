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
 ************************** QISHA_GenSeedImage.ijm ******************************
 */
 
// *** SETUP *** 
// Housekeeping: Close irrelevant images that might be open
run("Close All");
// Specify which channels to use for generating the seed image
chnsMP = Array.concat("1","2");
// Specify which channels to exclude from process
chnsEx = Array.concat("0","3");
// Specify which slices to use
ssSt = 1;
ssEnd = 20;
// Specify radius for Gaussian Filter
sigma = 4;

// *** GET USER CHOICE ***
// Ask the user if they want to run in batch mode or if they want to open a 
// . single image. Batch mode will mean iterating through all of the files in a foler. 
// . Single file mode will mean allowing the user to choose a single file to open
Dialog.create("Welcome to QISHA_GenSeedImage.ijm");
Dialog.addMessage("This macro open your Zstacks and generate seed images for segmentation with Cellpose.");
Dialog.addChoice("Do you want to open a single file or run batch mode for multiple files?", Array.concat("Single File", "Batch Mode"));
Dialog.show();
choiceRun = Dialog.getChoice();

// Kick off - Inform the user about setup for BioFormats Importers
Dialog.create("Choose file to process");
Dialog.addMessage("Please select the image to process on the following screen.\n"+
				  "For BioFormats Importer, 'Split Channels' and 'Autoscale' should be the only checked box.\n"+
				  "and all default settings should be used. "+
				  "Select cancel to exit.");
Dialog.show();

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
	// *** SELECT FILE TO PROCESS *** 
	run("Bio-Formats Importer");
	self = getInfo("image.filename");
	// fnBase here is specific to JF's filenaming system. Adjust or comment out if not applicable.
	fnBase = substring(self,0,lastIndexOf(self,".01.40x."));
	selfDir =getInfo("image.directory");
	parent = substring(selfDir, 0,lastIndexOf(selfDir, "RawImageFiles"));
	dirSI = parent+"SeedImages/";
	
	// Setup directory for saving the seed images if it doesn't already exist
	if(File.exists(dirSI)==0){
		File.makeDirectory(dirSI);
	}
	
	// Iterate through exlcuded channels and close
	for (i = 0; i < lengthOf(chnsEx); i++) {
		selectWindow(self+" - C="+toString(chnsEx[i]));
		close();
	}
	
	if (lengthOf(chnsMP)>1) {
		// Iterate through each channel in the z-stack to generate max projection
		for (i = 0; i < lengthOf(chnsMP); i++) {
			selectWindow(self+" - C="+toString(chnsMP[i]));
			run("Make Substack...", "slices="+ssSt+"-"+ssEnd);
			run("Z Project...", "projection=[Max Intensity]");
			rename("Max_SS_c"+chnsMP[i]);
			selectWindow(self+" - C="+toString(chnsMP[i]));
			selectWindow("Substack ("+ssSt+"-"+ssEnd+")");
			close();
		}
		
		// Make a string of image names to feed into to Merge Channels
		strArr = newArray(lengthOf(chnsMP));
		for (i = 0; i < lengthOf(chnsMP); i++) {
			//strArr[i] = "c"+(i+1)+"=[MAX_"+self+" - C="+(i+1)+"]";
			strArr[i] = "c"+(i+1)+"=Max_SS_c"+chnsMP[i];
		}
		str = String.join(strArr, " ");
		// Create a merged image from the max projections
		run("Merge Channels...", str+" create");
	}else{
		run("Z Project...", "projection=[Max Intensity]");
		selectWindow(self+" - C="+toString(chnsMP[0]));
		close();
	}
	
	// Begin processing
	//run("Flatten");
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	run("Smooth");
	run("Despeckle");
	run("Gaussian Blur...", "sigma="+sigma);
	//run("Maximum...","radius=5");
	//run("Mean...", "radius=5");
	run("Bin...", "x=2 y=2 bin=Average");
	run("Subtract Background...", "rolling=100");
	run("Flatten");
	run("8-bit");
	
	// Save the seedimage
	saveAs("PNG", dirSI+fnBase+".SeedImage.png");
	
	// Be sure to close open images before proceeding to the next one
	run("Close All");	
	
	// Wrap things up
	Dialog.create("Contine");
	Dialog.addChoice("Continue generating seed images?", Array.concat("Yes", "No"));
	Dialog.show();
	choiceCont = Dialog.getChoice();
	
	if (choiceCont == "No") {
		exit;
	}
}