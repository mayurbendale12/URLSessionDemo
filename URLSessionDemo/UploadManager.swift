import Foundation

class UploadManager: NSObject, URLSessionTaskDelegate {
    private var session: URLSession!
    
    override init() {
        super.init()
        
        // Create a session with delegate to track progress
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func uploadData() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the data to upload
        let postData: [String: Any] = [
            "title": "foo",
            "body": "bar",
            "userId": 1
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: postData, options: []) else {
            print("Failed to encode JSON")
            return
        }
        
        // Create an upload task
        let task = session.uploadTask(with: request, from: jsonData) { data, response, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                return
            }
            
            if let response = response as? HTTPURLResponse, let data = data {
                print("Status Code: \(response.statusCode)")
                print("Response: \(String(data: data, encoding: .utf8) ?? "")")
            }
        }
        
        task.resume()
    }
    
    // Delegate method to track upload progress
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if totalBytesExpectedToSend > 0 {
            let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
            print(String(format: "Upload Progress: %.2f%%", progress * 100))
        }
    }
}
