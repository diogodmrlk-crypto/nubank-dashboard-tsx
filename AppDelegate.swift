import UIKit
import WebKit
import LocalAuthentication

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var webView: WKWebView?
    var keyTextField: UITextField?
    
    // Variáveis de controle
    var isShowingLogin = false
    var isWebViewLoaded = false
    
    let apiUrl = "https://69b9908ce69653ffe6a81689.mockapi.io/api/v1/bankkeys"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.overrideUserInterfaceStyle = .dark
        window?.makeKeyAndVisible()
        
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        webView = WKWebView(frame: window!.bounds, configuration: config)
        webView?.isOpaque = false
        webView?.scrollView.contentInsetAdjustmentBehavior = .never
        
        checkKeyStatus()
        
        return true
    }
    
    // ESSA FUNÇÃO É CHAMADA TODA VEZ QUE O APP VOLTA DO BACKGROUND
    func applicationDidBecomeActive(_ application: UIApplication) {
        checkKeyStatus()
    }
    
    func checkKeyStatus() {
        if let expireDate = UserDefaults.standard.object(forKey: "ExpireDate") as? Date {
            if Date() < expireDate {
                // Key válida
                if !isWebViewLoaded {
                    loadReactApp()
                }
            } else {
                // Key expirou
                UserDefaults.standard.removeObject(forKey: "SavedKey")
                UserDefaults.standard.removeObject(forKey: "ExpireDate")
                if !isShowingLogin {
                    showLoginScreen()
                }
            }
        } else {
            // Sem key salva
            if !isShowingLogin {
                showLoginScreen()
            }
        }
    }
    
    func loadReactApp() {
        isShowingLogin = false
        isWebViewLoaded = true
        
        if let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") {
            let url = URL(fileURLWithPath: htmlPath)
            webView?.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            
            let vc = UIViewController()
            vc.view = webView
            window?.rootViewController = vc
        }
    }
    
    func showLoginScreen() {
        isShowingLogin = true
        isWebViewLoaded = false
        
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor(red: 0.15, green: 0.0, blue: 0.25, alpha: 1.0)
        
        let titleLabel = UILabel()
        titleLabel.text = "ACESSO PRIVATE"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let keyTextField = UITextField()
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
        self.keyTextField = keyTextField
        
        let loginButton = UIButton(type: .system)
        loginButton.setTitle("Validar Key", for: .normal)
        loginButton.backgroundColor = UIColor(red: 0.5, green: 0.1, blue: 0.8, alpha: 1.0)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        loginButton.layer.cornerRadius = 10
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        let loginAction = UIAction { _ in
            vc.view.endEditing(true)
            guard let key = self.keyTextField?.text, !key.isEmpty else { return }
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
        loginButton.addAction(loginAction, for: .touchUpInside)
        
        let discordButton = UIButton(type: .system)
        discordButton.setTitle("Discord", for: .normal)
        discordButton.backgroundColor = UIColor(red: 0.34, green: 0.39, blue: 0.85, alpha: 1.0)
        discordButton.setTitleColor(.white, for: .normal)
        discordButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        discordButton.layer.cornerRadius = 10
        discordButton.translatesAutoresizingMaskIntoConstraints = false
        
        let discordAction = UIAction { _ in
            if let url = URL(string: "https://discord.gg/efyKdCXNXF") {
                UIApplication.shared.open(url)
            }
        }
        discordButton.addAction(discordAction, for: .touchUpInside)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        containerView.addSubview(keyTextField)
        containerView.addSubview(loginButton)
        containerView.addSubview(discordButton)
        vc.view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor, constant: -50),
            containerView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 25),
            containerView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -25),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            keyTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            keyTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            keyTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            keyTextField.heightAnchor.constraint(equalToConstant: 55),
            
            loginButton.topAnchor.constraint(equalTo: keyTextField.bottomAnchor, constant: 20),
            loginButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 55),
            
            discordButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 15),
            discordButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            discordButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            discordButton.heightAnchor.constraint(equalToConstant: 55),
            discordButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        window?.rootViewController = vc
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
                        
                        // CORREÇÃO DA MATEMÁTICA DE TEMPO AQUI
                        if let expireAmount = keyData["expire"] as? Double, let type = keyData["type"] as? String {
                            var timeInterval: TimeInterval = 0
                            
                            if type == "hourly" {
                                timeInterval = expireAmount * 60 * 60 // Horas
                            } else if type == "daily" {
                                timeInterval = expireAmount * 24 * 60 * 60 // Dias
                            } else if type == "weekly" {
                                timeInterval = expireAmount * 7 * 24 * 60 * 60 // Semanas
                            } else if type == "monthly" {
                                timeInterval = 30 * 24 * 60 * 60 // Mês
                            } else if type == "perm" {
                                timeInterval = 36500 * 24 * 60 * 60 // Permanente (100 anos)
                            } else {
                                timeInterval = expireAmount * 24 * 60 * 60 // Fallback
                            }
                            
                            let expireDate = Date().addingTimeInterval(timeInterval)
                            UserDefaults.standard.set(key, forKey: "SavedKey")
                            UserDefaults.standard.set(expireDate, forKey: "ExpireDate")
                            
                            if let keyId = keyData["id"] as? String {
                                self.updateKeyAsUsed(id: keyId, hwid: hwid)
                            }
                            onSuccess()
                        } else {
                            onFailure("Erro ao ler validade da Key.")
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
