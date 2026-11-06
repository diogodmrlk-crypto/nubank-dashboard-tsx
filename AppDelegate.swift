import UIKit
import WebKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var webView: WKWebView?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Configuração para permitir arquivos locais (JS/CSS)
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        webView = WKWebView(frame: window!.bounds, configuration: config)
        webView?.isOpaque = false
        webView?.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // Fundo escuro do Nubank
        
        // Procura o index.html na raiz do app
        if let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") {
            let url = URL(fileURLWithPath: htmlPath)
            webView?.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            print("ERRO FATAL: index.html nao encontrado!")
        }
        
        let viewController = UIViewController()
        viewController.view = webView
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        return true
    }
}
