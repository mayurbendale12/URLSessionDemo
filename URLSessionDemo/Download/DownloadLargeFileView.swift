//
//  ContentView.swift
//  URLSessionDemo
//
//  Created by Mayur Bendale on 14/09/24.
//

import SwiftUI

struct DownloadLargeFileView: View {
    @StateObject var downloadManager = DownloadManager()
    private let fileURL = URL(string: "https://archive.org/download/BigBuckBunny_328/BigBuckBunny_512kb.mp4")!
    var body: some View {
        VStack(spacing: 20) {
            Text("Download Progress: \(downloadManager.downloadProgress * 100)%")
                .padding()
                .font(.headline)

            ProgressView(value: downloadManager.downloadProgress)
                .padding()

            if downloadManager.isDownloading {
                Button(action: {
                    downloadManager.pauseDownload()
                }) {
                    Text("Pause")
                }
            } else if downloadManager.isPaused {
                Button(action: {
                    downloadManager.resumeDownload()
                }) {
                    Text("Resume")
                }
            } else {
                Button(action: {
                    downloadManager.startDownload(from: fileURL)
                }) {
                    Text("Start Download")
                }
            }
        }
        .padding()
    }
}

#Preview {
    DownloadLargeFileView()
}
