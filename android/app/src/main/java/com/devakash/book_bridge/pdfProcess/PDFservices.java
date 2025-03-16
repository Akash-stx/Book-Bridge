package com.devakash.book_bridge.pdfProcess;

import com.devakash.book_bridge.pdfProcess.utils.CommonProgressData;
import com.devakash.book_bridge.pdfProcess.utils.PageOperationOutcome;
import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.pdmodel.PDPage;
import com.tom_roush.pdfbox.pdmodel.PDPageTree;
import com.tom_roush.pdfbox.text.PDFTextStripper;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.MethodChannel;

public class PDFservices {

	public static void splitPDFpagesToBundle(String path) {
		ExecutorService executor = Executors.newSingleThreadExecutor(); // ✅ New executor per PDF
		executor.submit(() -> {
			try {
				splitPDFpagesToBundleHelperSync(path);
				// PDF processing logic here
			} finally {
				executor.shutdown(); // ✅ Shut down after task completes
			}
		});
	}

	public static void splitPDFpagesToBundleHelperSync(String path) {
		PDDocument  document = loadPdf(path);
        if(document==null){
			PdfGlobalStore.pdfCallbackToFlutter(0, "LOOP NUMBER");
			return;
		}

		PDPageTree OriginalPages=document.getPages();
		CommonProgressData progress=new CommonProgressData(OriginalPages);// get all data and methods for progress

		System.out.println(progress.toString());

		int sliceNumber=0;
		long currentSliceSize=0;

		progress.updateOtherPdfProgress(50);
		PdfGlobalStore.pdfCallbackToFlutter(progress.getCurrentTotalPercentage(), "LOOP NUMBER");

		for (int i=0;i<progress.totalPdfPages;i++){
			PDPage originalPage=OriginalPages.get(i);
			PageOperationOutcome currentPageCommonInfo=commonOperationOnSinglePage(originalPage);
			if(currentPageCommonInfo.isRedable && currentPageCommonInfo.size < PdfGlobalStore.getPdfSplitSize()){

			}else{
				//failed pdf store this object into so recreate
			}
			progress.updatePdfProcessingProgress(i);
			PdfGlobalStore.pdfCallbackToFlutter(progress.getCurrentTotalPercentage(), "LOOP NUMBER");
		}

		progress.updateOtherPdfProgress(100);
		PdfGlobalStore.pdfCallbackToFlutter(progress.getCurrentTotalPercentage(), "LOOP NUMBER");
		//int pageNumber = document.getNumberOfPages();

	}


	public static PageOperationOutcome commonOperationOnSinglePage(PDPage originalPage) {
		PDDocument tempraryPdfObject = new PDDocument();
		tempraryPdfObject.addPage(originalPage);
		return new PageOperationOutcome(isTextPresent(tempraryPdfObject),getPdfSizeInMemory(tempraryPdfObject));
	}


	public static long getPdfSizeInMemory(PDDocument document) {
		try (ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream()) {
			document.save(byteArrayOutputStream);
			return byteArrayOutputStream.size();
		} catch (Exception e) {
			return  0;
		}
	}



	public static boolean isTextPresent(PDDocument newDoc) {
		try {
			PDFTextStripper stripper = new PDFTextStripper();
			return containsSingleLetter(stripper.getText(newDoc));
		} catch (Exception e) {
			return  false;
		}
	}

	public static boolean containsSingleLetter(String str) {
		if(str==null) {
			return false;
		}
		int len = str.length();
		for (int i = 0; i < len; i++) {
			if (Character.isLetter(str.charAt(i))) {
				return true; // Found at least one letter
			}
		}
		return false;
	}

	public static PDDocument  loadPdf(String filePath){
		try {
			return PDDocument.load(new File(filePath));
		} catch (Exception e) {
			return null;
		}

	}

	public static PDDocument  newPDF(){
			return new PDDocument();
	}

}
