import Foundation

class StreamManager: NSObject, URLSessionDelegate, URLSessionStreamDelegate {
    private var session: URLSession!
    private var streamTask: URLSessionStreamTask!

    override init() {
        super.init()

        // Create session with delegate to handle stream events
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
    }

    func startStream() {
        //Echo server, send back any data you send to them. They are useful for testing basic read/write operations
        let host = "tcpbin.com"
        let port = 4242

        // Create the stream task
        streamTask = session.streamTask(withHostName: host, port: port)
        streamTask.resume()

        // Write data to the stream
        let message = "Hello, Echo Server!\n"
        if let messageData = message.data(using: .utf8) {
            streamTask.write(messageData, timeout: 30) { error in
                if let error = error {
                    print("Write error: \(error.localizedDescription)")
                } else {
                    print("Message sent to server.")
                }
            }
        }

        // Read response from the server
        streamTask.readData(ofMinLength: 1, maxLength: 1024, timeout: 30) { data, atEOF, error in
            if let error = error {
                print("Read error: \(error.localizedDescription)")
            } else if let data = data, let response = String(data: data, encoding: .utf8) {
                print("Received response: \(response)")
            }
        }
    }

    func closeStream() {
        streamTask.closeWrite()
        streamTask.closeRead()
        print("Stream closed.")
    }

    // MARK: - URLSessionStreamDelegate Methods
    func urlSession(_ session: URLSession, streamTask: URLSessionStreamTask, didBecome inputStream: InputStream, outputStream: OutputStream) {
        print("Stream task did become input and output streams.")
        // Use `inputStream` and `outputStream` if you need lower-level stream handling.
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Stream task completed with error: \(error.localizedDescription)")
        } else {
            print("Stream task completed successfully.")
        }
    }
}
