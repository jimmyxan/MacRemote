import Foundation
import Network

final class Server {
    static let port: UInt16 = 8765

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "macremote.server")
    private var recent: [Date] = []
    private var recentPointer: [Date] = []
    let token: () -> String
    let handler: (String, String?) -> [String: Any]
    /// Slow GET resources (now playing, artwork, screenshots): (status, content type, body) or nil for 404. Runs off the server queue.
    let resource: (HTTPRequest) -> (Int, String, Data)?

    init(token: @escaping () -> String, handler: @escaping (String, String?) -> [String: Any],
         resource: @escaping (HTTPRequest) -> (Int, String, Data)?) {
        self.token = token
        self.handler = handler
        self.resource = resource
    }

    func start() throws {
        let l = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: Server.port)!)
        l.service = NWListener.Service(name: "MacRemote", type: "_http._tcp")
        l.newConnectionHandler = { [weak self] conn in self?.accept(conn) }
        l.start(queue: queue)
        listener = l
    }

    private func accept(_ conn: NWConnection) {
        guard Self.isLocal(conn.endpoint) else { conn.cancel(); return }
        conn.start(queue: queue)
        receive(conn, buffer: Data())
    }

    private func receive(_ conn: NWConnection, buffer: Data) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, done, err in
            guard let self else { return }
            var buf = buffer
            if let data { buf.append(data) }
            if let req = HTTPRequest.parse(buf) {
                self.respond(conn, to: req)
            } else if done || err != nil || buf.count > 1_000_000 {
                conn.cancel()
            } else {
                self.receive(conn, buffer: buf)
            }
        }
    }

    private func respond(_ conn: NWConnection, to req: HTTPRequest) {
        // The trackpad streams small batches back to back, so it gets its own, larger budget.
        let admitted = req.path == "/pointer" ? Self.admit(&recentPointer, limit: 150) : Self.admit(&recent, limit: 40)
        if !admitted { return send(conn, 429, "text/plain", "slow down") }

        if req.method == "GET", req.path == "/icon.png" {
            guard let url = Bundle.main.url(forResource: "touch-icon", withExtension: "png"),
                  let data = try? Data(contentsOf: url) else { return send(conn, 404, "text/plain", "not found") }
            return send(conn, 200, "image/png", data)
        }

        let supplied = req.headers["x-token"] ?? req.query["t"] ?? ""
        guard supplied == token() else { return send(conn, 401, "text/plain", "unauthorized") }

        switch (req.method, req.path) {
        case ("GET", "/"):
            send(conn, 200, "text/html; charset=utf-8", WebUI.html)
        case ("GET", "/status"):
            let json = (try? JSONSerialization.data(withJSONObject: Battery.status().merging(Brightness.availability()) { a, _ in a }.merging(["displayCount": ScreenPreview.displayCount()]) { a, _ in a })) ?? Data("{}".utf8)
            send(conn, 200, "application/json", json)
        case ("POST", "/cmd"):
            guard let obj = try? JSONSerialization.jsonObject(with: req.body) as? [String: Any],
                  let action = obj["action"] as? String else {
                return send(conn, 400, "text/plain", "bad request")
            }
            let result = handler(action, obj["value"] as? String)
            let json = (try? JSONSerialization.data(withJSONObject: result)) ?? Data("{}".utf8)
            send(conn, 200, "application/json", json)
        case ("POST", "/pointer"):
            let result = handler("pointer", String(decoding: req.body, as: UTF8.self))
            let json = (try? JSONSerialization.data(withJSONObject: result)) ?? Data("{}".utf8)
            send(conn, 200, "application/json", json)
        case ("GET", _):
            DispatchQueue.global().async { [self] in
                if let (status, type, body) = resource(req) { send(conn, status, type, body) }
                else { send(conn, 404, "text/plain", "not found") }
            }
        default:
            send(conn, 404, "text/plain", "not found")
        }
    }

    private static func admit(_ log: inout [Date], limit: Int) -> Bool {
        let now = Date()
        log = log.filter { now.timeIntervalSince($0) < 1 }
        guard log.count < limit else { return false }
        log.append(now)
        return true
    }

    private func send(_ conn: NWConnection, _ status: Int, _ type: String, _ body: String) {
        send(conn, status, type, Data(body.utf8))
    }

    private func send(_ conn: NWConnection, _ status: Int, _ type: String, _ payload: Data) {
        let head = "HTTP/1.1 \(status) X\r\nContent-Type: \(type)\r\nContent-Length: \(payload.count)\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n"
        conn.send(content: Data(head.utf8) + payload, completion: .contentProcessed { _ in conn.cancel() })
    }

    static func isLocal(_ endpoint: NWEndpoint) -> Bool {
        guard case .hostPort(let host, _) = endpoint else { return false }
        switch host {
        case .ipv4(let a):
            return isPrivate(Array(a.rawValue))
        case .ipv6(let a):
            let b = Array(a.rawValue)
            if b.count != 16 { return false }
            if b[0] == 0xfe && (b[1] & 0xc0) == 0x80 { return true }   // link-local
            if (b[0] & 0xfe) == 0xfc { return true }                    // unique local
            if b[0..<15].allSatisfy({ $0 == 0 }) && b[15] == 1 { return true } // ::1
            if b[0..<10].allSatisfy({ $0 == 0 }) && b[10] == 0xff && b[11] == 0xff {
                return isPrivate(Array(b[12..<16]))                     // v4-mapped
            }
            return false
        default:
            return false
        }
    }

    private static func isPrivate(_ b: [UInt8]) -> Bool {
        guard b.count == 4 else { return false }
        return b[0] == 10 || b[0] == 127
            || (b[0] == 172 && (16...31).contains(b[1]))
            || (b[0] == 192 && b[1] == 168)
            || (b[0] == 169 && b[1] == 254)
    }
}

struct HTTPRequest {
    var method: String
    var path: String
    var query: [String: String]
    var headers: [String: String]
    var body: Data

    /// Returns nil until the full request (headers + Content-Length body) is buffered.
    static func parse(_ data: Data) -> HTTPRequest? {
        guard let sep = data.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        let headText = String(decoding: data[..<sep.lowerBound], as: UTF8.self)
        var lines = headText.components(separatedBy: "\r\n")
        let start = lines.removeFirst().split(separator: " ")
        guard start.count >= 2 else { return nil }

        var headers: [String: String] = [:]
        for line in lines {
            guard let i = line.firstIndex(of: ":") else { continue }
            headers[line[..<i].lowercased()] = line[line.index(after: i)...].trimmingCharacters(in: .whitespaces)
        }
        let length = Int(headers["content-length"] ?? "") ?? 0
        let body = data[sep.upperBound...]
        guard body.count >= length else { return nil }

        let comps = URLComponents(string: String(start[1]))
        var query: [String: String] = [:]
        for item in comps?.queryItems ?? [] { query[item.name] = item.value ?? "" }
        return HTTPRequest(method: String(start[0]), path: comps?.path ?? "/", query: query,
                           headers: headers, body: Data(body.prefix(length)))
    }
}
