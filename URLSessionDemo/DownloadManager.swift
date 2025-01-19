import UIKit

protocol DownloadManagerDelegate: AnyObject {
    func downloadManagerDidStartDownloading()
    func downloadManagerDidPauseDownloading()
    func downloadManagerDidFinishDownloading()
    func downloadManagerDidUpdateProgress(progress: Double)
    func downloadManagerDidResumeDownloading()
}

//To use cache
//Ensure the server sends proper caching headers (Cache-Control, ETag) for the best results.
//If the server doesn't support caching headers, manually store the response in URLCache using storeCachedResponse.

class DownloadManager: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    var isPaused: Bool = false
    var isDownloading = false
    weak var delegate: DownloadManagerDelegate?

    private let cache = NSCache<NSURL, NSURL>()
    private var url: URL!
    private var downloadTask: URLSessionDownloadTask?
    private var resumeData: Data?

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.msb.largefiledownload")
        configuration.isDiscretionary = false // For time-insensitive tasks enable this so the system can wait for optimal conditions to perform the transfer, such as when the device is plugged in or connected to Wi-Fi
        configuration.allowsCellularAccess = true // Enable download over cellular
        configuration.sessionSendsLaunchEvents = true // To have the system to wake up your app when a task completes and the app is in the background
        configuration.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,// 50 MB memory cache
            diskCapacity: 100 * 1024 * 1024, // 100 MB disk cache
            diskPath: "fileDownloadCache"    // Custom disk cache path
        )
        return URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
    }()

    func startDownload(from url: URL) {
        self.url = url

        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad // Use cache if available, else fetch from the server

        guard !cacheExist() else {
            return
        }

        let downloadTask = session.downloadTask(with: request)
//        downloadTask.earliestBeginDate = Date().addingTimeInterval(60 * 60) // to schedule the download to begin at a particular point in the future. The download isn’t guaranteed to begin at precisely this time, but it won’t start sooner.
        downloadTask.countOfBytesClientExpectsToSend = 200 // To help the system schedule network activity efficiently
        downloadTask.countOfBytesClientExpectsToReceive = 500 * 1024 // To help the system schedule network activity efficiently
        downloadTask.resume()
        self.downloadTask = downloadTask
        DispatchQueue.main.async {
            self.isDownloading = true
        }
        delegate?.downloadManagerDidStartDownloading()
    }

    func pauseDownload() {
        guard let downloadTask = downloadTask else { return }
        downloadTask.cancel { [weak self] resumeDataOrNil in
            guard let self = self else { return }
            self.resumeData = resumeDataOrNil
            self.delegate?.downloadManagerDidPauseDownloading()
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
        delegate?.downloadManagerDidResumeDownloading()
        DispatchQueue.main.async {
            self.isPaused = false
            self.isDownloading = true
        }
    }

    // Track download progress
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            print("Download progress: \(progress * 100)%")
            self.delegate?.downloadManagerDidUpdateProgress(progress: progress)
        }
    }

    // Handle file completion
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let response = downloadTask.response,
              let request = downloadTask.originalRequest else {
            print("No response or request available.")
            return
        }

        print("Download completed. File downloaded to temporary location: \(location)")
        // Move file to a permanent location
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("BigBuckBunny.mp4")

        do {
            saveToCache(destinationURL: destinationURL, response: response)

            try fileManager.moveItem(at: location, to: destinationURL)
            print("File moved to: \(destinationURL)")

            delegate?.downloadManagerDidFinishDownloading()
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

// MARK: - Cache
extension DownloadManager {
    func cacheExist() -> Bool {
        // Remove all cached response
//        cache.removeAllObjects()
//        URLCache.shared.removeAllCachedResponses()
//        session.configuration.urlCache?.removeAllCachedResponses()

        // Using NSCache
//        if let cacheURL = cache.object(forKey: url as NSURL) {
//            print("Using cached URL: ", cacheURL)
//            return true
//        }

        let request = URLRequest(url: url)

        if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
            print("Cached Response: \(String(data: cachedResponse.data, encoding: .utf8) ?? "No readable data")")
            return true
        }

        if let cachedResponse = session.configuration.urlCache?.cachedResponse(for: request) {
            let fileURL = String(data: cachedResponse.data, encoding: .utf8)
            print("Cached Response: \(fileURL ?? "No readable data")")
            return true
        }
        return false
    }

    func saveToCache(destinationURL: URL, response: URLResponse) {
        // using NSCache
//        cache.setObject(destinationURL as NSURL, forKey: url as NSURL)

        // Using Cache policy
        let data = destinationURL.absoluteString.data(using: .utf8)!
//            let data = try Data(contentsOf: destinationURL)
        // Create a CachedURLResponse
        let cachedResponse = CachedURLResponse(response: response, data: data)
        // Manually store the response in the cache
        let request = URLRequest(url: url)
        session.configuration.urlCache?.storeCachedResponse(cachedResponse, for: request)
        print("Response cached successfully.")
    }
}
