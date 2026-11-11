import UIKit
import WebKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var webView: WKWebView?
    var keyTextField: UITextField?
    
    var isShowingLogin = false
    var isWebViewLoaded = false
    
    let apiUrl = "https://69b9908ce69653ffe6a81689.mockapi.io/api/v1/bankkeys"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.overrideUserInterfaceStyle = .dark
        window?.makeKeyAndVisible()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted { print("Permissão de notificação concedida") }
        }
        
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        webView = WKWebView(frame: window!.bounds, configuration: config)
        webView?.isOpaque = false
        webView?.scrollView.contentInsetAdjustmentBehavior = .never
        
        checkKeyStatus()
        
        return true
    }
    
    func agendarNotificacao(valor: String, data: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Nubank"
        content.body = "Você acaba de receber um PIX!\nPix recebido em \(formatarData(data)) no valor de R$ \(valor)"
        content.sound = UNNotificationSound.default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: data)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func formatarData(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy 'às' HH:mm"
        return formatter.string(from: date)
    }
    
    func abrirTelaNotificacao() {
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        vc.modalPresentationStyle = .formSheet
        
        let titleLabel = UILabel()
        titleLabel.text = "Notificação de Pagamentos"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .compact
        datePicker.tintColor = .white
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        let valorField = UITextField()
        valorField.placeholder = "Valor (ex: 45.000,00)"
        valorField.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        valorField.textColor = .white
        valorField.layer.cornerRadius = 8
        valorField.keyboardType = .decimalPad
        valorField.translatesAutoresizingMaskIntoConstraints = false
        
        let agendarButton = UIButton(type: .system)
        agendarButton.setTitle("Agendar Notificação", for: .normal)
        agendarButton.backgroundColor = UIColor(red: 0.5, green: 0.1, blue: 0.8, alpha: 1.0)
        agendarButton.setTitleColor(.white, for: .normal)
        agendarButton.layer.cornerRadius = 8
        agendarButton.translatesAutoresizingMaskIntoConstraints = false
        
        let action = UIAction { _ in
            guard let valor = valorField.text, !valor.isEmpty else { return }
            self.agendarNotificacao(valor: valor, data: datePicker.date)
            vc.dismiss(animated: true)
        }
        agendarButton.addAction(action, for: .touchUpInside)
        
        vc.view.addSubview(titleLabel)
        vc.view.addSubview(datePicker)
        vc.view.addSubview(valorField)
        vc.view.addSubview(agendarButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            
            datePicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            datePicker.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            
            valorField.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 30),
            valorField.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 40),
            valorField.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -40),
            valorField.heightAnchor.constraint(equalToConstant: 50),
            
            agendarButton.topAnchor.constraint(equalTo: valorField.bottomAnchor, constant: 30),
            agendarButton.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 40),
            agendarButton.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -40),
            agendarButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        window?.rootViewController?.present(vc, animated: true)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if !isShowingLogin {
            checkKeyOnServer()
        }
    }
    
    func checkKeyOnServer() {
        guard let savedKey = UserDefaults.standard.string(forKey: "SavedKey"),
              let expireDate = UserDefaults.standard.object(forKey: "ExpireDate") as? Date else {
            return
        }
        
        if Date() >= expireDate {
            logout()
            return
        }
        
        guard let url = URL(string: apiUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    if let keyData = json.first(where: { ($0["key"] as? String) == savedKey }) {
                        let used = keyData["used"] as? Bool ?? false
                        let status = keyData["status"] as? String ?? "active"
                        
                        if !used || status == "blocked" || status == "revoked" {
                            self.logout()
                        }
                    } else {
                        self.logout()
                    }
                }
            }
        }.resume()
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "SavedKey")
        UserDefaults.standard.removeObject(forKey: "ExpireDate")
        showLoginScreen()
    }
    
    func checkKeyStatus() {
        if let expireDate = UserDefaults.standard.object(forKey: "ExpireDate") as? Date {
            if Date() < expireDate {
                loadReactApp()
            } else {
                logout()
            }
        } else {
            showLoginScreen()
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
            
            setupInvisibleButton(on: vc)
        }
    }
    
    // BOTÃO CORRIGIDO: SUBIU 30px E FICOU MAIOR PARA FACILITAR O TOQUE
    func setupInvisibleButton(on vc: UIViewController) {
        let invisibleButton = UIButton(type: .custom)
        invisibleButton.backgroundColor = .clear
        invisibleButton.translatesAutoresizingMaskIntoConstraints = false
        
        let action = UIAction { _ in
            self.abrirTelaNotificacao()
        }
        invisibleButton.addAction(action, for: .touchUpInside)
        
        vc.view.addSubview(invisibleButton)
        
        NSLayoutConstraint.activate([
            invisibleButton.bottomAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            invisibleButton.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20),
            invisibleButton.widthAnchor.constraint(equalToConstant: 70),
            invisibleButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    func showLoginScreen() {
        if isShowingLogin { return }
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
                        
                        if let expireAmount = keyData["expire"] as? Double, let type = keyData["type"] as? String {
                            var timeInterval: TimeInterval = 0
                            
                            if type == "hourly" {
                                timeInterval = expireAmount * 60 * 60
                            } else if type == "daily" {
                                timeInterval = expireAmount * 24 * 60 * 60
                            } else if type == "weekly" {
                                timeInterval = expireAmount * 7 * 24 * 60 * 60
                            } else if type == "monthly" {
                                timeInterval = 30 * 24 * 60 * 60
                            } else if type == "perm" {
                                timeInterval = 36500 * 24 * 60 * 60
                            } else {
                                timeInterval = expireAmount * 24 * 60 * 60
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
