//
//  URLSessionDemoApp.swift
//  URLSessionDemo
//
//  Created by Mayur Bendale on 14/09/24.
//

import SwiftUI

@main
struct URLSessionDemoApp: App {
    // Create a UIApplicationDelegateAdaptor to connect AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            DownloadLargeFileView()
        }
    }
}
