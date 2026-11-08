import UIKit
import WebKit
import LocalAuthentication

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var webView: WKWebView?
    
    let apiUrl = "https://69b9908ce69653ffe6a81689.mockapi.io/api/v1/bankkeys"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.overrideUserInterfaceStyle = .dark
        
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        webView = WKWebView(frame: window!.bounds, configuration: config)
        webView?.isOpaque = false
        webView?.scrollView.contentInsetAdjustmentBehavior = .never
        
        // Verifica se já tem key salva
        checkKeyStatus()
        
        return true
    }
    
    func checkKeyStatus() {
        if let _ = UserDefaults.standard.string(forKey: "SavedKey"),
           let expireDate = UserDefaults.standard.object(forKey: "ExpireDate") as? Date {
            
            if Date() < expireDate {
                self.loadReactApp()
            } else {
                UserDefaults.standard.removeObject(forKey: "SavedKey")
                UserDefaults.standard.removeObject(forKey: "ExpireDate")
                self.showLoginScreen()
            }
        } else {
            self.showLoginScreen()
        }
    }
    
    func loadReactApp() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Acesse sua conta com segurança.") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        self.loadHTML()
                    }
                }
            }
        } else {
            self.loadHTML()
        }
    }
    
    func loadHTML() {
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
        
        // O SEGREDO ESTÁ AQUI: Usar um NavigationController força a tela a aparecer
        let navController = UINavigationController(rootViewController: loginVC)
        navController.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = navController
    }
}
