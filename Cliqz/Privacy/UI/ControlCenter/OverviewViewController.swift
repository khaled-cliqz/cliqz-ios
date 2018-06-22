//
//  OverviewViewController.swift
//  Client
//
//  Created by Sahakyan on 4/17/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import Foundation
import Charts

protocol NotchViewDelegate: class {
    func switchValueChanged(value: Bool)
	func viewIsDragging(value: Float, velocity: Float)
	func viewStopDragging(value: Float)
}

class NotchView: UIView {

	private var notchView = UIImageView()
	private var iconView = UIImageView()
	private var countLabel = UILabel()
	private var titleLabel = UILabel()
	private var switchControl = UISwitch()
	private var descriptionLabel = UILabel()

    weak var delegate: NotchViewDelegate? = nil

	var isSwitchOn: Bool? {
		set {
			DispatchQueue.main.async {
				self.switchControl.isOn = newValue ?? false
				self.switchValueChanged(s: self.switchControl)
			}
		}
		get {
			return switchControl.isOn
		}
	}

	var count: Int? {
		didSet {
			// Disabled for now, fixed text will be shown till we have a solution for the count
//			countLabel.text = "\(count ?? 0)"
		}
	}

	var title: String? {
		didSet {
			titleLabel.text = title
		}
	}

	var iconName: String? {
		set {
			if let name = newValue {
				self.iconView.image = UIImage(named: name)
			}
		}
		get {
			return nil
		}
	}

	init() {
		super.init(frame: CGRect.zero)
		self.addSubview(notchView)
		self.addSubview(iconView)
		self.addSubview(countLabel)
		self.addSubview(titleLabel)
		self.addSubview(descriptionLabel)
		self.addSubview(switchControl)
		let gesture = UIPanGestureRecognizer(target: self, action: #selector(wasDragged))
		self.addGestureRecognizer(gesture)
		self.isUserInteractionEnabled = true
		setStyles()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func setStyles() {
		titleLabel.textColor = UIColor.cliqzBluePrimary
		titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
		switchControl.onTintColor = UIColor.cliqzBluePrimary
		switchControl.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        switchControl.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
		notchView.image = UIImage(named:"notch")
		descriptionLabel.textColor = UIColor.cliqzGrayFunctional
		descriptionLabel.font = UIFont.systemFont(ofSize: 12)
		descriptionLabel.numberOfLines = 0
		descriptionLabel.text = NSLocalizedString("Enhanced Ad Blocking anonymizes unblocked and unknown trackers for greater browsing protection.", tableName: "Cliqz", comment: "[ControlCenter -> Overview] Ad Blocking description")
		descriptionLabel.textAlignment = .left
		countLabel.textColor = UIColor.cliqzBluePrimary
		countLabel.text = NSLocalizedString("Ads Removed", tableName: "Cliqz", comment: "[ControlCenter -> Overview] Removed Ads indicator")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.notchView.snp.remakeConstraints { (make) in
			make.top.left.right.equalToSuperview()
			make.height.equalTo(30)
		}
		self.titleLabel.snp.remakeConstraints { (make) in
			make.left.equalToSuperview().offset(20)
			make.top.equalTo(self.notchView.snp.bottom)
			make.height.equalTo(25)
		}
		self.iconView.snp.remakeConstraints { (make) in
			make.top.equalTo(titleLabel.snp.bottom).offset(30)
			make.centerX.equalToSuperview()
		}
		self.countLabel.snp.remakeConstraints { (make) in
			make.top.equalTo(self.iconView.snp.bottom).offset(10)
			make.centerX.equalTo(self)
			make.height.equalTo(25)
		}
		self.switchControl.snp.remakeConstraints { (make) in
			make.top.equalTo(self.notchView.snp.bottom)
			make.height.equalTo(25)
			make.right.equalTo(self).inset(10)
		}
		self.descriptionLabel.snp.remakeConstraints { (make) in
			make.bottom.equalToSuperview().inset(25)
			make.left.right.equalToSuperview().inset(20)
		}
	}

    @objc func switchValueChanged(s: UISwitch) {
        s.isOn ? self.delegate?.switchValueChanged(value: true) : self.delegate?.switchValueChanged(value: false)
		updateViewStyle(enabled: s.isOn)
    }

	@objc func wasDragged(gestureRecognizer: UIPanGestureRecognizer) {
		if gestureRecognizer.state == UIGestureRecognizerState.began || gestureRecognizer.state == UIGestureRecognizerState.changed {
			let translation = gestureRecognizer.translation(in: self)
			self.delegate?.viewIsDragging(value: Float(translation.y), velocity: Float(gestureRecognizer.velocity(in: self).y))
		}
		if gestureRecognizer.state == UIGestureRecognizerState.ended {
			self.delegate?.viewStopDragging(value: Float(gestureRecognizer.velocity(in: self).y))
		}
	}

	private func updateViewStyle(enabled isEnabled: Bool) {
		if isEnabled {
			iconView.tintColor = UIColor.cliqzBluePrimary
			countLabel.textColor = UIColor.cliqzBluePrimary
		} else {
			iconView.tintColor = UIColor.gray
			countLabel.textColor = UIColor.gray
		}
	}

}

struct ControlCenterUX {
	static let adblockerViewMaxHeight: Float = 280
	static let adblockerViewInitialOffset: Float = -85
}

class OverviewViewController: UIViewController {
	private var chart: PieChartView!

	private var urlLabel: UILabel = UILabel()
	private var blockedTrackers = UILabel()

	private var trustSiteButton = UIButton(type: .custom)
	private var restrictSiteButton = UIButton(type: .custom)
	private var pauseGhosteryButton = UIButton(type: .custom)

	fileprivate var adBlockingView = NotchView()

	weak var dataSource: ControlCenterDSProtocol? {
		didSet {
			updateData()
		}
	}
	weak var delegate: ControlCenterDelegateProtocol? {
		didSet {
			updateData()
		}
	}

	var categories = [String: [TrackerListApp]]() {
		didSet {
			self.updateData()
		}
	}

	var pageURL: String = "" {
		didSet {
			self.urlLabel.text = pageURL
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		self.setupComponents()
		self.setComponentsStyles()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.updateData()
	}

	private func updateData() {
        guard let datasource = self.dataSource else { return }
	
		self.urlLabel.text = datasource.domainString()
        
        updateChart()
        updateBlockedTrackersCount()
        
		let domainState = datasource.domainState()
		if domainState == .trusted {
			setTrustSite(true)
		} else if domainState == .restricted {
			setRestrictSite(true)
		}
        else {
            setSiteToNone()
        }
		setPauseGhostery(datasource.isGhosteryPaused())
	}

	private func setupComponents() {
		self.setupPieChart()
        
        self.view.addSubview(chart)
        self.view.addSubview(urlLabel)
        self.view.addSubview(blockedTrackers)
        self.view.addSubview(trustSiteButton)
        self.view.addSubview(restrictSiteButton)
        self.view.addSubview(pauseGhosteryButton)
        self.view.addSubview(adBlockingView)
        
        let (device,orientation) = UIDevice.current.getDeviceAndOrientation()
        
        if (orientation == .portrait && device != .iPad) || device == .iPad {
            chart.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
				if UIDevice.current.isSmallIphoneDevice() {
					make.top.equalToSuperview()
					make.height.equalTo(160)
				} else {
					make.top.equalToSuperview().offset(5)
					make.height.equalTo(220)
				}
            }
            
            self.urlLabel.snp.makeConstraints { (make) in
				make.left.right.equalTo(self.view).inset(7)
				make.top.equalTo(chart.snp.bottom)
                make.height.equalTo(17)
            }
            
            self.blockedTrackers.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.view)
				make.top.equalTo(self.urlLabel.snp.bottom)
                make.height.equalTo(30)
            }

            self.trustSiteButton.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.view)
				make.bottom.equalTo(self.restrictSiteButton.snp.top).offset(-12)
                make.height.equalTo(40)
                make.width.equalTo(213)
            }

            self.restrictSiteButton.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.view)
				if UIDevice.current.isSmallIphoneDevice() {
					make.bottom.equalTo(self.pauseGhosteryButton.snp.top).offset(-20)
				} else {
					make.bottom.equalTo(self.pauseGhosteryButton.snp.top).offset(-30)
				}
                make.height.equalTo(40)
                make.width.equalTo(213)
            }
            
            self.pauseGhosteryButton.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.view)
				make.bottom.equalToSuperview().offset(ControlCenterUX.adblockerViewInitialOffset)
                make.height.equalTo(40)
                make.width.equalTo(213)
            }
            
            self.adBlockingView.snp.makeConstraints { (make) in
                make.left.right.equalTo(self.view)
				make.top.equalTo(self.view.snp.bottom).offset(ControlCenterUX.adblockerViewInitialOffset)
                make.height.equalTo(ControlCenterUX.adblockerViewMaxHeight)
            }
        } else {
            let blockedTrackersOffset: CGFloat = 10.0
            let adblockingViewOffset: CGFloat = 75.0
            
            chart.snp.makeConstraints { (make) in
                let inset = self.blockedTrackers.intrinsicContentSize.height + self.urlLabel.intrinsicContentSize.height + blockedTrackersOffset + adblockingViewOffset
                make.top.equalToSuperview()
                make.height.equalToSuperview().offset(-inset)
                make.left.equalToSuperview()
                make.width.equalToSuperview().dividedBy(2)
            }
            
            self.urlLabel.snp.makeConstraints { (make) in
                make.left.equalTo(self.view).inset(7)
                make.right.equalToSuperview().dividedBy(2)
                make.top.equalTo(chart.snp.bottom).offset(2)
            }
            
            self.blockedTrackers.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.urlLabel.snp.centerX)
                make.top.equalTo(self.urlLabel.snp.bottom).offset(blockedTrackersOffset)
            }
            
            self.trustSiteButton.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.view).multipliedBy(1.5)
                make.top.equalToSuperview().offset(36)
                make.height.equalTo(30)
                make.width.equalTo(self.view.snp.width).dividedBy(2.3)
            }
            
            self.restrictSiteButton.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.view).multipliedBy(1.5)
                make.top.equalTo(self.trustSiteButton.snp.bottom).offset(10)
                make.height.equalTo(30)
                make.width.equalTo(self.view.snp.width).dividedBy(2.3)
            }
            
            self.pauseGhosteryButton.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.view).multipliedBy(1.5)
                make.top.equalTo(self.restrictSiteButton.snp.bottom).offset(10)
                make.height.equalTo(30)
                make.width.equalTo(self.view.snp.width).dividedBy(2.3)
            }
            
            self.adBlockingView.snp.makeConstraints { (make) in
                make.left.right.equalTo(self.view)
                make.top.equalTo(self.view.snp.bottom).offset(-adblockingViewOffset)
                make.height.equalTo(150)
            }
        }
        
		let trustTitle = NSLocalizedString("Trust Site", tableName: "Cliqz", comment: "[ControlCenter -> Overview] Trust button title")
		self.trustSiteButton.setTitle(trustTitle, for: .normal)
		self.trustSiteButton.addTarget(self, action: #selector(trustSitePressed), for: .touchUpInside)

		let restrictTitle = NSLocalizedString("Restrict Site", tableName: "Cliqz", comment: "[ControlCenter -> Overview] Restrict button title")
		self.restrictSiteButton.setTitle(restrictTitle, for: .normal)
		self.restrictSiteButton.addTarget(self, action: #selector(restrictSitePressed), for: .touchUpInside)

		let pauseGhostery = NSLocalizedString("Pause Ghostery", tableName: "Cliqz", comment: "[ControlCenter -> Overview] Pause Ghostery button title")
		self.pauseGhosteryButton.setTitle(pauseGhostery, for: .normal)
        self.pauseGhosteryButton.addTarget(self, action: #selector(pauseGhosteryPressed), for: .touchUpInside)
        self.pauseGhosteryButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)

		// TODO: Count should be from DataSource
        self.adBlockingView.delegate = self
		self.adBlockingView.count = 0
		self.adBlockingView.title = NSLocalizedString("Enhanced Ad Blocking", tableName: "Cliqz", comment: "[ControlCenter -> Overview] Ad blocking switch title")
		self.adBlockingView.isSwitchOn = self.dataSource?.isGlobalAdblockerOn()
		self.adBlockingView.iconName = "adblocking"
		self.adBlockingView.backgroundColor = UIColor.white
	}

	private func setComponentsStyles() {
		chart.backgroundColor = NSUIColor.clear

		self.urlLabel.font = UIFont.systemFont(ofSize: 13)
		self.urlLabel.textAlignment = .center

		self.blockedTrackers.font = UIFont.systemFont(ofSize: 20)

		self.trustSiteButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
		self.trustSiteButton.backgroundColor = UIColor.white
		self.trustSiteButton.layer.borderColor = ControlCenterUI.buttonGray.cgColor
		self.trustSiteButton.layer.borderWidth = 1
		self.trustSiteButton.layer.cornerRadius = 3
		self.trustSiteButton.setTitleColor(UIColor.white, for: .selected)
		self.trustSiteButton.setTitleColor(ControlCenterUI.buttonGray, for: .normal)
		self.trustSiteButton.setImage(UIImage(named: "trust"), for: .normal)
		self.trustSiteButton.setImage(UIImage(named: "trustAction"), for: .selected)
		self.trustSiteButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
		self.trustSiteButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);

		self.restrictSiteButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
		self.restrictSiteButton.backgroundColor = UIColor.white
		self.restrictSiteButton.layer.borderColor = ControlCenterUI.buttonGray.cgColor
		self.restrictSiteButton.layer.borderWidth = 1
		self.restrictSiteButton.layer.cornerRadius = 3
		self.restrictSiteButton.setTitleColor(ControlCenterUI.buttonGray, for: .normal)
		self.restrictSiteButton.setTitleColor(UIColor.white, for: .selected)
		self.restrictSiteButton.setImage(UIImage(named: "restrict"), for: .normal)
		self.restrictSiteButton.setImage(UIImage(named: "restrictAction"), for: .selected)
		self.restrictSiteButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
		self.restrictSiteButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);

		self.pauseGhosteryButton.backgroundColor = UIColor.white
		self.pauseGhosteryButton.layer.borderColor = ControlCenterUI.buttonGray.cgColor
		self.pauseGhosteryButton.layer.borderWidth = 1
		self.pauseGhosteryButton.layer.cornerRadius = 3
		self.pauseGhosteryButton.setTitleColor(ControlCenterUI.buttonGray, for: .normal)
		self.pauseGhosteryButton.setTitleColor(UIColor.white, for: .selected)
		self.pauseGhosteryButton.setImage(UIImage(named: "ghosteryPause"), for: .normal)
		self.pauseGhosteryButton.setImage(UIImage(named: "ghosteryPlay"), for: .selected)
		self.pauseGhosteryButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
		self.pauseGhosteryButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
	}
    
    private func showPauseActionSheet() {
        
        let pauseAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let thirty = UIAlertAction(title: NSLocalizedString("30 minutes", tableName: "Cliqz", comment: "[ControlCenter - Overview] Pause Ghostery for thirty minutes title"), style: .default, handler: { [weak self] (alert: UIAlertAction) -> Void in
            let time = Date(timeIntervalSinceNow: 30 * 60)
            self?.pauseGhostery(time)
        })
        pauseAlertController.addAction(thirty)
        
        let onehour = UIAlertAction(title: NSLocalizedString("1 hour", tableName: "Cliqz", comment: "[ControlCenter - Overview] Pause Ghostery for one hour title"), style: .default, handler: { [weak self] (alert: UIAlertAction) -> Void in
            let time = Date(timeIntervalSinceNow: 60 * 60)
            self?.pauseGhostery(time)
        })
        pauseAlertController.addAction(onehour)
        
        let twentyfour = UIAlertAction(title: NSLocalizedString("24 hours", tableName: "Cliqz", comment: "[ControlCenter - Overview] Pause Ghostery for twentyfour hours title"), style: .default, handler: { [weak self] (alert: UIAlertAction) -> Void in
            let time = Date(timeIntervalSinceNow: 24 * 60 * 60)
            self?.pauseGhostery(time)
        })
        pauseAlertController.addAction(twentyfour)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", tableName: "Cliqz", comment: "[ControlCenter - Trackers list] Cancel action title"), style: .cancel)
        pauseAlertController.addAction(cancelAction)
        
        if let popover = pauseAlertController.popoverPresentationController {
            popover.sourceView = pauseGhosteryButton
            popover.permittedArrowDirections = .down
            popover.sourceRect = CGRect(x: pauseGhosteryButton.bounds.width/2, y: 0, width: 0, height: 0)
        }
        
        self.present(pauseAlertController, animated: true, completion: nil)
    }
    
    @objc private func pauseGhosteryPressed() {
        if self.pauseGhosteryButton.isSelected { //already paused
            //resume
            self.delegate?.pauseGhostery(paused: false, time: Date())
            self.setPauseGhostery(!self.pauseGhosteryButton.isSelected)
            TelemetryHelper.sendControlCenterResumeClick()
        }
        else {
            //pause
            showPauseActionSheet()
        }
    }
    
    func pauseGhostery(_ time: Date) {
        self.delegate?.pauseGhostery(paused: true, time: time)
        self.setPauseGhostery(!self.pauseGhosteryButton.isSelected)
        self.delegate?.chageSiteState(to: .empty)
        setSiteToNone()
        TelemetryHelper.sendControlCenterPauseClick()
    }

	@objc private func trustSitePressed() {
		setTrustSite(!self.trustSiteButton.isSelected)
        self.trustSiteButton.isSelected ? self.delegate?.chageSiteState(to: .trusted) : self.delegate?.chageSiteState(to: .empty)
        self.delegate?.pauseGhostery(paused: false, time: Date())
        self.setPauseGhostery(false)
        updateBlockedTrackersCount()
        TelemetryHelper.sendControlCenterTrustClick()
	}

	@objc private func restrictSitePressed() {
		setRestrictSite(!self.restrictSiteButton.isSelected)
        self.restrictSiteButton.isSelected ? self.delegate?.chageSiteState(to: .restricted) : self.delegate?.chageSiteState(to: .empty)
        self.delegate?.pauseGhostery(paused: false, time: Date())
        self.setPauseGhostery(false)
        updateBlockedTrackersCount()
        TelemetryHelper.sendControlCenterRestrictClick()
	}
    
    private func setPauseGhostery(_ value: Bool) {
        self.pauseGhosteryButton.isSelected = value
        updatePauseGhosteryUI()
        updateBlockedTrackersCount()
        updateChart()
    }
    
    private func setTrustSite(_ value: Bool) {
        self.trustSiteButton.isSelected = value
        self.restrictSiteButton.isSelected = false
        updateTrustSiteUI()
        updateRestrictSiteUI()
    }
    
    private func setRestrictSite(_ value: Bool) {
        self.restrictSiteButton.isSelected = value
        self.trustSiteButton.isSelected = false
        updateTrustSiteUI()
        updateRestrictSiteUI()
    }
    
    private func setSiteToNone() {
        self.trustSiteButton.isSelected = false
        self.restrictSiteButton.isSelected = false
        updateTrustSiteUI()
        updateRestrictSiteUI()
    }
    
    private func updatePauseGhosteryUI() {
        if self.pauseGhosteryButton.isSelected {
            self.pauseGhosteryButton.setTitle(NSLocalizedString("Resume", tableName: "Cliqz", comment: "[ControlCenter -> Overview] Resume Ghostery button title"), for: .normal)
            self.pauseGhosteryButton.backgroundColor = UIColor.cliqzBluePrimary
        }
        else {
            self.pauseGhosteryButton.setTitle(NSLocalizedString("Pause Ghostery", tableName: "Cliqz", comment: "[ControlCenter -> Overview] Pause Ghostery button title"), for: .normal)
            self.pauseGhosteryButton.backgroundColor = UIColor.white
        }
    }
    
    private func updateTrustSiteUI() {
        if self.trustSiteButton.isSelected {
            self.trustSiteButton.backgroundColor = UIColor.cliqzGreenLightFunctional
        } else {
            self.trustSiteButton.backgroundColor = UIColor.white
        }
    }
    
    private func updateRestrictSiteUI() {
        if self.restrictSiteButton.isSelected {
            self.restrictSiteButton.backgroundColor = UIColor(colorString: "BE4948")
        } else {
            self.restrictSiteButton.backgroundColor = UIColor.white
        }
    }
    
    private func updateBlockedTrackersCount() {
        blockedTrackers.text = String(format: NSLocalizedString("%d Tracker(s) Blocked", tableName: "Cliqz", comment: "[ControlCenter -> Overview] Blocked trackers count"), self.dataSource?.blockedTrackerCount() ?? 0)
    }
    
    private func updateChart() {
        guard let datasource = self.dataSource else { return }
        let countsAndColors = datasource.countAndColorByCategory()
        var values: [PieChartDataEntry] = []
        var colors: [UIColor] = []
        for key in countsAndColors.keys {
            if let touple = countsAndColors[key] {
                values.append(PieChartDataEntry(value: Double(touple.0), label: ""))
                colors.append(touple.1)
            }
        }
        let dataSet = PieChartDataSet(values: values, label: "")
        dataSet.drawIconsEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.iconsOffset = CGPoint(x: 0, y: 20.0)
        dataSet.colors = colors
        chart?.data = PieChartData(dataSet: dataSet)
        chart?.centerText = String(format: NSLocalizedString("%d Tracker(s) found", tableName: "Cliqz", comment: "[ControlCenter -> Overview] Detected trackers count"), self.dataSource?.detectedTrackerCount() ?? 0)
    }

	private func setupPieChart() {
		chart = PieChartView()
		chart.chartDescription?.text = ""
		chart.legend.enabled = false
		chart.holeRadiusPercent = 0.8
	}
}

extension OverviewViewController: NotchViewDelegate {

    func switchValueChanged(value: Bool) {
        self.delegate?.turnGlobalAdblocking(on: value)
	}

	func viewIsDragging(value: Float, velocity: Float) {
		self.adBlockingView.snp.updateConstraints { (make) in
			// TODO: Some more improvements should be done when direction is changed quickly...
			if velocity < 0 {
				if value + ControlCenterUX.adblockerViewInitialOffset < -ControlCenterUX.adblockerViewMaxHeight {
					make.top.equalTo(self.view.snp.bottom).offset(-ControlCenterUX.adblockerViewMaxHeight)
				} else {
					make.top.equalTo(self.view.snp.bottom).offset(value + ControlCenterUX.adblockerViewInitialOffset)
				}
			} else {
				make.top.equalTo(self.view.snp.bottom).offset(value - ControlCenterUX.adblockerViewMaxHeight)
			}
		}
	}

	func viewStopDragging(value: Float) {
		if value > 0 {
			self.adBlockingView.snp.updateConstraints { (make) in
				make.top.equalTo(self.view.snp.bottom).offset(ControlCenterUX.adblockerViewInitialOffset)
			}
		} else {
			self.adBlockingView.snp.updateConstraints { (make) in
				make.top.equalTo(self.view.snp.bottom).offset(-ControlCenterUX.adblockerViewMaxHeight)
			}
		}
	}
}