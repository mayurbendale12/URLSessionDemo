import Foundation

class WebSocketManager: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession!
    
    override init() {
        super.init()
        
        // Initialize a session with the WebSocket delegate
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
    }
    
    func connect() {
        //wss://ws.postman-echo.com/raw
        guard let url = URL(string: "wss://echo.websocket.org") else {
            print("Invalid URL")
            return
        }
        
        // Create the WebSocket task
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start receiving messages
        receiveMessage()
    }
    
    func sendMessage(_ message: String) {
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                print("Send error: \(error.localizedDescription)")
            } else {
                print("Message sent: \(message)")
            }
        }
    }
    
    func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received string: \(text)")
                case .data(let data):
                    print("Received binary data: \(data)")
                @unknown default:
                    print("Received unknown message type")
                }
                
                // Continue receiving messages
                self?.receiveMessage()
                
            case .failure(let error):
                print("Receive error: \(error.localizedDescription)")
            }
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        print("WebSocket disconnected")
    }
    
    // MARK: - URLSessionWebSocketDelegate Methods
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        let string = `protocol`

        print("WebSocket connection opened. Protocol: \(string ?? "None")")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket connection closed. Code: \(closeCode.rawValue)")
        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            print("Reason: \(reasonString)")
        } else {
            print("No reason provided.")
        }
    }
}
