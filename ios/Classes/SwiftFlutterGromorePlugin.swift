import Flutter
import UIKit
import AppTrackingTransparency
import ABUAdSDK

public class SwiftFlutterGromorePlugin: NSObject, FlutterPlugin {
    private static var messenger: FlutterBinaryMessenger? = nil
    private var feedManager: FlutterGromoreFeedManager?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: FlutterGromoreContants.methodChannelName, binaryMessenger: registrar.messenger())
        let eventChanel = FlutterEventChannel(name: FlutterGromoreContants.eventChannelName, binaryMessenger: registrar.messenger())
        eventChanel.setStreamHandler(AdEventHandler.instance)
        let instance = SwiftFlutterGromorePlugin()
        
        messenger = registrar.messenger()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.register(FlutterGromoreFactory(messenger: registrar.messenger()), withId: FlutterGromoreContants.feedViewTypeId)
        
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any> ?? [:]
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "requestATT":
            requestATT(result: result)
        case "initSDK":
            initSDK(appId: args["appId"] as! String,result: result)
        case "showSplashAd":
            showSplashAd(args: args, result: result)
        case "showInterstitialAd":
            Utils.getVC().addChild(FlutterGromoreInterstitial.init(messenger: SwiftFlutterGromorePlugin.messenger!, arguments: args))
            result(true)
        case "loadFeedAd":
            feedManager = FlutterGromoreFeedManager(args: args, result: result)
            feedManager?.loadAd()
        case "clearFeedAd":
            let adsId: [String] = args["adsId"] as? [String] ?? []
            adsId.forEach { id in
                FlutterGromoreFeedCache.removeAd(key: id)
            }
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // 请求广告标识符
    private func requestATT(result: @escaping FlutterResult){
        // iOS 14 之后需要获取 ATT 追踪权限
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                let isAuthorized: Bool = status == ATTrackingManager.AuthorizationStatus.authorized
                result(isAuthorized)
            })
        } else {
            result(true)
        }
    }
    
    // 初始化SDK
    private func initSDK(appId: String, result: @escaping FlutterResult) {
        ABUAdSDKManager.setupSDK(withAppId: appId) { ABUUserConfig in
            ABUUserConfig.logEnable = true
            return ABUUserConfig
        }
        result(true)
    }
    
    private func showSplashAd(args: [String: Any], result: @escaping FlutterResult) {
        let splashView: FlutterGromoreSplash = FlutterGromoreSplash(args)
        UIApplication.shared.keyWindow?.addSubview(splashView)
        result(true)
    }
}
