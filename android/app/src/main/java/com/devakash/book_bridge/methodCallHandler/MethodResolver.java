package com.devakash.book_bridge.methodCallHandler;

import androidx.annotation.NonNull;

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
			default:
				result.notImplemented();
				break;
		}
	}
}
