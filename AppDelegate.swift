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
        
        // Força a janela a aparecer com a tela roxa
        let loginVC = LoginViewController()
        loginVC.apiUrl = apiUrl
        loginVC.onSuccess = { [weak self] in
            self?.loadReactApp()
        }
        
        window?.rootViewController = loginVC
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func loadReactApp() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        webView = WKWebView(frame: window!.bounds, configuration: config)
        webView?.isOpaque = false
        webView?.scrollView.contentInsetAdjustmentBehavior = .never
        
        if let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") {
            let url = URL(fileURLWithPath: htmlPath)
            webView?.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            
            let vc = UIViewController()
            vc.view = webView
            window?.rootViewController = vc
        }
    }
}

// ==========================================
// TUDO AQUI DENTRO PARA NÃO DAR ERRO DE TELA PRETA
// ==========================================
class LoginViewController: UIViewController {
    var apiUrl: String = ""
    var onSuccess: (() -> Void)?
    
    let keyTextField = UITextField()
    let loginButton = UIButton(type: .system)
    let discordButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = UIColor(red: 0.15, green: 0.0, blue: 0.25, alpha: 1.0) // ROXO
        
        let titleLabel = UILabel()
        titleLabel.text = "ACESSO PRIVATE"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        keyTextField.placeholder = "Insira sua Key aqui"
        keyTextField.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        keyTextField.textColor = .white
        keyTextField.layer.cornerRadius = 10
        keyTextField.autocapitalizationType = .none
        keyTextField.autocorrectionType = .no
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        keyTextField.leftView = paddingView
        keyTextField.leftViewMode = .always
        keyTextField.translatesAutoresizingMaskIntoConstraints = false
        
        loginButton.setTitle("Validar Key", for: .normal)
        loginButton.backgroundColor = UIColor(red: 0.5, green: 0.1, blue: 0.8, alpha: 1.0)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        loginButton.layer.cornerRadius = 10
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        discordButton.setTitle("Discord", for: .normal)
        discordButton.backgroundColor = UIColor(red: 0.34, green: 0.39, blue: 0.85, alpha: 1.0)
        discordButton.setTitleColor(.white, for: .normal)
        discordButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        discordButton.layer.cornerRadius = 10
        discordButton.addTarget(self, action: #selector(openDiscord), for: .touchUpInside)
        discordButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(keyTextField)
        view.addSubview(loginButton)
        view.addSubview(discordButton)
        
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -120),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            keyTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            keyTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            keyTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            keyTextField.heightAnchor.constraint(equalToConstant: 55),
            
            loginButton.topAnchor.constraint(equalTo: keyTextField.bottomAnchor, constant: 20),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            loginButton.heightAnchor.constraint(equalToConstant: 55),
            
            discordButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 15),
            discordButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            discordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            discordButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    @objc func openDiscord() {
        if let url = URL(string: "https://discord.gg/efyKdCXNXF") {
            UIApplication.shared.open(url)
        }
    }
    
    @objc func handleLogin() {
        view.endEditing(true)
        guard let key = keyTextField.text, !key.isEmpty else { return }
        
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "Desconhecido"
        let hwid = "\(UIDevice.current.model)-\(deviceId)"
        
        validateKeyWithAPI(key: key, hwid: hwid)
    }
    
    func validateKeyWithAPI(key: String, hwid: String) {
        guard let url = URL(string: apiUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    if let keyData = json.first(where: { ($0["key"] as? String) == key }) {
                        if let used = keyData["used"] as? Bool, used == true {
                            self.showAlert(msg: "Esta key já foi utilizada.")
                            return
                        }
                        
                        if let days = keyData["expire"] as? Double {
                            let expireDate = Date().addingTimeInterval(days * 24 * 60 * 60)
                            UserDefaults.standard.set(key, forKey: "SavedKey")
                            UserDefaults.standard.set(expireDate, forKey: "ExpireDate")
                            
                            if let keyId = keyData["id"] as? String {
                                self.updateKeyAsUsed(id: keyId, hwid: hwid)
                            }
                            self.onSuccess?()
                        } else {
                            self.showAlert(msg: "Key sem validade definida.")
                        }
                    } else {
                        self.showAlert(msg: "Key inválida ou não encontrada.")
                    }
                } else {
                    self.showAlert(msg: "Erro de conexão com a API.")
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
    
    func showAlert(msg: String) {
        let alert = UIAlertController(title: "Aviso", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
