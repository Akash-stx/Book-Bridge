package com.devakash.book_bridge;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.os.Handler;
import android.widget.Toast;

import com.devakash.book_bridge.methodCallHandler.MethodResolver;

public class MainActivity extends FlutterActivity {
        private static final String CHANNEL = "com.devakash.book_bridge/initalize";
        private MethodChannel methodChannel=null;
        private int count=0;
 
        
        @Override
        protected void onDestroy() {
            super.onDestroy();
        }

        @Override
        public void onBackPressed() {
             backButtonCloseCustom();  
        }

        private void backButtonCloseCustom(){
                if (count >= 1) {
                        // If the back button is pressed again within 2 seconds, exit the app or perform any action
                        finishAffinity();
                    } else {
                        // Show a toast message to inform the user
                        Toast.makeText(this, "Press back again to exit", Toast.LENGTH_SHORT).show();

                        // Increment the counter
                        count++;

                        // Reset the counter in 2 seconds
                        new Handler().postDelayed(new Runnable() {
                            @Override
                            public void run() {
                                count = 0;
                            }
                        }, 2000);
                    }
        }


        @Override
        public void configureFlutterEngine(FlutterEngine flutterEngine) {
            super.configureFlutterEngine(flutterEngine);
            methodChannel = new MethodChannel(flutterEngine.getDartExecutor(), CHANNEL);
            methodChannel.setMethodCallHandler(new MethodResolver(methodChannel));
        }


    
}
