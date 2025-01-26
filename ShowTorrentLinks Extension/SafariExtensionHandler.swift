//
//  SafariExtensionHandler.swift
//  ShowTorrentLinks Extension
//
//  Created by Jon Hogg on 20/11/2019.
//  Copyright © 2019-2025 Jon Hogg. All rights reserved.
//
let myDebug = false

struct Session {
    let server: String
    let port: Int
    let rpcPath: String
    let user: String
    let pass: String
    var sessionId: String
}
struct Request: Codable {
    let arguments: [String: String]
    let method: String
    let tag: String
}

var ses = Session(server: "mediaserver18.h0stname.net",
				  port: 28991,
				  rpcPath: "/transmission/rpc",
				  user: "xmitd",
				  pass: "xmitd",
				  sessionId: "")

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    
    fileprivate func rpc2Transmission(rpcArgs: [String: String], rpcMethod: String, rpcTag: String = "") {
        if myDebug { NSLog("rpc2Transmission (\(rpcMethod)) (\(rpcTag)) (\(rpcArgs))") }

        // create the url
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = ses.server
        urlComponents.port = ses.port
        urlComponents.user = ses.user
        urlComponents.password = ses.pass
        urlComponents.path = ses.rpcPath
        // create the request
        if myDebug { NSLog("components (\(urlComponents.url!.absoluteString))") }
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(ses.sessionId, forHTTPHeaderField: "X-Transmission-Session-Id")
        if myDebug { NSLog("request: (\(request))") }

        // create the request data
        let rpcRequest = Request(arguments: rpcArgs, method: rpcMethod, tag: rpcTag)
        guard let uploadData = try? JSONEncoder().encode(rpcRequest) else {
            NSLog("error creating uploadData")
            return
        }
        if myDebug { NSLog("uploadData (\(String(data: uploadData, encoding: .utf8)!))") }

        // create and start an upload task
        let task = URLSession(configuration: .ephemeral).uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                NSLog("error: \(error)")
                return
            }

            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) || response.statusCode == 409 else {
                NSLog("server error")
                return
            }

            // if response code is 409 then get the Session ID from the X-Transmission-Session-Id response header
            // and try again
            if response.statusCode == 409 {
                ses.sessionId = response.value(forHTTPHeaderField:  "X-Transmission-Session-Id")!
                self.rpc2Transmission(rpcArgs: rpcArgs, rpcMethod: rpcMethod, rpcTag: rpcTag)
            }

            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data,
                let dataString = String(data: data, encoding: .utf8) {
                NSLog("got data: \(dataString)")
            }
        }
        task.resume()

    }

    fileprivate func addTorrent(_ urlString: String) {
        if myDebug { NSLog("addTorrent (\(urlString))") }

        // change https to http, otherwise some torrents aren't able to be added successfully
        var url = urlString
        if urlString.hasPrefix("https") {
            let i = url.firstIndex(of: "s")
            url.remove(at: i!)
            if myDebug { NSLog("addTorrent#2 (\(url))") }
        }

        // send the torrent to transmission and check response
        rpc2Transmission(rpcArgs: ["filename": url], rpcMethod: "torrent-add")

    }

    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
        page.getPropertiesWithCompletionHandler { properties in
            NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
        }
        
        // torrent download initiated by clicking link on page
        if messageName == "inject" {
            guard let linkURL = userInfo?["url"] else {
                return
            }
            if myDebug { NSLog("messageReceived: (\(linkURL as! String)), (\(userInfo?["method"] as! String))") }
            if userInfo?["method"] as! String == "torrent-add" {
                addTorrent(linkURL as! String)
            }
        }

    }
    
}
