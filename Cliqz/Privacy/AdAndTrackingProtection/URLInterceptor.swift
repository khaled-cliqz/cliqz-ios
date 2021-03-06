//
//  URLInterceptor.swift
//  BrowserCore
//
//  Created by Tim Palade on 3/19/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import WebKit

class URLInterceptor: NSObject {
    static let shared = URLInterceptor()
}

let detectedTrackerNotification = Notification.Name(rawValue: "trackerDetectedNotification")
let newInterceptedURLNotification = Notification.Name(rawValue: "newInterceptedURLNotification")

extension URLInterceptor: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let body = message.body as? [String: Any],
            let urlString = body["url"] as? String,
            let pageUrl = body["location"] as? String,
            let tabIdentifier = body["tabIdentifier"] as? Int else { return }
        
        guard var components = URLComponents(string: urlString) else { return }
        components.scheme = "http"
        guard let url = components.url else { return }
        
        let timestamp = Date().timeIntervalSince1970
        
        if let siteURL = URL(string: pageUrl)?.domainURL {
            
            var userInfo: [String: Any] = ["domainURL": siteURL]
            if let pageURL = URL(string: pageUrl) {
                userInfo["url"] = pageURL
            }
            userInfo["tabID"] = tabIdentifier
            userInfo["sourceURL"] = url
            
            let bug = TrackerList.instance.isTracker(url, pageUrl: siteURL, timestamp: timestamp)
            if bug != nil {
                userInfo["bug"] = bug
                NotificationCenter.default.post(name: detectedTrackerNotification, object: nil, userInfo: userInfo)
            }
            else {
                NotificationCenter.default.post(name: newInterceptedURLNotification, object: nil, userInfo: userInfo)
            }
        }
    }
}
