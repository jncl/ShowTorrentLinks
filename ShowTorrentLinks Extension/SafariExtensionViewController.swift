//
//  SafariExtensionViewController.swift
//  ShowTorrentLinks Extension
//
//  Created by Jon Hogg on 20/11/2019.
//  Copyright © 2019 Jon Hogg. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:320, height:240)
        return shared
    }()

}
