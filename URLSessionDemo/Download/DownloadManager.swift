import Foundation
import SwiftUI

class DownloadManager: NSObject, ObservableObject, URLSessionDelegate, URLSessionDownloadDelegate {
    @Published var downloadProgress: Double = 0.0
    @Published var isPaused: Bool = false
    @Published var isDownloading = false

    private var downloadTask: URLSessionDownloadTask?
    private var resumeData: Data?

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.yourApp.largefiledownload")
        config.isDiscretionary = false // For time-insensitive tasks enable this so the system can wait for optimal conditions to perform the transfer, such as when the device is plugged in or connected to Wi-Fi
        config.allowsCellularAccess = true // Enable download over cellular
        config.sessionSendsLaunchEvents = true // To have the system to wake up your app when a task completes and the app is in the background
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func startDownload(from url: URL) {
        guard downloadTask == nil else { return }
        let downloadTask = session.downloadTask(with: url)
//        downloadTask.earliestBeginDate = Date().addingTimeInterval(60 * 60) // to schedule the download to begin at a particular point in the future. The download isn’t guaranteed to begin at precisely this time, but it won’t start sooner.
        downloadTask.countOfBytesClientExpectsToSend = 200 // To help the system schedule network activity efficiently
        downloadTask.countOfBytesClientExpectsToReceive = 500 * 1024 // To help the system schedule network activity efficiently
        downloadTask.resume()
        self.downloadTask = downloadTask
        DispatchQueue.main.async {
            self.isDownloading = true
        }
    }

    func pauseDownload() {
        guard let downloadTask = downloadTask else { return }
        downloadTask.cancel { [weak self] resumeDataOrNil in
            guard let self = self else { return }
            self.resumeData = resumeDataOrNil
            DispatchQueue.main.async {
                self.isPaused = true
                self.isDownloading = false
            }
        }
    }

    func resumeDownload() {
        guard let resumeData = resumeData else { return }
        let task = session.downloadTask(withResumeData: resumeData)
        task.resume()
        downloadTask = task
        DispatchQueue.main.async {
            self.isPaused = false
            self.isDownloading = true
        }
    }

    // Track download progress
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.downloadProgress = progress
            print("Download progress: \(progress * 100)%")
        }
    }

    // Handle file completion
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Download completed. File downloaded to temporary location: \(location)")

        // Move file to a permanent location
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("BigBuckBunny.mp4")

        do {
            try fileManager.moveItem(at: location, to: destinationURL)
            print("File moved to: \(destinationURL)")
        } catch {
            print("Error moving file: \(error)")
        }

        DispatchQueue.main.async {
            self.isDownloading = false
        }
    }

    // Handle background task completion
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                completionHandler()
            }
        }
    }
}
