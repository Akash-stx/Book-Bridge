package com.devakash.book_bridge.pdfProcess.utils;

import com.tom_roush.pdfbox.pdmodel.PDPageTree;

public class CommonProgressData {
	private final double PAGE_INCREMENT_PERCENTAGE = 20.0;
	private final double HUNDRED = 100.0;

	public double totalPdfPages = 0.0;
	public double total_Max_Progress = 0.0;
	public double totalPdfProcessingProgress = 0.0;
	public double totalOtherProcessesProgress = 0.0;

	public double currentPdfProcessingProgress =0.0;
	public double currentOtherProcessingProgress =0.0;

	public CommonProgressData(PDPageTree OriginalPages) {
		//saving the total pdf page count in this object
		totalPdfPages = ((double)OriginalPages.getCount());
		// doing calculation to add some more to this pdf page count do that not only for loop  other progress can be sown as number
		// so here caluctatng this with totalpdf with 20 pectage of total pdf adding both get new value
		total_Max_Progress= totalPdfPages + PAGE_INCREMENT_PERCENTAGE/HUNDRED * totalPdfPages;
		// here getting the pdf processing decimal reserved for pdf for loop only under 1
		// example 200/240 gives some 0.83 so this is reserved by pdf processing for loop
		// and other is 1-0.83 gives 0.17 like that so adding both get (1)
		// so the idea is i caluclate the for loop progress and give a value under 0.83
		// by index/totalPdfCount wich give some decimal value multiplised by its reserved value here is 0.83
		// so from for loop i get 0.83 and other is get by other progress adding bothe get 0 to 1 value so multipling that with 100 give inbetween number from 0 to 100 wich indirecly look like prcentage feeling , wich can show to screen
		totalPdfProcessingProgress = totalPdfPages/total_Max_Progress;
		totalOtherProcessesProgress = 1 - totalPdfProcessingProgress;

	}

	public double updateOtherPdfProgress(int progress){
		// Example: How to find 20% of a number
		// To get a percentage, we divide by 100 because 100% means the whole number.
		// For example, if we want 20% of 50:
		// we first find decimal of 20 then multiply by the number whose 20 percentage you need
		// → 20 / 100 = 0.2 (this is the decimal form of 20%)
		// → 0.2 * 50 = 10 (so, 20% of 50 is 10)
		// You can divide by other numbers too, like 200/1000, and still get the same result.
		// But using 100 makes it easier to understand because percentages are based on 100.

		currentOtherProcessingProgress = ((double) progress/HUNDRED) * totalOtherProcessesProgress;
		return currentOtherProcessingProgress;
	}

	public double updatePdfProcessingProgress(int currentIndexInForLoop){
		// Example: How to find 20% of a number
		// To get a percentage, we divide by 100 because 100% means the whole number.
		// For example, if we want 20% of 50:
		// we first find decimal of 20 then multiply by the number whose 20 percentage you need
		// → 20 / 100 = 0.2 (this is the decimal form of 20%)
		// → 0.2 * 50 = 10 (so, 20% of 50 is 10)
		// You can divide by other numbers too, like 200/1000, and still get the same result.
		// But using 100 makes it easier to understand because percentages are based on 100.

		currentPdfProcessingProgress = (((double) currentIndexInForLoop+1)/totalPdfPages) * totalPdfProcessingProgress;
		return currentPdfProcessingProgress;
	}
	public int getCurrentTotalPercentage(){
		// Example: How to find 20% of a number
		// To get a percentage, we divide by 100 because 100% means the whole number.
		// For example, if we want 20% of 50:
		// we first find decimal of 20 then multiply by the number whose 20 percentage you need
		// → 20 / 100 = 0.2 (this is the decimal form of 20%)
		// → 0.2 * 50 = 10 (so, 20% of 50 is 10)
		// You can divide by other numbers too, like 200/1000, and still get the same result.
		// But using 100 makes it easier to understand because percentages are based on 100.

		return (int)((currentPdfProcessingProgress+currentOtherProcessingProgress)*HUNDRED);
	}

	@Override
	public String toString() {
		return "CommonProgressData{" +
				"PAGE_INCREMENT_PERCENTAGE=" + PAGE_INCREMENT_PERCENTAGE +
				", HUNDRED=" + HUNDRED +
				", totalPdfPages=" + totalPdfPages +
				", total_Max_Progress=" + total_Max_Progress +
				", totalPdfProcessingProgress=" + totalPdfProcessingProgress +
				", totalOtherProcessesProgress=" + totalOtherProcessesProgress +
				", currentPdfProcessingProgress=" + currentPdfProcessingProgress +
				", currentOtherProcessingProgress=" + currentOtherProcessingProgress +
				'}';
	}
}
