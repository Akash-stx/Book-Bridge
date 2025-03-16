package com.devakash.book_bridge.pdfProcess.utils;

public class PageOperationOutcome {
	public boolean isRedable;
	public long size;

	public PageOperationOutcome(boolean isRedable, long size) {
		this.isRedable = isRedable;
		this.size = size;
	}
}
