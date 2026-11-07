import UIKit
import WebKit
import LocalAuthentication
import Foundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var webView: WKWebView?
    
    // URL da sua API
    let apiUrl = "https://69b9908ce69653ffe6a81689.mockapi.io/api/v1/bankkeys"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        webView = WKWebView(frame: window!.bounds, configuration: config)
        webView?.isOpaque = false
        webView?.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        webView?.scrollView.contentInsetAdjustmentBehavior = .never
        webView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        window?.overrideUserInterfaceStyle = .dark
        
        // 1. Inicia o fluxo de segurança
        authenticateWithFaceID()
        
        return true
    }
    
    func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Acesse sua conta Nubank com segurança."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
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
    
    // 2. Verifica se a Key está salva e válida
    func checkKeyStatus() {
        if let savedKey = UserDefaults.standard.string(forKey: "SavedKey"),
           let expireDate = UserDefaults.standard.object(forKey: "ExpireDate") as? Date {
            
            if Date() < expireDate {
                // Key válida e não expirou. Abre o app.
                self.loadReactApp()
            } else {
                // Key expirou. Limpa e pede de novo.
                UserDefaults.standard.removeObject(forKey: "SavedKey")
                UserDefaults.standard.removeObject(forKey: "ExpireDate")
                self.showLoginScreen()
            }
        } else {
            // Sem key salva. Pede login.
            self.showLoginScreen()
        }
    }
    
    func loadReactApp() {
        if let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") {
            let url = URL(fileURLWithPath: htmlPath)
            webView?.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            
            let viewController = UIViewController()
            viewController.view = webView
            window?.rootViewController = viewController
        }
    }
    
    // 3. Mostra a tela de Login nativa em SwiftUI/UIKit
    func showLoginScreen() {
        let loginVC = LoginViewController()
        loginVC.apiUrl = apiUrl
        loginVC.onSuccess = { [weak self] in
            self?.loadReactApp()
        }
        window?.rootViewController = loginVC
    }
}
