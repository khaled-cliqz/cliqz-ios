//
//  CliqzStrings.swift
//  Client
//
//  Created by Tim Palade on 5/18/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import UIKit

struct CliqzStrings {}

// Onboarding
extension CliqzStrings {
    public struct Onboarding {
        public var telemetryText: String {
            return NSLocalizedString("Support Ghostery by sharing anonymous analytics and Human Web data to improve Ghostery's performance.", tableName: "Cliqz", comment: "[Onboarding] Telemetry")
        }
        
        public var introText: String {
            return NSLocalizedString("Browse cleaner, faster, and safer on-the-go with Ghostery, now optimized for mobile!", tableName: "Cliqz", comment: "[Onboarding] Intro Text")
        }
        
        public var introTextOldUsers: String {
            return NSLocalizedString("Browse cleaner, faster, and safer on-the-go with Ghostery, now optimized for mobile! Don't worry, all your data will be imported.", tableName: "Cliqz", comment: "[Onboarding] Intro Text Old Users")
        }
        
        public var introTitle: String {
            return NSLocalizedString("Introducing Ghostery", tableName: "Cliqz", comment: "[Onboarding] Intro Title")
        }
        
        public var introTitleOldUsers: String {
            return NSLocalizedString("Introducing New Ghostery", tableName: "Cliqz", comment: "[Onboarding] Intro Title Old Users")
        }
        
        public var adblockerText: String {
            return NSLocalizedString("Choose what you want Ghostery to block for cleaner, faster, and safer browsing. You can change and customize these settings at any time in the Privacy Control Center.", tableName: "Cliqz", comment: "[Onboarding] Adblocker Text")
        }
        
        public var adblockerTitle: String {
            return NSLocalizedString("Ad & Tracker Blocking", tableName: "Cliqz", comment: "[Onboarding] Adblocker Title")
        }
        
        public var quickSearchText: String {
            return NSLocalizedString("Stay anonymous, reduce data usage, and save time: results appear instantly as you type in the Ghost search bar.", tableName: "Cliqz", comment: "[Onboarding] QuickSearch Text")
        }
        
        public var quickSearchTitle: String {
            return NSLocalizedString("Ghost Search", tableName: "Cliqz", comment: "[Onboarding] QuickSearch Title")
        }
        
        public var tabText: String {
            return NSLocalizedString("Each new Start Tab is customizable and can display top sites, the latest news, and other tracking insights to come.", tableName: "Cliqz", comment: "[Onboarding] Tab Text")
        }
        
        public var tabTitle: String {
            return NSLocalizedString("Start Tab", tableName: "Cliqz", comment: "[Onboarding] Freshtab Title")
        }
        
        public var blockNothingTickButtonTitle: String {
            return NSLocalizedString("Block Nothing", tableName: "Cliqz", comment: "[Onboarding] Block Nothing TickButton Title")
        }
        
        public var blockRecommendedTickButtonTitle: String {
            return NSLocalizedString("Block Recommended", tableName: "Cliqz", comment: "[Onboarding] Block Recommended TickButton Title")
        }
        
        public var blockRecommendedTickButtonSubTitle: String {
            return NSLocalizedString("Ads, site analytics and adult advertising trackers", tableName: "Cliqz", comment: "[Onboarding] Block Recommended TickButton SubTitle")
        }

        public var blockEverythingTickButtonTitle: String {
            return NSLocalizedString("Block Everything", tableName: "Cliqz", comment: "[Onboarding] Block Everything TickButton Title")
        }
        
    }
    
    public static let FreshTab = NSLocalizedString("Fresh Tab", tableName: "Cliqz", comment: "Title for Freshtab in tab history list")
    
    public static let AppMenuAddFavoriteTitleString = NSLocalizedString("Menu.AddFavoriteAction.Title", tableName: "Cliqz", value: "Add to Favorites", comment: "Label for the button, displayed in the menu, used to create a favorite for the current website.")
    
    public static let AppMenuRemoveFavoriteTitleString = NSLocalizedString("Menu.RemoveBookmarkAction.Title", tableName: "Cliqz", value: "Remove Favorite", comment: "Label for the button, displayed in the menu, used to delete an existing bookmark for the current website.")
    
    public static let AppMenuAddFavoriteConfirmMessage = NSLocalizedString("Menu.AddFavorite.Confirm", tableName: "Cliqz", value: "Favorite Added", comment: "Toast displayed to the user after a bookmark has been added.")
    public static let AppMenuRemoveFavoriteConfirmMessage = NSLocalizedString("Menu.RemoveFavorite.Confirm", tableName: "Cliqz", value: "Favorite Removed", comment: "Toast displayed to the user after a bookmark has been removed.")
    
    #if PAID
        public static let ShareOpenInCliqz = NSLocalizedString("ShareExtension.OpenInLumenAction.Title", tableName: "Lumen", value: "Open in Lumen", comment: "Action label on share extension to immediately open page in Ghostery.")
    
        public static let ShareSearchInCliqz = NSLocalizedString("ShareExtension.SeachInLumenAction.Title", tableName: "Lumen", value: "Search in Lumen", comment: "Action label on share extension to search for the selected text in Ghostery.")
        public static let OpenInNewForgetTabContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.OpenInNewPrivateTab", tableName: "Lumen", value: "Open in New Private Tab", comment: "The title for the Open in New Forget Tab context menu action for sites in Home Panels")
        public static let NewForgetTabTitle = NSLocalizedString("Hotkeys.NewPrivateTab.DiscoveryTitle", tableName: "Lumen", value: "New Private Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
        public static let ShareLoadInBackgroundDone = NSLocalizedString("ShareExtension.LoadLumenInBackgroundActionDone.Title", tableName: "Lumen", value: "Loading in Lumen", comment: "Share extension label shown after user has performed 'Load in Background' action.")
    
    #elseif CLIQZ
		public static let ShareOpenInCliqz = NSLocalizedString("ShareExtension.OpenInGhosteryAction.Title", tableName: "Cliqz", value: "Open in Cliqz", comment: "Action label on share extension to immediately open page in Cliqz.")
		public static let ShareSearchInCliqz = NSLocalizedString("ShareExtension.SeachInGhosteryAction.Title", tableName: "Cliqz", value: "Search in Cliqz", comment: "Action label on share extension to search for the selected text in Cliqz.")
		public static let OpenInNewForgetTabContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.OpenInNewForgetTab", tableName: "Cliqz", value: "Open in New Private Tab", comment: "The title for the Open in New Forget Tab context menu action for sites in Home Panels")
		public static let NewForgetTabTitle = NSLocalizedString("Hotkeys.NewForgetTab.DiscoveryTitle", tableName: "Cliqz", value: "New Private Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
		public static let ShareLoadInBackgroundDone = NSLocalizedString("ShareExtension.LoadGhosteryInBackgroundActionDone.Title", tableName: "Cliqz", value: "Loading in Cliqz", comment: "Share extension label shown after user has performed 'Load in Background' action.")
	#else
        public static let ShareOpenInCliqz = NSLocalizedString("ShareExtension.OpenInGhosteryAction.Title", tableName: "Cliqz", value: "Open in Ghostery", comment: "Action label on share extension to immediately open page in Ghostery.")
    
        public static let ShareSearchInCliqz = NSLocalizedString("ShareExtension.SeachInGhosteryAction.Title", tableName: "Cliqz", value: "Search in Ghostery", comment: "Action label on share extension to search for the selected text in Ghostery.")
        public static let OpenInNewForgetTabContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.OpenInNewForgetTab", tableName: "Ghostery", value: "Open in New Ghost Tab", comment: "The title for the Open in New Forget Tab context menu action for sites in Home Panels")
        public static let NewForgetTabTitle = NSLocalizedString("Hotkeys.NewForgetTab.DiscoveryTitle", tableName: "Ghostery", value: "New Ghost Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
        public static let ShareLoadInBackgroundDone = NSLocalizedString("ShareExtension.LoadGhosteryInBackgroundActionDone.Title", tableName: "Ghostery", value: "Loading in Ghostery", comment: "Share extension label shown after user has performed 'Load in Background' action.")
    #endif
    
    
    public struct LumenOnboarding {
        
        public var introTitle: String {
            return NSLocalizedString("Ultimate Protection Online", tableName: "Lumen", comment: "[Onboarding] Intro Title")
        }
        public var introText: String {
            return NSLocalizedString("Blocks ads and trackers. Saves data volume and time.", tableName: "Lumen", comment: "[Onboarding] Intro text")
        }
        
        
        public var adblockerTitle: String {
            return NSLocalizedString("Block Ads & Trackers", tableName: "Lumen", comment: "[Onboarding] Adblocker title")
        }
        public var adblockerText: String {
            return NSLocalizedString("Enjoy clutter-free websites and save data & time.", tableName: "Lumen", comment: "[Onboarding] Adblocker text")
        }
        
        public var vpnTitle: String {
            return NSLocalizedString("Safe and Sound on the Go", tableName: "Lumen", comment: "[Onboarding] VPN title")
        }
        
        public var vpnText: String {
            return NSLocalizedString("Hide your location", tableName: "Lumen", comment: "[VPN] Hide your location")
        }
        
        
        public var dashboardTitle: String {
            return NSLocalizedString("Dashboard", tableName: "Lumen", comment: "[Onboarding] Dashboard title")
        }
        public var dashboardText: String {
            return NSLocalizedString("Lumen brings to light what happens in the shadows and protects you.", tableName: "Lumen", comment: "[Onboarding] Dashboard text")
        }
        
        public var getNextButtonText: String {
            return NSLocalizedString("NEXT", tableName: "Lumen", comment: "[Onboarding] Get Started button text")
        }

		public var getLetsGoButtonText: String {
			return NSLocalizedString("LET'S GO", tableName: "Lumen", comment: "[Onboarding] Get Started button text")
		}

		public var getSkipIntroButtonText: String {
			return NSLocalizedString("SKIP", tableName: "Lumen", comment: "[Onboarding] Get Started button text")
		}
		
        public var telemetryText: String {
            return NSLocalizedString("I agree to share strictly anonymous analytics data to improve Lumen's performance.", tableName: "Lumen", comment: "[Onboarding] Telemetry")
        }
    }
    
}
