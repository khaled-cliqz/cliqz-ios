//
//  RegistrationViewController.swift
//  Client
//
//  Created by Sahakyan on 11/13/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import Foundation
import BondAPI
import SnapKit
import Shared

class RegistrationViewController: UIViewController {

    var profile: Profile?
	var tabManager: TabManager!

	private let contentView = UIView()
	private let backgroundView = LoginGradientView()

	private let image = UIImageView()
	private let titleLabel = UILabel()
	private let descriptionLabel = UILabel()
	private let errorLabel = UILabel()
	private let emailTextField = EmailTextField()
	private let nextButton = UIButton(type: .custom)
	private let termsConditionsLabel = UILabel()

	override func viewDidLoad() {
		super.viewDidLoad()
        presentIntroViewController()
        
		self.title = NSLocalizedString("Login", tableName: "Cliqz", comment: "Back Button Title")
		if let cred = AuthenticationService.shared.userCredentials() {
			AuthenticationService.shared.isDeviceActivated(cred) { (isActivated, timestamp) in
				if isActivated {
					let nextVC = RegistrationConfirmationViewController()
					nextVC.availableDaysTimeInterval = Double(timestamp)
					self.navigationController?.pushViewController(nextVC, animated: true)
				}
			}
		}
		setupViews()
	}

	override func viewWillAppear(_ animated: Bool) {
		super .viewWillAppear(animated)
		self.navigationController?.isNavigationBarHidden = true
	}

    func presentIntroViewController(_ force: Bool = false, animated: Bool = true) {
        guard let profile = profile else {
            return
        }
        if force || profile.prefs.intForKey(PrefsKeys.IntroSeen) == nil {
            let introViewController = LumenIntroViewController()
            introViewController.delegate = self
            present(introViewController, animated: animated)
        }
    }

	override open var shouldAutorotate: Bool {
		return false
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.backgroundView.snp.remakeConstraints { (make) in
			make.edges.equalToSuperview()
		}
		self.backgroundView.gradient.frame = self.backgroundView.bounds
		if self.emailTextField.isEditing {
			self.contentView.snp.remakeConstraints { (make) in
				make.top.left.right.equalToSuperview()
				make.bottom.equalTo(self.view.snp.bottom).offset(-300)
			}
		} else {
		self.contentView.snp.remakeConstraints { (make) in
			make.top.left.right.equalToSuperview()
			make.bottom.equalTo(self.view.snp.bottom).offset(0)
		}
		}
		self.termsConditionsLabel.snp.remakeConstraints { (make) in
			make.bottom.equalToSuperview().offset(-18)
			make.left.equalToSuperview().offset(29)
			make.right.equalToSuperview().offset(-29)
			make.height.equalTo(33)
		}
		self.nextButton.snp.remakeConstraints { (make) in
			make.left.equalToSuperview().offset(29)
			make.right.equalToSuperview().offset(-29)
			make.bottom.equalTo(self.termsConditionsLabel.snp.top).offset(-12)
			make.height.equalTo(33)
		}
		self.emailTextField.snp.remakeConstraints { (make) in
			make.left.equalToSuperview().offset(29)
			make.right.equalToSuperview().offset(-29)
			make.bottom.equalTo(self.nextButton.snp.top).offset(-15)
			make.height.equalTo(33)
		}
		self.errorLabel.snp.remakeConstraints { (make) in
			make.left.equalToSuperview().offset(97)
			make.right.equalToSuperview().offset(-97)
			make.bottom.equalTo(self.emailTextField.snp.top).offset(-22)
			make.height.equalTo(32)
		}
		self.descriptionLabel.snp.remakeConstraints { (make) in
			make.left.equalToSuperview().offset(29)
			make.right.equalToSuperview().offset(-29)
			make.bottom.equalTo(self.errorLabel.snp.top).offset(-40)
		}
		self.titleLabel.snp.remakeConstraints { (make) in
			make.centerX.equalToSuperview()
			make.bottom.equalTo(self.descriptionLabel.snp.top).offset(-11)
			make.height.equalTo(24)
		}
		self.image.snp.remakeConstraints { (make) in
			make.centerX.equalToSuperview()
			make.bottom.equalTo(self.titleLabel.snp.top).offset(-70)
		}
	}

	@objc
	private func register() {
		self.enableEditing(false)
		if let email = self.emailTextField.text,
			isValidEmail(email) {
			let cred = AuthenticationService.shared.generateNewCredentials(email)
			if let oldCred = AuthenticationService.shared.userCredentials(),
				cred.username != oldCred.username {
				self.askDeletePermissionAndRegister(cred)
			} else {
				registerDevice(cred)
			}
		} else {
			self.enableEditing(true)
			let invalidErrorMessage = NSLocalizedString("Please specify valid email", tableName: "Cliqz", comment: "Invalid email error message")
			showErrorMessage(invalidErrorMessage)
		}
	}

	private func askDeletePermissionAndRegister(_ credentials: UserAuth) {
		let title = NSLocalizedString("Sign in with another account?", tableName: "Lumen", comment: "Alert title")
		let message = NSLocalizedString("This will log you out and all your app data well be deleted.", tableName: "Lumen", comment: "Deletion message")
		let permissionAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		
		let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", tableName: "Cliqz", comment: "[ControlCenter - Trackers list] Cancel action title"), style: .cancel)
		permissionAlert.addAction(cancelAction)
		
		let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", tableName: "Cliqz", comment: ""), style: .default, handler: { [weak self] (alert: UIAlertAction) -> Void in
			self?.tabManager.removeAll()
			self?.clearData()
			self?.registerDevice(credentials)
		})
		permissionAlert.addAction(deleteAction)
		
		self.present(permissionAlert, animated: true, completion: nil)

	}

	private func clearData() {
		if let profile = self.profile {
			var clearables: [Clearable] = [
					HistoryClearable(profile: profile),
					CacheClearable(tabManager: self.tabManager),
					CookiesClearable(tabManager: self.tabManager),
					SiteDataClearable(tabManager: self.tabManager)
				]
			clearables.append(DownloadedFilesClearable())
			for i in clearables {
				let _ = i.clear()
			}
		}
		Engine.sharedInstance.getBridge().callAction(JSBridge.Action.cleanData.rawValue, args: [], callback: { (result) in
			if let error = result["error"] as? [[String: Any]] {
				debugPrint("Error calling action insights:clearData: \(error)")
				//TODO: What should I do in this case?
			}
		})
	}

	private func registerDevice(_ credentials: UserAuth) {
		AuthenticationService.shared.registerDevice(credentials) { (isRegistered, errMessage) in
			self.enableEditing(true)
			if let err = errMessage {
				self.showErrorMessage(err)
			} else if isRegistered {
				let emailActivationVC = EmailVerificationViewController()
				self.navigationController?.pushViewController(emailActivationVC, animated: true)
			}
		}
	}

	private func setupViews() {
		self.view.addSubview(self.backgroundView)
		self.view.addSubview(self.contentView)

		self.image.image = UIImage(named: "logoAuthentication")

		let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
		tap.delegate = self
		contentView.addGestureRecognizer(tap)

		self.contentView.addSubview(self.image)
		self.contentView.addSubview(self.titleLabel)
		self.contentView.addSubview(self.descriptionLabel)
		self.contentView.addSubview(self.errorLabel)
		self.contentView.addSubview(self.emailTextField)
		self.contentView.addSubview(self.nextButton)
		self.contentView.addSubview(self.termsConditionsLabel)

		self.nextButton.setTitle(NSLocalizedString("Next", tableName: "Cliqz", comment: "Next"), for: .normal)
		self.nextButton.backgroundColor = AuthenticationUX.blue
		self.nextButton.layer.cornerRadius = AuthenticationUX.cornerRadius
		self.nextButton.layer.borderWidth = 0
		self.nextButton.layer.masksToBounds = true
		self.nextButton.setTitleColor(UIColor.black, for: .disabled)
		self.nextButton.setTitleColor(AuthenticationUX.textColor, for: .normal)
		self.changeButtonState(false)
		self.nextButton.addTarget(self, action: #selector(register), for: .touchUpInside)

		self.emailTextField.backgroundColor = UIColor.clear
		self.emailTextField.keyboardType = .emailAddress
		self.emailTextField.autocapitalizationType = .none
		self.emailTextField.layer.cornerRadius = AuthenticationUX.cornerRadius
		self.emailTextField.layer.borderWidth = 1
		self.emailTextField.layer.borderColor = AuthenticationUX.blue.cgColor
		self.emailTextField.textColor = AuthenticationUX.blue
		self.emailTextField.layer.masksToBounds = true
		self.emailTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Email", tableName: "Cliqz", comment: "Email"), attributes: [NSAttributedStringKey.foregroundColor: AuthenticationUX.blue])
		self.emailTextField.delegate = self
		self.emailTextField.addTarget(self, action: #selector(emailChanged), for: .editingChanged)

		self.termsConditionsLabel.text = NSLocalizedString("Terms and Conditions", tableName: "Cliqz", comment: "Terms and Conditions")
		self.termsConditionsLabel.textAlignment = .center
		self.termsConditionsLabel.textColor = AuthenticationUX.blue
		self.termsConditionsLabel.font = UIFont.systemFont(ofSize: 11)
		self.termsConditionsLabel.numberOfLines = 2
		self.termsConditionsLabel.isHidden = true

		self.errorLabel.text = ""
		self.errorLabel.textAlignment = .center
		self.errorLabel.textColor = AuthenticationUX.errorColor
		self.errorLabel.font = UIFont.systemFont(ofSize: 14)
		self.errorLabel.numberOfLines = 2
		self.errorLabel.isHidden = true
		
		self.descriptionLabel.text = NSLocalizedString("See the Web in a whole new light with Lumen Browser!", tableName: "Cliqz", comment: "Description")
		self.descriptionLabel.textAlignment = .center
		self.descriptionLabel.textColor = AuthenticationUX.textColor
		self.descriptionLabel.font = AuthenticationUX.subtitleFont
		self.descriptionLabel.numberOfLines = 0

		self.titleLabel.text = NSLocalizedString("Lumen Browser", tableName: "Cliqz", comment: "Lumen Browser")
		self.titleLabel.textAlignment = .center
		self.titleLabel.textColor = AuthenticationUX.textColor
		self.titleLabel.font = AuthenticationUX.titleFont
	}

	private func showErrorMessage(_ message: String) {
		self.errorLabel.text = message
		self.errorLabel.isHidden = false
	}

	private func isValidEmail(_ candidate: String) -> Bool {
		let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
		let pred = NSPredicate(format: "SELF MATCHES %@", emailRegex)
		return pred.evaluate(with: candidate)
	}

	@objc
	private func emailChanged(sender: UITextField) {
		if let email = self.emailTextField.text,
			!email.isEmpty {
			self.changeButtonState(true)
		} else {
			self.changeButtonState(false)
		}
	}

	private func changeButtonState(_ isEnabled: Bool) {
		self.nextButton.isEnabled = isEnabled
		if isEnabled {
			self.nextButton.backgroundColor = AuthenticationUX.blue
		} else {
			self.nextButton.backgroundColor = AuthenticationUX.disabledBlue
		}
	}

	private func enableEditing(_ isEnabled: Bool) {
		changeButtonState(isEnabled)
		emailTextField.isEnabled = isEnabled
	}

	@objc
	func endEditing() {
		self.emailTextField.resignFirstResponder()
	}
}

extension RegistrationViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		self.register()
		return true
	}
	
	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		UIView.animate(withDuration: 0.2) {
			self.image.alpha = 0
			self.contentView.snp.remakeConstraints { (make) in
				make.top.left.right.equalToSuperview()
				make.bottom.equalTo(self.view.snp.bottom).offset(-300)
			}
			self.contentView.layoutIfNeeded()
		}
		return true
	}

	func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
		UIView.animate(withDuration: 0.2) {
			self.image.alpha = 1
			self.contentView.snp.remakeConstraints { (make) in
				make.top.left.right.equalToSuperview()
				make.bottom.equalTo(self.view.snp.bottom).offset(0)
			}
			self.contentView.layoutIfNeeded()
		}
		return true
	}
}

extension UINavigationController {
	
	override open var shouldAutorotate: Bool {
		get {
			if let visibleVC = visibleViewController {
				return visibleVC.shouldAutorotate
			}
			return super.shouldAutorotate
		}
	}
	
	override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation{
		get {
			if let visibleVC = visibleViewController {
				return visibleVC.preferredInterfaceOrientationForPresentation
			}
			return super.preferredInterfaceOrientationForPresentation
		}
	}
	
	override open var supportedInterfaceOrientations: UIInterfaceOrientationMask{
		get {
			if let visibleVC = visibleViewController {
				return visibleVC.supportedInterfaceOrientations
			}
			return super.supportedInterfaceOrientations
		}
	}
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .default
    }
}

extension RegistrationViewController: UIGestureRecognizerDelegate {

	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		if gestureRecognizer is UITapGestureRecognizer {
			if let _ = gestureRecognizer.view as? UIButton {
				return false
			}
			return true
		}
		return false
	}
}

extension RegistrationViewController : IntroViewControllerDelegate {
    func introViewControllerDidFinish(_ introViewController: UIViewController, requestToLogin: Bool) {
        self.profile?.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        introViewController.dismiss(animated: true)
    }
}
