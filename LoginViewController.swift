import UIKit

class LoginViewController: UIViewController {
    var apiUrl: String = ""
    var onSuccess: (() -> Void)?
    
    let keyTextField = UITextField()
    let loginButton = UIButton(type: .system)
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        
        // Título
        let titleLabel = UILabel()
        titleLabel.text = "Acesso Restrito"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Campo de Texto
        keyTextField.placeholder = "Insira sua Key aqui"
        keyTextField.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        keyTextField.textColor = .white
        keyTextField.layer.cornerRadius = 8
        keyTextField.autocapitalizationType = .none
        keyTextField.autocorrectionType = .no
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 40))
        keyTextField.leftView = paddingView
        keyTextField.leftViewMode = .always
        keyTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Botão
        loginButton.setTitle("Validar Key", for: .normal)
        loginButton.backgroundColor = UIColor(red: 0.5, green: 0.1, blue: 0.8, alpha: 1.0)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 8
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Loading
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(keyTextField)
        view.addSubview(loginButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            
            keyTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            keyTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            keyTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            keyTextField.heightAnchor.constraint(equalToConstant: 50),
            
            loginButton.topAnchor.constraint(equalTo: keyTextField.bottomAnchor, constant: 20),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc func handleLogin() {
        guard let key = keyTextField.text, !key.isEmpty else { return }
        
        activityIndicator.startAnimating()
        loginButton.isEnabled = false
        
        // PEGA O HWID REAL DO DISPOSITIVO
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "Desconhecido"
        let deviceModel = UIDevice.current.model
        let hwid = "\(deviceModel)-\(deviceId)"
        
        // Valida na API
        validateKeyWithAPI(key: key, hwid: hwid)
    }
    
    func validateKeyWithAPI(key: String, hwid: String) {
        // Você precisa configurar a API para receber a KEY e o HWID via GET ou POST.
        // Aqui ele busca todas as keys e compara, mas o ideal seria um endpoint /validate
        guard let url = URL(string: apiUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.loginButton.isEnabled = true
                
                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
                        
                        // Procura a key no retorno da API
                        if let keyData = json?.first(where: { ($0["key"] as? String) == key }) {
                            // Verifica se já está em uso
                            if let used = keyData["used"] as? Bool, used == true {
                                self.showAlert(msg: "Esta key já foi utilizada.")
                                return
                            }
                            
                            // Calcula a expiração
                            if let days = keyData["expire"] as? Double {
                                let expireDate = Date().addingTimeInterval(days * 24 * 60 * 60)
                                UserDefaults.standard.set(key, forKey: "SavedKey")
                                UserDefaults.standard.set(expireDate, forKey: "ExpireDate")
                                
                                // Opcional: Atualizar a API dizendo que a key foi usada
                                self.updateKeyAsUsed(key: key, hwid: hwid)
                                
                                self.onSuccess?()
                            } else {
                                self.showAlert(msg: "Key sem validade definida.")
                            }
                        } else {
                            self.showAlert(msg: "Key inválida ou não encontrada.")
                        }
                    } catch {
                        self.showAlert(msg: "Erro ao ler resposta da API.")
                    }
                } else {
                    self.showAlert(msg: "Erro de conexão com o servidor.")
                }
            }
        }.resume()
    }
    
    func updateKeyAsUsed(key: String, hwid: String) {
        // Aqui você faz um PUT para a API informando que a key foi usada e salvando o HWID
        // Exemplo: URL = apiUrl + "/" + idDaKey
        // Body: { "used": true, "device": hwid }
    }
    
    func showAlert(msg: String) {
        let alert = UIAlertController(title: "Aviso", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
