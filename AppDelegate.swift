import UIKit
import WebKit
import LocalAuthentication

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var webView: WKWebView?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        webView = WKWebView(frame: window!.bounds, configuration: config)
        webView?.isOpaque = false
        webView?.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        
        // ISSO REMOVE AS BORDAS E PREENCHE A TELA TODA
        webView?.scrollView.contentInsetAdjustmentBehavior = .never 
        webView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let viewController = UIViewController()
        viewController.view = webView
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        // Força os ícones da barra de status a serem brancos
        window?.overrideUserInterfaceStyle = .dark
        
        authenticateWithFaceID()
        
        return true
    }
    
    func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Acesse sua conta Nubank com segurança."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.loadReactApp()
                    }
                }
            }
        } else {
            self.loadReactApp()
        }
    }
    
    func loadReactApp() {
        if let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") {
            let url = URL(fileURLWithPath: htmlPath)
            webView?.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }
}
