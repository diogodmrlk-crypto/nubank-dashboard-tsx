import UIKit
import WebKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let webView = WKWebView(frame: window!.bounds)
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        
        // Procura o index.html na raiz do Bundle
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            let readAccessUrl = url.deletingLastPathComponent()
            webView.loadFileURL(url, allowingReadAccessTo: readAccessUrl)
        } else {
            print("ERRO: index.html não encontrado no bundle")
        }
        
        let viewController = UIViewController()
        viewController.view = webView
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        return true
    }
}
