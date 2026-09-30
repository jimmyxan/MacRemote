import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Reads what the Mac is playing. Main source: system MediaRemote (any app or browser tab: Netflix, YouTube, Music...),
/// read through /usr/bin/perl because macOS 15.4+ denies MediaRemote to third-party binaries.
/// Fallback when the helper dylib is missing (plain `swift build`): AppleScript for Music and Spotify, queried only while running.
enum NowPlaying {
    private struct Player {
        let name: String
        let bundleID: String
        let script: String
    }

    private static let sep = "\u{1F}"
    private static let players = [
        Player(name: "Spotify", bundleID: "com.spotify.client", script: """
            tell application "Spotify"
              if player state is stopped then return "stopped"
              set t to current track
              set s to character id 31
              return (player state as text) & s & (name of t) & s & (artist of t) & s & (album of t) & s & (duration of t) & s & (player position) & s & (artwork url of t)
            end tell
            """),
        Player(name: "Music", bundleID: "com.apple.Music", script: """
            tell application "Music"
              if player state is stopped then return "stopped"
              set t to current track
              set s to character id 31
              return (player state as text) & s & (name of t) & s & (artist of t) & s & (album of t) & s & (duration of t) & s & (player position) & s & ""
            end tell
            """),
    ]

    private static let lock = NSLock()
    private static var cached: (date: Date, json: [String: Any])?
    /// A paused track stays visible only shortly after it was playing; otherwise a long-paused
    /// item (e.g. an old video in Music) would hide whatever is really being played elsewhere.
    private static let pausedGrace: TimeInterval = 600
    private static var lastPlaying = Date.distantPast
    private static var artURLs: [String: String] = [:]
    private static var artCache: [String: (mime: String, data: Data)] = [:]

    static func current() -> [String: Any] {
        lock.lock()
        if let c = cached, Date().timeIntervalSince(c.date) < 1 { lock.unlock(); return c.json }
        lock.unlock()

        if let viaSystem = systemNowPlaying() {
            lock.lock()
            cached = (Date(), viaSystem)
            lock.unlock()
            return viaSystem
        }

        let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        var paused: [String: Any]?
        var result: [String: Any] = ["active": false]
        for p in players where running.contains(p.bundleID) {
            guard let info = query(p) else { continue }
            if info["playing"] as? Bool == true { paused = nil; result = info; break }
            if paused == nil { paused = info }
        }
        lock.lock()
        if result["playing"] as? Bool == true { lastPlaying = Date() }
        else if let paused, Date().timeIntervalSince(lastPlaying) < pausedGrace { result = paused }
        cached = (Date(), result)
        lock.unlock()
        return result
    }

    private static let perlLoader = """
        use DynaLoader;
        my $lib = DynaLoader::dl_load_file($ARGV[0], 0) or exit 1;
        my $sym = DynaLoader::dl_find_symbol($lib, "macremote_nowplaying") or exit 1;
        my $xs = DynaLoader::dl_install_xsub("main::np", $sym);
        &$xs("main::np");
        """

    /// nil when the helper is unavailable or failed (caller falls back to AppleScript); [active: false] when nothing is playing.
    private static func systemNowPlaying() -> [String: Any]? {
        guard let lib = Bundle.main.path(forResource: "libmediaremote", ofType: "dylib"),
              let out = run("/usr/bin/perl", ["-e", perlLoader, lib]),
              let info = (try? JSONSerialization.jsonObject(with: Data(out.utf8))) as? [String: Any],
              info["error"] == nil else { return nil }

        let prefix = "kMRMediaRemoteNowPlayingInfo"
        func str(_ k: String) -> String { info[prefix + k] as? String ?? "" }
        func num(_ k: String) -> Double? { (info[prefix + k] as? NSNumber)?.doubleValue }

        let title = str("Title"), artist = str("Artist"), album = str("Album")
        let duration = num("Duration") ?? 0
        guard !title.isEmpty || !artist.isEmpty || duration > 0 else { return ["active": false] }

        let rate = num("PlaybackRate")
        // Some sources (browsers) report one signal but not the other: either means playing.
        let playing = (info["_playing"] as? NSNumber)?.intValue == 1 || (rate ?? 0) > 0
        var position = num("ElapsedTime") ?? 0
        let stamp = num("Timestamp")
        if playing, let stamp { position += max(0, Date().timeIntervalSince1970 - stamp) * (rate ?? 1) }
        if duration > 0 { position = min(position, duration) }
        // Paused items stay visible only for a while after they were last updated (paused).
        if !playing, let stamp, Date().timeIntervalSince1970 - stamp > pausedGrace { return ["active": false] }

        let key = "MR|\(title)|\(artist)|\(album)|\(str("ContentItemIdentifier"))"
        if let art = info[prefix + "ArtworkData"] as? String, art.hasPrefix("data:"),
           let raw = Data(base64Encoded: String(art.dropFirst(5))), let (mime, data) = browserImage(raw) {
            lock.lock()
            if artCache.count > 4 { artCache.removeAll() }
            artCache[key] = (mime, data)
            lock.unlock()
        }
        return ["active": true, "playing": playing, "title": title.isEmpty ? "Contenuto multimediale" : title,
                "artist": artist, "album": album, "duration": duration, "position": position, "art": key]
    }

    private static func query(_ p: Player) -> [String: Any]? {
        guard let out = osascript(p.script), out != "stopped" else { return nil }
        let f = out.components(separatedBy: sep)
        guard f.count >= 7, !f[1].isEmpty else { return nil }
        var duration = number(f[4])
        if p.name == "Spotify" { duration /= 1000 }   // Spotify reports milliseconds, Music seconds
        let key = "\(p.name)|\(f[1])|\(f[2])|\(f[3])"
        if !f[6].isEmpty { lock.lock(); artURLs[key] = f[6]; lock.unlock() }
        return ["active": true, "app": p.name, "playing": f[0] == "playing",
                "title": f[1], "artist": f[2], "album": f[3],
                "duration": duration, "position": number(f[5]), "art": key]
    }

    /// Artwork for a key previously returned by `current()`, cached per track.
    static func artwork(key: String) -> (mime: String, data: Data)? {
        lock.lock()
        if let hit = artCache[key] { lock.unlock(); return hit }
        let url = artURLs[key]
        lock.unlock()

        var data: Data?
        if key.hasPrefix("Spotify|") {
            if let url, let u = URL(string: url) { data = download(u) }
        } else if key.hasPrefix("Music|") {
            data = musicArtwork()
        }
        guard let data, let mime = mimeType(data) else { return nil }
        lock.lock()
        if artCache.count > 4 { artCache.removeAll() }
        artCache[key] = (mime, data)
        lock.unlock()
        return (mime, data)
    }

    private static func musicArtwork() -> Data? {
        let path = NSTemporaryDirectory() + "macremote-art-\(ProcessInfo.processInfo.processIdentifier)"
        defer { try? FileManager.default.removeItem(atPath: path) }
        let script = """
            tell application "Music"
              try
                set d to raw data of artwork 1 of current track
              on error
                return "none"
              end try
              set f to open for access POSIX file "\(path)" with write permission
              set eof f to 0
              write d to f
              close access f
              return "ok"
            end tell
            """
        guard osascript(script) == "ok" else { return nil }
        return try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    private static func download(_ url: URL) -> Data? {
        guard url.scheme == "https" else { return nil }
        let sem = DispatchSemaphore(value: 0)
        var out: Data?
        var req = URLRequest(url: url)
        req.timeoutInterval = 4
        URLSession.shared.dataTask(with: req) { d, _, _ in out = d; sem.signal() }.resume()
        _ = sem.wait(timeout: .now() + 5)
        return out
    }

    /// Artwork as a format every browser shows. MediaRemote sometimes sends TIFF while declaring JPEG.
    private static func browserImage(_ d: Data) -> (String, Data)? {
        if let m = mimeType(d) { return (m, d) }
        guard let src = CGImageSourceCreateWithData(d as CFData, nil), let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, img, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        return CGImageDestinationFinalize(dest) ? ("image/jpeg", out as Data) : nil
    }

    private static func mimeType(_ d: Data) -> String? {
        if d.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
        if d.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "image/png" }
        return nil
    }

    private static func number(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    /// Runs a script with a hard timeout so a hung player can't stall the server.
    private static func osascript(_ script: String, timeout: TimeInterval = 4) -> String? {
        run("/usr/bin/osascript", ["-e", script], timeout: timeout)
    }

    private static func run(_ executable: String, _ args: [String], timeout: TimeInterval = 4) -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: executable)
        proc.arguments = args
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        let done = DispatchSemaphore(value: 0)
        proc.terminationHandler = { _ in done.signal() }
        do { try proc.run() } catch { return nil }
        // Drain stdout while the process runs: artwork can exceed the 64 KB pipe buffer and would block the writer.
        var data = Data()
        let drained = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            data = pipe.fileHandleForReading.readDataToEndOfFile()
            drained.signal()
        }
        if done.wait(timeout: .now() + timeout) == .timedOut { proc.terminate(); return nil }
        guard proc.terminationStatus == 0 else { return nil }
        drained.wait()
        return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .newlines)
    }
}
