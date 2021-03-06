/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Shared
import Storage
import Deferred

extension UIStackView {
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }

    func rightLeftEdges(inset: CGFloat) {
        layoutMargins = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        isLayoutMarginsRelativeArrangement = true
    }
}

extension UILabel {
    // Ensures labels can span a second line and will compress to fit text
    func handleLongLabels() {
        numberOfLines = 2
        adjustsFontSizeToFitWidth = true
        allowsDefaultTighteningForTruncation = true
    }
}

// Credit: https://stackoverflow.com/a/48860391/490488
extension String {
    static var quotes: (String, String) {
        guard
            let bQuote = Locale.current.quotationBeginDelimiter,
            let eQuote = Locale.current.quotationEndDelimiter
            else { return ("“", "”") }

        return (bQuote, eQuote)
    }

    var quoted: String {
        let (bQuote, eQuote) = String.quotes
        return bQuote + self + eQuote
    }
}

protocol ShareControllerDelegate: AnyObject {
    func finish(afterDelay: TimeInterval)
    func getValidExtensionContext() -> NSExtensionContext?
    func hidePopupWhenShowingAlert()
}

// Telemetry events are written to NSUserDefaults, and then the host app reads and clears this list.
func addAppExtensionTelemetryEvent(forMethod method: String) {
    let profile = BrowserProfile(localName: "profile")
    var events = profile.prefs.arrayForKey(PrefsKeys.AppExtensionTelemetryEventArray) ?? [[String]]()
    // Currently, only URL objects are shared.
    let event = ["method": method, "object": "url"]
    events.append(event)
    profile.prefs.setObject(events, forKey: PrefsKeys.AppExtensionTelemetryEventArray)
}

class ShareViewController: UIViewController {
    var shareItem: ExtensionUtils.ExtractedShareItem?
    private var viewsShownDuringDoneAnimation = [UIView]()
    private var stackView: UIStackView!
    private var actionDoneRow: (row: UIStackView, label: UILabel)!
    private var sendToDevice: SendToDevice?
    private var pageInfoHeight: Constraint?
    private var actionRowHeights = [Constraint]()
    private var pageInfoRowTitleLabel: UILabel?
    private var pageInfoRowUrlLabel: UILabel?

    weak var delegate: ShareControllerDelegate?

    override var extensionContext: NSExtensionContext? {
        get {
            return delegate?.getValidExtensionContext()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        setupNavBar()
        setupStackView()

        guard let shareItem = shareItem else { return }

        self.setupRows()

        switch shareItem {
        case .shareItem(let item):
            self.pageInfoRowUrlLabel?.text = item.url
            self.pageInfoRowTitleLabel?.text = item.title
        case .rawText(let text):
            self.pageInfoRowTitleLabel?.text = text.quoted
        }
    }

    private func setupRows() {
        let pageInfoRow = makePageInfoRow(addTo: stackView)
        pageInfoRowTitleLabel = pageInfoRow.pageTitleLabel
        pageInfoRowUrlLabel = pageInfoRow.urlLabel
        makeSeparator(addTo: stackView)

        // Cliqz: Add strings localized strings
        //start
        let ShareOpenInCliqz = CliqzStrings.ShareOpenInCliqz
        let AppMenuAddFavoriteTitleString = NSLocalizedString("Menu.AddFavoriteAction.Title", tableName: "Cliqz", value: "Add to Favorites", comment: "Label for the button, displayed in the menu, used to create a favorite for the current website.")
        let ShareSearchInCliqz = CliqzStrings.ShareSearchInCliqz
        //end
 
        if shareItem?.isUrlType() ?? true {
            /* Cliqz: Modify these actions
            makeActionRow(addTo: stackView, label: Strings.ShareOpenInFirefox, imageName: "open-in-firefox", action: #selector(actionOpenInFirefoxNow), hasNavigation: false)
            makeActionRow(addTo: stackView, label: Strings.ShareLoadInBackground, imageName: "menu-Show-Tabs", action: #selector(actionLoadInBackground), hasNavigation: false)
            makeActionRow(addTo: stackView, label: Strings.ShareBookmarkThisPage, imageName: "AddToBookmarks", action: #selector(actionBookmarkThisPage), hasNavigation: false)
            makeActionRow(addTo: stackView, label: Strings.ShareAddToReadingList, imageName: "AddToReadingList", action: #selector(actionAddToReadingList), hasNavigation: false)
            makeSeparator(addTo: stackView)
            makeActionRow(addTo: stackView, label: Strings.ShareSendToDevice, imageName: "menu-Send-to-Device", action: #selector(actionSendToDevice), hasNavigation: true)
            */
            makeActionRow(addTo: stackView, label: ShareOpenInCliqz, imageName: "open-in-firefox", action: #selector(actionOpenInFirefoxNow), hasNavigation: false)
            makeSeparator(addTo: stackView)
            makeActionRow(addTo: stackView, label: Strings.ShareLoadInBackground, imageName: "menu-Show-Tabs", action: #selector(actionLoadInBackground), hasNavigation: false)
            makeSeparator(addTo: stackView)
            makeActionRow(addTo: stackView, label: AppMenuAddFavoriteTitleString, imageName: "AddToBookmarks", action: #selector(actionBookmarkThisPage), hasNavigation: false)
        } else {
            pageInfoRowUrlLabel?.removeFromSuperview()
            makeActionRow(addTo: stackView, label: ShareSearchInCliqz, imageName: "quickSearch", action: #selector(actionSearchInFirefox), hasNavigation: false)
        }

        let footerSpaceRow = UIView()
        stackView.addArrangedSubview(footerSpaceRow)
        // Without some growable space at the bottom there are constraint errors because the UIView space doesn't subdivide equally, and none of the rows are growable.
        // Also, during the animation to the done state, without this space, the page info label moves down slightly.
        footerSpaceRow.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(0)
        }

        actionDoneRow = makeActionDoneRow(addTo: stackView)
        // Fully constructing and pre-adding as a subview ensures that only the show operation will animate during the UIView.animate(),
        // and other animatable properties will not unexpectedly animate because they are modified in the same event loop as the animation.
        actionDoneRow.row.isHidden = true

        // All other views are hidden for the done animation.
        viewsShownDuringDoneAnimation += [pageInfoRow.row, footerSpaceRow, actionDoneRow.row]
    }

    private func makeSeparator(addTo parent: UIStackView) {
        let view = UIView()
        view.backgroundColor = UX.separatorColor
        parent.addArrangedSubview(view)
        view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    func layout(forTraitCollection traitCollection: UITraitCollection) {
        let isSearchMode = !(shareItem?.isUrlType() ?? true) // Dialog doesn't change size in search mode
        if !UX.enableResizeRowsForSmallScreens || isSearchMode {
            return
        }

        pageInfoHeight?.update(offset: isLandscapeSmallScreen(traitCollection) ? UX.pageInfoRowHeight - UX.perRowShrinkageForLandscape : UX.pageInfoRowHeight)
        actionRowHeights.forEach {
            $0.update(offset: isLandscapeSmallScreen(traitCollection) ? UX.actionRowHeight - UX.perRowShrinkageForLandscape : UX.actionRowHeight)
        }
    }

    private func makePageInfoRow(addTo parent: UIStackView) -> (row: UIStackView, pageTitleLabel: UILabel, urlLabel: UILabel) {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.rightLeftEdges(inset: UX.rowInset)
        parent.addArrangedSubview(row)
        row.snp.makeConstraints { make in
            pageInfoHeight = make.height.equalTo(isLandscapeSmallScreen(traitCollection) ? UX.pageInfoRowHeight - UX.perRowShrinkageForLandscape : UX.pageInfoRowHeight).constraint
        }

        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = UX.pageInfoLineSpacing

        row.addArrangedSubview(verticalStackView)

        let pageTitleLabel = UILabel()
        let urlLabel = UILabel()
        [pageTitleLabel, urlLabel].forEach { label in
            verticalStackView.addArrangedSubview(label)
            label.allowsDefaultTighteningForTruncation = true
            label.lineBreakMode = .byTruncatingMiddle
            label.font = UX.baseFont
        }

        pageTitleLabel.font = UIFont.boldSystemFont(ofSize: UX.baseFont.pointSize)

        return (row, pageTitleLabel, urlLabel)
    }

    private func makeActionRow(addTo parent: UIStackView, label: String, imageName: String, action: Selector, hasNavigation: Bool) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = UX.actionRowSpacingBetweenIconAndTitle
        row.rightLeftEdges(inset: UX.rowInset)
        parent.addArrangedSubview(row)
        row.snp.makeConstraints { make in
            let c = make.height.equalTo(isLandscapeSmallScreen(traitCollection) ? UX.actionRowHeight - UX.perRowShrinkageForLandscape : UX.actionRowHeight).constraint
            actionRowHeights.append(c)
        }

        let icon = UIImageView(image: UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate))
        icon.contentMode = .scaleAspectFit
        icon.tintColor = UX.actionRowTextAndIconColor
        
        /*Cliqz: Change title
        let title = UILabel()
        title.font = UX.baseFont
        title.handleLongLabels()
        title.textColor = UX.actionRowTextAndIconColor
        title.text = label
        */
        let title = UILabel()
        title.font = UIFont.boldSystemFont(ofSize: 16)
        title.handleLongLabels()
        title.textColor = UIColor(red:0.03, green:0.64, blue:0.93, alpha:1.00)
        title.text = label
        title.textAlignment = .center
        /* Cliqz: Remove icon
        [icon, title].forEach { row.addArrangedSubview($0) }

        icon.snp.makeConstraints { make in
            make.width.equalTo(UX.actionRowIconSize)
        }
        */
        row.addArrangedSubview(title)

        if hasNavigation {
            let navButton = UIImageView(image: UIImage(named: "menu-Disclosure")?.withRenderingMode(.alwaysTemplate))
            navButton.contentMode = .scaleAspectFit
            navButton.tintColor = UX.actionRowTextAndIconColor
            row.addArrangedSubview(navButton)
            navButton.snp.makeConstraints { make in
                make.width.equalTo(14)
            }
        }

        let gesture = UITapGestureRecognizer(target: self, action: action)
        row.addGestureRecognizer(gesture)
    }

    fileprivate func animateToActionDoneView(withTitle title: String = "") {
        navigationItem.leftBarButtonItem = nil

        navigationController?.view.snp.updateConstraints { make in
            make.height.equalTo(UX.viewHeightForDoneState)
        }

        actionDoneRow.label.text = title

        UIView.animate(withDuration: UX.doneDialogAnimationDuration) {
            self.actionDoneRow.row.isHidden = false
            self.stackView.arrangedSubviews
                .filter { !self.viewsShownDuringDoneAnimation.contains($0) }
                .forEach { $0.removeFromSuperview() }

            self.navigationController?.view.superview?.layoutIfNeeded()
        }
    }

    @objc func finish(afterDelay: TimeInterval = UX.durationToShowDoneDialog) {
        delegate?.finish(afterDelay: afterDelay)
    }

    private func makeActionDoneRow(addTo parent: UIStackView) -> (row: UIStackView, label: UILabel) {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.addBackground(color: UX.doneLabelBackgroundColor)
        stackView.rightLeftEdges(inset: UX.rowInset)
        parent.addArrangedSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.height.equalTo(UX.pageInfoRowHeight)
        }

        let label = UILabel()
        label.font = UX.doneLabelFont
        label.handleLongLabels()

        let checkmark = UILabel()
        checkmark.text = "✓"
        checkmark.font = UIFont.boldSystemFont(ofSize: 22)

        [label, checkmark].forEach {
            stackView.addArrangedSubview($0)
            $0.textColor = .white
        }

        checkmark.snp.makeConstraints { make in
            make.width.equalTo(20)
        }

        return (stackView, label)
    }

    private func setupNavBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow") // hide separator line
		navigationItem.titleView = UIImageView(image: UIImage(named: "Icon-Small"))
		// Cliqz
		#if PAID
        navigationItem.titleView = UIImageView(image: UIImage(named: "lumenIcon"))
		#elseif CLIQZ
		navigationItem.titleView = UIImageView(image: UIImage(named: "cliqzIcon"))
		#endif
		// Cliqz End
        navigationItem.titleView?.contentMode = .scaleAspectFit
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.SendToCancelButton, style: .plain, target: self, action: #selector(finish))
    }

    private func setupStackView() {
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension ShareViewController {
    @objc func actionLoadInBackground(gesture: UIGestureRecognizer) {
        // To avoid re-rentry from double tap, each action function disables the gesture
        gesture.isEnabled = false
        /* Cliqz: [IP-312] Change the localized string to cliqz one
        animateToActionDoneView(withTitle: Strings.ShareLoadInBackgroundDone)
         */
        animateToActionDoneView(withTitle: CliqzStrings.ShareLoadInBackgroundDone)
        
        if let shareItem = shareItem, case .shareItem(let item) = shareItem {
            let profile = BrowserProfile(localName: "profile")
            profile.queue.addToQueue(item).uponQueue(.main) { _ in
                profile.shutdown()
            }

            addAppExtensionTelemetryEvent(forMethod: "load-in-background")
        }

        finish()
    }

    @objc func actionBookmarkThisPage(gesture: UIGestureRecognizer) {
        gesture.isEnabled = false
        animateToActionDoneView(withTitle: Strings.ShareBookmarkThisPageDone)

        if let shareItem = shareItem, case .shareItem(let item) = shareItem {
            let profile = BrowserProfile(localName: "profile")
            _ = profile.bookmarks.shareItem(item).value // Blocks until database has settled
            profile.shutdown()

            addAppExtensionTelemetryEvent(forMethod: "bookmark-this-page")
        }

        finish()
    }

    @objc func actionAddToReadingList(gesture: UIGestureRecognizer) {
        gesture.isEnabled = false
        animateToActionDoneView(withTitle: Strings.ShareAddToReadingListDone)

        if let shareItem = shareItem, case .shareItem(let item) = shareItem {
            let profile = BrowserProfile(localName: "profile")
            profile.readingList.createRecordWithURL(item.url, title: item.title ?? "", addedBy: UIDevice.current.name)
            profile.shutdown()

            addAppExtensionTelemetryEvent(forMethod: "add-to-reading-list")
        }

        finish()
    }

    @objc func actionSendToDevice(gesture: UIGestureRecognizer) {
        guard let shareItem = shareItem, case .shareItem(let item) = shareItem else {
            return
        }

        gesture.isEnabled = false
        sendToDevice = SendToDevice()
        guard let sendToDevice = sendToDevice else { return }
        sendToDevice.sharedItem = item
        sendToDevice.delegate = delegate
        let vc = sendToDevice.initialViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    func openFirefox(withUrl url: String, isSearch: Bool) {
        // Telemetry is handled in the app delegate that receives this event.
        let profile = BrowserProfile(localName: "profile")
        profile.prefs.setBool(true, forKey: PrefsKeys.AppExtensionTelemetryOpenUrl)

       func firefoxUrl(_ url: String) -> String {
            let encoded = url.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics) ?? ""
            if isSearch {
				#if PAID
				return "lumen://open-text?text=\(encoded)"
				#elseif CLIQZ
				return "cliqz://open-text?text=\(encoded)"
				#else
                return "ghostery://open-text?text=\(encoded)"
				#endif
            }
			#if PAID
			return "lumen://open-url?url=\(encoded)"
			#elseif CLIQZ
			return "cliqz://open-url?url=\(encoded)"
			#else
            return "ghostery://open-url?url=\(encoded)"
			#endif
        }

        guard let url = URL(string: firefoxUrl(url)) else { return }
        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")
        while let current = responder {
            if current.responds(to: selectorOpenURL) {
                current.perform(selectorOpenURL, with: url, afterDelay: 0)
                break
            }

            responder = current.next
        }
    }

    @objc func actionSearchInFirefox(gesture: UIGestureRecognizer) {
        gesture.isEnabled = false

        if let shareItem = shareItem, case .rawText(let text) = shareItem {
            openFirefox(withUrl: text, isSearch: true)
        }

        finish(afterDelay: 0)
    }

    @objc func actionOpenInFirefoxNow(gesture: UIGestureRecognizer) {
        gesture.isEnabled = false

        if let shareItem = shareItem, case .shareItem(let item) = shareItem {
            openFirefox(withUrl: item.url, isSearch: false)
        }

        finish(afterDelay: 0)
    }
}

