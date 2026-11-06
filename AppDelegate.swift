import UIKit
import WebKit
import LocalAuthentication // Importante para o Face ID

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
        webView?.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        
        webView?.scrollView.contentInsetAdjustmentBehavior = .never
        webView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Cria o ViewController primeiro (com tela de bloqueio fake se quiser)
        let viewController = UIViewController()
        viewController.view = webView
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        // CHAMA O FACE ID AQUI
        authenticateWithFaceID()
        
        return true
    }
    
    func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        // Verifica se o dispositivo suporta biometria
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Acesse sua conta Nubank com segurança."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // SUCESSO: Carrega o HTML do React
                        self.loadReactApp()
                    } else {
                        // FALHA: O usuário cancelou ou falhou. 
                        // Opcional: Fechar o app ou mostrar um alerta.
                        print("Autenticação falhou: \(authenticationError?.localizedDescription ?? "Erro")")
                    }
                }
            }
        } else {
            // Dispositivo não tem Face ID (ex: simulador ou iPhone antigo)
            // Para não travar o app, carrega direto.
            print("Biometria não disponível. Carregando app...")
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
