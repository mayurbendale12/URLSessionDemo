import UIKit

class ViewController: UIViewController, DownloadManagerDelegate {
    @IBOutlet private weak var label: UILabel!
    private let downloadManager = DownloadManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        testDataTask()
        testURLSessionDefaultConfiguration()
    }

    //MARK: - Download Task
    @IBAction private func didTapDownloadButton() {
        downloadManager.delegate = self
        let fileURL = URL(string: "https://archive.org/download/BigBuckBunny_328/BigBuckBunny_512kb.mp4")!
        downloadManager.startDownload(from: fileURL)
    }

    @IBAction private func didTapResumeButton() {
        if downloadManager.isPaused {
            downloadManager.resumeDownload()
        }
    }

    @IBAction private func didTapPauseButton() {
        if downloadManager.isDownloading {
            downloadManager.pauseDownload()
        }
    }

    func downloadManagerDidStartDownloading() {}

    func downloadManagerDidPauseDownloading() {}

    func downloadManagerDidFinishDownloading() {}

    func downloadManagerDidUpdateProgress(progress: Double) {
        let formatedProgress = (progress * 10000).rounded() / 100
        let progress = "\(formatedProgress)%"
        label.text = "Download Progress: \(progress)"
    }

    func downloadManagerDidResumeDownloading() {}

    //MARK: - Upload Task
    @IBAction private func didTapUploadButton() {
        let uploadManager = UploadManager()
        uploadManager.uploadData()
    }

    //MARK: - Stream Task
    @IBAction private func didTapStreamButton() {
        let streamManager = StreamManager()
        streamManager.startStream()

        // Close after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            streamManager.closeStream()
        }
    }

    //MARK: - Websocket Task
    @IBAction private func didTapWebsocketButton() {
        let webSocketManager = WebSocketManager()
        webSocketManager.connect()

        // Send a message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            webSocketManager.sendMessage("Hello, WebSocket!")
        }

        // Disconnect after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            webSocketManager.disconnect()
        }
    }
}

//MARK: - Data Task
private extension ViewController {
    struct Post: Codable {
        let userId: Int
        let id: Int
        let title: String
        let body: String
    }

    func testDataTask() {
        performGETRequest()
        performPUTRequest()
        performPOSTRequest()
        performPATCHRequest()
        performDELETERequest()
    }

    func performGETRequest() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1") else {
            print("Invalid URL")
            return
        }

//        var urlRequest = URLRequest(url: url)
//        urlRequest.httpMethod = "GET"
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        urlRequest.httpBody = nil
//        urlRequest.timeoutInterval = 10
//        urlRequest.allowsCellularAccess = false
//        urlRequest.allowsConstrainedNetworkAccess = false

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("GET Request Error: \(error.localizedDescription)")
                return
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("GET Response: \(responseString)")
                let post = try? JSONDecoder().decode(Post.self, from: data)
                print("Post: ", post as Any)
            }
        }

        task.resume()
    }

    func performPOSTRequest() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "title": "foo",
            "body": "bar",
            "userId": 1
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("POST Request Error: \(error.localizedDescription)")
                return
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("POST Response: \(responseString)")
            }
        }

        task.resume()
    }

    func performPUTRequest() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "id": 1,
            "title": "Updated Title",
            "body": "Updated Body",
            "userId": 1
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("PUT Request Error: \(error.localizedDescription)")
                return
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("PUT Response: \(responseString)")
            }
        }

        task.resume()
    }

    func performDELETERequest() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DELETE Request Error: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse {
                print("DELETE Response Code: \(response.statusCode)")
            }
        }

        task.resume()
    }

    func performPATCHRequest() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "title": "Partially Updated Title"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("PATCH Request Error: \(error.localizedDescription)")
                return
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("PATCH Response: \(responseString)")
            }
        }

        task.resume()
    }
}

//MARK: - URLSessionConfiguration and URLRequest configuration
class MockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        // Decide which requests to handle (e.g., all requests)
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    // Called when a request starts. Here, you can provide mock responses.
    override func startLoading() {
        if let url = request.url, url.absoluteString == "https://www.google.com" {
            let mockResponse = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )
            let mockData = """
                    {
                        "message": "This is a mocked response"
                    }
                    """.data(using: .utf8)

            client?.urlProtocol(self, didReceive: mockResponse!, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: mockData!)
        } else {
            // Handle unexpected requests
            let error = NSError(domain: "MockURLProtocol", code: 404, userInfo: nil)
            client?.urlProtocol(self, didFailWithError: error)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // Clean up resources (if needed)
    }
}

extension ViewController {
    func testURLSessionDefaultConfiguration() {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.timeoutIntervalForRequest = 30 // Timeout for requests
        configuration.timeoutIntervalForResource = 60 // Timeout for resources
        configuration.httpMaximumConnectionsPerHost = 5 // Limit concurrent connections
        configuration.httpShouldSetCookies = true // Manage cookies automatically
        configuration.waitsForConnectivity = true // should wait for connectivity to become available, or fail immediately
        configuration.urlCache = nil //for providing cached responses to requests within the session

        let session = URLSession(configuration: configuration)
        let url = URL(string: "https://www.google.com")!
        let task = session.dataTask(with: url) { data, response, error in
            if let data, let responseString = String(data: data, encoding: .utf8) {
                print(responseString)
            }
        }
        task.resume()
    }

    func testURLSessionEphemeralConfiguration() {
        let configuration = URLSessionConfiguration.ephemeral
        let _ = URLSession(configuration: configuration)
        configuration.httpShouldUsePipelining = true // Optimize HTTP/1.1 performance
        configuration.allowsCellularAccess = false // Restrict to Wi-Fi only
    }

    func testURLSessionBackgroundConfiguration() {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.example.backgroundSession")
        let _ = URLSession(configuration: configuration)
        configuration.isDiscretionary = true // Schedule tasks when system resources allow
        configuration.sharedContainerIdentifier = "group.com.example.shared" // Use shared container for data
    }

    func testURLRequestConfigurations() {
        var request = URLRequest(url: URL(string: "https://example.com")!)
        request.httpMethod = "POST" // GET, POST, PUT, DELETE, PATCH
        request.timeoutInterval = 30 // Seconds
        //cachePolicy:
            //.useProtocolCachePolicy (default)
            //.reloadIgnoringLocalCacheData
            //.returnCacheDataElseLoad
            //.returnCacheDataDontLoad
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let parameters = ["key": "value"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        request.allHTTPHeaderFields = ["Authorization": "Bearer token"]
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.allowsCellularAccess = false
        request.allowsExpensiveNetworkAccess = false
        request.allowsConstrainedNetworkAccess = true
    }
}
