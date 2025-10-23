import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var googleMapsApiKey: String?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // MethodChannel 설정
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let googleMapsChannel = FlutterMethodChannel(name: "com.pes.frontend/google_maps",
                                                  binaryMessenger: controller.binaryMessenger)
    
    googleMapsChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard call.method == "setGoogleMapsApiKey" else {
        result(FlutterMethodNotImplemented)
        return
      }
      
      if let args = call.arguments as? Dictionary<String, Any>,
         let apiKey = args["apiKey"] as? String {
        self?.googleMapsApiKey = apiKey
        GMSServices.provideAPIKey(apiKey)
        result("Google Maps API Key set successfully")
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT",
                           message: "API Key is required",
                           details: nil))
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
