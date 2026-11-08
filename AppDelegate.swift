import UIKit
import WebKit
import LocalAuthentication

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var webView: WKWebView?
    
    // URL da sua API
    let apiUrl = "https://69b9908ce69653ffe6a81689.mockapi.io/api/v1/bankkeys"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Configuração do WebView
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        webView = WKWebView(frame: window!.bounds, configuration: config)
        webView?.isOpaque = false
        webView?.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        webView?.scrollView.contentInsetAdjustmentBehavior = .never
        
        window?.overrideUserInterfaceStyle = .dark
        
        // Inicia o fluxo
        authenticateWithFaceID()
        
        return true
    }
    
    func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Acesse sua conta com segurança.") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        self.checkKeyStatus()
                    }
                }
            }
        } else {
            self.checkKeyStatus()
        }
    }
    
    func checkKeyStatus() {
        if let _ = UserDefaults.standard.string(forKey: "SavedKey"),
           let expireDate = UserDefaults.standard.object(forKey: "ExpireDate") as? Date {
            
            if Date() < expireDate {
                self.loadReactApp()
            } else {
                // Key expirou
                UserDefaults.standard.removeObject(forKey: "SavedKey")
                UserDefaults.standard.removeObject(forKey: "ExpireDate")
                self.showLoginScreen()
            }
        } else {
            // Sem Key salva
            self.showLoginScreen()
        }
    }
    
    func loadReactApp() {
        if let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") {
            let url = URL(fileURLWithPath: htmlPath)
            webView?.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            
            let vc = UIViewController()
            vc.view = webView
            window?.rootViewController = vc
        }
    }
    
    func showLoginScreen() {
        let loginVC = LoginViewController()
        loginVC.apiUrl = apiUrl
        loginVC.onSuccess = { [weak self] in
            self?.loadReactApp()
        }
        window?.rootViewController = loginVC
    }
}
