package co.sotai.flutter_mediapipe;


import android.app.Activity;
import android.content.pm.PackageManager;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.plugin.platform.PlatformViewRegistry;
import io.flutter.plugin.common.EventChannel;


/**
 * FlutterMediapipePlugin
 */
public class FlutterMediapipePlugin implements FlutterPlugin, ActivityAware {

    public static final String VIEW = "flutter_mediapipe/view";

    private PlatformViewRegistry registry;
    private BinaryMessenger messenger;
    private PlatformViewFactory factory;

    private static final String FRAME_CHANNEL = "flutter_mediapipe/frameStream";
    private EventChannel frameEventChannel;
    private EventChannel.EventSink frameSink;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        registry = binding.getPlatformViewRegistry();
        messenger = binding.getBinaryMessenger();

        frameEventChannel = new EventChannel(binding.getBinaryMessenger(), FRAME_CHANNEL);
        frameEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                frameSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                frameSink = null;
            }
        });
    }


    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {}

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        factory = new NativeViewFactory(messenger, binding.getActivity(), frameSink);
        registry.registerViewFactory(VIEW, factory);
        binding.addRequestPermissionsResultListener(new PermissionsListener(factory));
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {
        //methodChannel.setMethodCallHandler(null);
    }

    private static class PermissionsListener implements RequestPermissionsResultListener {

        private final NativeViewFactory factory;

        public PermissionsListener(PlatformViewFactory factory){
            this.factory = (NativeViewFactory)factory;
        }

        @Override
        public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
            if (requestCode != 0){
                return false;
            } else {
                for (int result : grantResults) {
                    if(result == PackageManager.PERMISSION_GRANTED){
                        NativeView nativeView = factory.getNativeView();
                        nativeView.onResume();
                    }
                }
                return true;
            }
        }
    }

}