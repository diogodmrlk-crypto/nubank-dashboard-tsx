import UIKit
import WebKit
import LocalAuthentication

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var webView: WKWebView?
    
    let apiUrl = "https://69b9908ce69653ffe6a81689.mockapi.io/api/v1/bankkeys"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Cria a janela na força bruta
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.overrideUserInterfaceStyle = .dark
        
        // Força a janela a ser a principal (isso evita a tela preta)
        window?.makeKeyAndVisible()
        
        // Cria o WebView (para depois)
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        webView = WKWebView(frame: window!.bounds, configuration: config)
        webView?.isOpaque = false
        
        // Abre a tela de login
        showLoginScreen()
        
        return true
    }
    
    func showLoginScreen() {
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor(red: 0.15, green: 0.0, blue: 0.25, alpha: 1.0) // ROXO
        
        let titleLabel = UILabel()
        titleLabel.text = "Acesso Restrito"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 26)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let keyTextField = UITextField()
        keyTextField.placeholder = "Insira sua Key aqui"
        keyTextField.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        keyTextField.textColor = .white
        keyTextField.layer.cornerRadius = 8
        keyTextField.autocapitalizationType = .none
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 40))
        keyTextField.leftView = paddingView
        keyTextField.leftViewMode = .always
        keyTextField.translatesAutoresizingMaskIntoConstraints = false
        
        let loginButton = UIButton(type: .system)
        loginButton.setTitle("Validar Key", for: .normal)
        loginButton.backgroundColor = UIColor(red: 0.5, green: 0.1, blue: 0.8, alpha: 1.0)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 8
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        let action = UIAction { _ in
            guard let key = keyTextField.text, !key.isEmpty else { return }
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "Desconhecido"
            let hwid = "\(UIDevice.current.model)-\(deviceId)"
            
            self.validateKeyWithAPI(key: key, hwid: hwid, onSuccess: {
                self.loadReactApp()
            }, onFailure: { msg in
                let alert = UIAlertController(title: "Aviso", message: msg, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                vc.present(alert, animated: true)
            })
        }
        loginButton.addAction(action, for: .touchUpInside)
        
        vc.view.addSubview(titleLabel)
        vc.view.addSubview(keyTextField)
        vc.view.addSubview(loginButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 80),
            titleLabel.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            
            keyTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            keyTextField.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 20),
            keyTextField.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20),
            keyTextField.heightAnchor.constraint(equalToConstant: 50),
            
            loginButton.topAnchor.constraint(equalTo: keyTextField.bottomAnchor, constant: 20),
            loginButton.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        window?.rootViewController = vc
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
    
    func validateKeyWithAPI(key: String, hwid: String, onSuccess: @escaping () -> Void, onFailure: @escaping (String) -> Void) {
        guard let url = URL(string: apiUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    if let keyData = json.first(where: { ($0["key"] as? String) == key }) {
                        if let used = keyData["used"] as? Bool, used == true {
                            onFailure("Esta key já foi utilizada.")
                            return
                        }
                        
                        if let days = keyData["expire"] as? Double {
                            let expireDate = Date().addingTimeInterval(days * 24 * 60 * 60)
                            UserDefaults.standard.set(key, forKey: "SavedKey")
                            UserDefaults.standard.set(expireDate, forKey: "ExpireDate")
                            
                            if let keyId = keyData["id"] as? String {
                                self.updateKeyAsUsed(id: keyId, hwid: hwid)
                            }
                            onSuccess()
                        } else {
                            onFailure("Key sem validade definida.")
                        }
                    } else {
                        onFailure("Key inválida ou não encontrada.")
                    }
                } else {
                    onFailure("Erro de conexão com a API.")
                }
            }
        }.resume()
    }
    
    func updateKeyAsUsed(id: String, hwid: String) {
        guard let url = URL(string: "\(apiUrl)/\(id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["used": true, "device": hwid, "activatedAt": Date().timeIntervalSince1970]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
    }
}
