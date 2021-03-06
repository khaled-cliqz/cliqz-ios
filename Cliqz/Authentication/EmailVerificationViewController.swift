//
//  EmailVerificationViewController.swift
//  Client
//
//  Created by Sahakyan on 11/14/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import Foundation
import BondAPI
import SnapKit

class EmailVerificationViewController: UIViewController {

	private let backgroundView = LoginGradientView()

	private let image = UIImageView()
	private let titleLabel = UILabel()
	private let descriptionLabel = UILabel()
	private let resendActivationLinkButton = UIButton(type: .custom)
	private let openEmailButton = UIButton(type: .custom)

	private var timer: Timer?
	private let credentials = AuthenticationService.shared.userCredentials()!

	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationController?.isNavigationBarHidden = false
		self.navigationController?.navigationBar.barTintColor = AuthenticationUX.backgroundDarkGradientStart
		self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
		self.navigationController?.navigationBar.tintColor = UIColor(rgb: 0xB2B8FF)
		self.timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(checkActivation), userInfo: nil, repeats: true)
		self.timer?.fire()
		self.setupViews()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.backgroundView.snp.remakeConstraints { (make) in
			make.edges.equalToSuperview()
		}
		self.backgroundView.gradient.frame = self.backgroundView.bounds

		self.openEmailButton.snp.remakeConstraints { (make) in
			make.left.equalToSuperview().offset(29)
			make.right.equalToSuperview().offset(-29)
			make.bottom.equalToSuperview().offset(-63)
			make.height.equalTo(33)
		}
		self.resendActivationLinkButton.snp.remakeConstraints { (make) in
			make.left.equalToSuperview().offset(29)
			make.right.equalToSuperview().offset(-29)
			make.bottom.equalTo(self.openEmailButton.snp.top).offset(-15)
			make.height.equalTo(33)
		}
		self.descriptionLabel.snp.remakeConstraints { (make) in
			make.left.equalToSuperview().offset(29)
			make.right.equalToSuperview().offset(-29)
			make.bottom.equalTo(self.resendActivationLinkButton.snp.top).offset(-40)
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

	override open var shouldAutorotate: Bool {
		return false
	}
	
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}

	private func setupViews() {
		self.view.addSubview(self.backgroundView)
		self.view.addSubview(self.image)
		self.view.addSubview(self.titleLabel)
		self.view.addSubview(self.descriptionLabel)
		self.view.addSubview(self.resendActivationLinkButton)
		self.view.addSubview(self.openEmailButton)

		self.image.image = UIImage(named: "circleAuthentication")
		self.animateImage()

		self.titleLabel.text = NSLocalizedString("Your account is almost ready!", tableName: "Cliqz", comment: "")
		self.titleLabel.textAlignment = .center
		self.titleLabel.textColor = AuthenticationUX.textColor
		self.titleLabel.font = AuthenticationUX.titleFont

		self.descriptionLabel.text = NSLocalizedString("We just sent you an activation link. Please check your inbox and open the link to confirm your account.", tableName: "Cliqz", comment: "Next")
		self.descriptionLabel.textAlignment = .center
		self.descriptionLabel.textColor = AuthenticationUX.textColor
		self.descriptionLabel.font = AuthenticationUX.subtitleFont
		self.descriptionLabel.numberOfLines = 0

		self.resendActivationLinkButton.setTitle(NSLocalizedString("Resend Activation Link", tableName: "Cliqz", comment: ""), for: .normal)
		self.resendActivationLinkButton.backgroundColor = UIColor.clear
		self.resendActivationLinkButton.layer.cornerRadius = AuthenticationUX.cornerRadius
		self.resendActivationLinkButton.layer.borderWidth = 1
		self.resendActivationLinkButton.layer.masksToBounds = true
		self.resendActivationLinkButton.layer.borderColor = AuthenticationUX.blue.cgColor
		self.resendActivationLinkButton.setTitleColor(AuthenticationUX.blue, for: .normal)
		self.resendActivationLinkButton.addTarget(self, action: #selector(resendActivationLink), for: .touchUpInside)

		self.openEmailButton.setTitle(NSLocalizedString("Open Mail App", tableName: "Cliqz", comment: "Next"), for: .normal)
		self.openEmailButton.backgroundColor = AuthenticationUX.blue
		self.openEmailButton.layer.cornerRadius = AuthenticationUX.cornerRadius
		self.openEmailButton.layer.borderWidth = 0
		self.openEmailButton.layer.masksToBounds = true
		self.openEmailButton.addTarget(self, action: #selector(openEmailApp), for: .touchUpInside)
	}

	@objc
	private func checkActivation() {
		AuthenticationService.shared.isDeviceActivated(self.credentials) { [weak self] (isActivated,
			timestamp) in
			if isActivated {
				self?.timer?.invalidate()
				let nextVC = RegistrationConfirmationViewController()
				nextVC.availableDaysTimeInterval = Double(timestamp)
				self?.navigationController?.pushViewController(nextVC, animated: true)
			}
		}
	}

	@objc
	private func openEmailApp() {
		if let url = URL(string: "message://"),
			UIApplication.shared.canOpenURL(url) {
			UIApplication.shared.open(url)
		}
	}
	
	@objc
	private func resendActivationLink(sender: UIButton) {
		AuthenticationService.shared.resendActivationEmail(credentials) { (isSent) in
			print("Succes")
		}
		self.showAlertView()
	}

	private func showAlertView() {
		let title = NSLocalizedString("Activation Link Resent", tableName: "Cliqz", comment: "Alert title")
		let message = NSLocalizedString("We resent the activation link. Please check your inbox and your spam folder.", tableName: "Cliqz", comment: "Activation message")
		let linkSent = UIAlertController(title: title, message: message, preferredStyle: .alert)
		
		let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", tableName: "Cliqz", comment: "[ControlCenter - Trackers list] Cancel action title"), style: .cancel)
		linkSent.addAction(cancelAction)
		
		let openMail = UIAlertAction(title: NSLocalizedString("Open Mail", tableName: "Cliqz", comment: ""), style: .default, handler: { [weak self] (alert: UIAlertAction) -> Void in
			self?.openEmailApp()
		})
		linkSent.addAction(openMail)
		
		self.present(linkSent, animated: true, completion: nil)
	}

	private func animateImage() {
		let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
		rotation.toValue = NSNumber(value: Double.pi * 2)
		rotation.duration = 1
		rotation.isCumulative = true
		rotation.repeatCount = Float.greatestFiniteMagnitude
		self.image.layer.add(rotation, forKey: "rotationAnimation")
	}
}
