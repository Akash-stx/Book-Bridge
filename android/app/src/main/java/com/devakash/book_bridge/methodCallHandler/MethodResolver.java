package com.devakash.book_bridge.methodCallHandler;

import androidx.annotation.NonNull;

import com.devakash.book_bridge.pdfProcess.PDFservices;
import com.devakash.book_bridge.pdfProcess.PdfGlobalStore;
import com.tom_roush.pdfbox.pdmodel.PDDocument;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MethodResolver implements MethodChannel.MethodCallHandler {

    private MethodChannel methodChannel=null;
	public MethodResolver(MethodChannel methodChannel) {
		this.methodChannel=methodChannel;
	}

	@Override
	public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {

		switch (call.method) {
			case "processPdf":
				PdfGlobalStore.clearCurrentLoadedPdf();
				PDFservices.splitPDFpagesToBundle((String) call.arguments);
				break;
			default:
				result.notImplemented();
				break;
		}
	}
}
