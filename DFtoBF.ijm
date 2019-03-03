dir1 = getDirectory("Choose Source Directory ");
dir2 = dir1;
list = getFileList(dir1);

setBatchMode(true);
for (i=0; i<list.length; i++) {
 showProgress(i+1, list.length);
 filename = dir1 + list[i];
 if (!endsWith(toLowerCase(filename), "_processed.tif") && endsWith(toLowerCase(filename), ".tif")) {
 open(filename);
 write("Opening filename", filename);
 //selectWindow(filename);
 

 run("8-bit");
 run("Invert");
 //run("Brightness/Contrast...");
 //run("Enhance Contrast", "saturated=0.35");
 setMinAndMax(30, 255);
 run("Apply LUT");
 run("Close");

 saveAs("TIFF", dir2+list[i]+"_processed");
 //close();
 }
}



/*
open();
run("8-bit");
run("Invert");
//run("Brightness/Contrast...");
run("Enhance Contrast", "saturated=0.35");
run("Apply LUT");
run("Close");
run("Save");
close();

*/

