import UIKit
import Flutter
import Firebase
import flutter_downloader
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
    GMSServices.provideAPIKey("AIzaSyD5r1UkqLfEg5_SpyYxqdC4rlwf7TY0WkI")
    GeneratedPluginRegistrant.register(with: self)
      if(FirebaseApp.app() == nil){
              FirebaseApp.configure()
          }
   
      FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
private func registerPlugins(registry: FlutterPluginRegistry) {
    if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
       FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
    }
}
