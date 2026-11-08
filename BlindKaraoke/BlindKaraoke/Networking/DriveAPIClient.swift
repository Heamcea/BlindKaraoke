//
//  DriveAPIClient.swift
//  BlindKaraoke
//
//  Created by Hamza Ahmad
//

import Foundation

class DriveAPIClient {

    private let apiKey = Secrets.googleAPIKey
    private let rootFolderID = Secrets.rootFolderID

    private let urlSession = URLSession(
        configuration: .default
    )

    // MARK: - Categories

    func fetchCategories(
        completionHandler: @escaping ([MusicCategory]?, Error?) -> Void
    ) {
        var components = URLComponents(
            string: "https://www.googleapis.com/drive/v3/files"
        )

        let query = """
        '\(rootFolderID)' in parents and \
        mimeType = 'application/vnd.google-apps.folder' and \
        trashed = false
        """

        components?.queryItems = [
            URLQueryItem(
                name: "q",
                value: query
            ),
            URLQueryItem(
                name: "fields",
                value: "files(id,name,mimeType)"
            ),
            URLQueryItem(
                name: "orderBy",
                value: "name"
            )
        ]

        guard let url = components?.url else {
            completionHandler(
                nil,
                URLError(.badURL)
            )
            return
        }

        var request = URLRequest(url: url)
        addHeaders(to: &request)

        urlSession.dataTask(
            with: request
        ) { data, response, error in

            if let error {
                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        error
                    )
                }
                return
            }

            guard let httpResponse =
                    response as? HTTPURLResponse,
                  (200..<300).contains(
                    httpResponse.statusCode
                  ),
                  let data else {

                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        URLError(
                            .badServerResponse
                        )
                    )
                }
                return
            }

            do {
                let response =
                    try JSONDecoder().decode(
                        DriveFileListResponse.self,
                        from: data
                    )

                let categories =
                    response.files.map {
                        MusicCategory(
                            id: $0.id,
                            name: $0.name
                        )
                    }

                DispatchQueue.main.async {
                    completionHandler(
                        categories,
                        nil
                    )
                }

            } catch {
                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        error
                    )
                }
            }
        }
        .resume()
    }

    // MARK: - Songs

    func fetchSongs(
        categories: [MusicCategory],
        completionHandler: @escaping ([Song]?, Error?) -> Void
    ) {
        let group = DispatchGroup()
        let lock = NSLock()

        var allSongs: [Song] = []
        var firstError: Error?

        for category in categories {
            group.enter()

            fetchFiles(
                folderID: category.id
            ) { files, error in

                if let files {
                    let songs = self.createSongs(
                        from: files,
                        category: category
                    )

                    lock.lock()
                    allSongs.append(
                        contentsOf: songs
                    )
                    lock.unlock()

                } else if let error {
                    lock.lock()

                    if firstError == nil {
                        firstError = error
                    }

                    lock.unlock()
                }

                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let firstError {
                completionHandler(
                    nil,
                    firstError
                )
                return
            }

            completionHandler(
                allSongs,
                nil
            )
        }
    }

    private func fetchFiles(
        folderID: String,
        completionHandler: @escaping ([DriveFile]?, Error?) -> Void
    ) {
        var components = URLComponents(
            string: "https://www.googleapis.com/drive/v3/files"
        )

        let query = """
        '\(folderID)' in parents and trashed = false
        """

        components?.queryItems = [
            URLQueryItem(
                name: "q",
                value: query
            ),
            URLQueryItem(
                name: "fields",
                value: "files(id,name,mimeType)"
            ),
            URLQueryItem(
                name: "pageSize",
                value: "1000"
            )
        ]

        guard let url = components?.url else {
            completionHandler(
                nil,
                URLError(.badURL)
            )
            return
        }

        var request = URLRequest(url: url)
        addHeaders(to: &request)

        urlSession.dataTask(
            with: request
        ) { data, response, error in

            if let error {
                completionHandler(
                    nil,
                    error
                )
                return
            }

            guard let httpResponse =
                    response as? HTTPURLResponse,
                  (200..<300).contains(
                    httpResponse.statusCode
                  ),
                  let data else {

                completionHandler(
                    nil,
                    URLError(
                        .badServerResponse
                    )
                )
                return
            }

            do {
                let response =
                    try JSONDecoder().decode(
                        DriveFileListResponse.self,
                        from: data
                    )

                completionHandler(
                    response.files,
                    nil
                )

            } catch {
                completionHandler(
                    nil,
                    error
                )
            }
        }
        .resume()
    }

    private func createSongs(
        from files: [DriveFile],
        category: MusicCategory
    ) -> [Song] {

        let audioFiles = files.filter {
            $0.name
                .lowercased()
                .hasSuffix(".m4a")
        }

        var songs: [Song] = []

        for audioFile in audioFiles {

            let fileName = audioFile.name
                .replacingOccurrences(
                    of: ".m4a",
                    with: "",
                    options: .caseInsensitive
                )

            let parts = fileName.components(
                separatedBy: "__"
            )

            guard parts.count == 2 else {
                continue
            }

            let song = Song(
                id: audioFile.id,
                artist: parts[0],
                title: parts[1],
                audioFileID: audioFile.id,
                category: category
            )

            songs.append(song)
        }

        return songs
    }

    // MARK: - Lyrics

    func fetchLyrics(
        completionHandler: @escaping ([String: String]?, Error?) -> Void
    ) {
        let cacheURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "lyrics.json"
            )

        // wenn lyrics.json schon lokal vorhanden ist verwenden wir den cache
        if FileManager.default.fileExists(
            atPath: cacheURL.path
        ) {
            do {
                let data = try Data(
                    contentsOf: cacheURL
                )

                let lyrics =
                    try JSONDecoder().decode(
                        [String: String].self,
                        from: data
                    )

                #if DEBUG
                print(
                    "Using cached lyrics.json"
                )
                #endif

                DispatchQueue.main.async {
                    completionHandler(
                        lyrics,
                        nil
                    )
                }

                return

            } catch {
                try? FileManager.default.removeItem(
                    at: cacheURL
                )
            }
        }

        findLyricsFile { fileID, error in

            if let error {
                completionHandler(
                    nil,
                    error
                )
                return
            }

            guard let fileID else {
                completionHandler(
                    nil,
                    URLError(
                        .fileDoesNotExist
                    )
                )
                return
            }

            self.downloadLyricsJSON(
                fileID: fileID,
                cacheURL: cacheURL,
                completionHandler:
                    completionHandler
            )
        }
    }

    private func findLyricsFile(
        completionHandler: @escaping (String?, Error?) -> Void
    ) {
        var components = URLComponents(
            string: "https://www.googleapis.com/drive/v3/files"
        )

        let query = """
        '\(rootFolderID)' in parents and \
        name = 'lyrics.json' and \
        trashed = false
        """

        components?.queryItems = [
            URLQueryItem(
                name: "q",
                value: query
            ),
            URLQueryItem(
                name: "fields",
                value: "files(id,name,mimeType)"
            )
        ]

        guard let url = components?.url else {
            completionHandler(
                nil,
                URLError(.badURL)
            )
            return
        }

        var request = URLRequest(url: url)
        addHeaders(to: &request)

        urlSession.dataTask(
            with: request
        ) { data, response, error in

            if let error {
                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        error
                    )
                }
                return
            }

            guard let httpResponse =
                    response as? HTTPURLResponse,
                  (200..<300).contains(
                    httpResponse.statusCode
                  ),
                  let data else {

                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        URLError(
                            .badServerResponse
                        )
                    )
                }
                return
            }

            do {
                let response =
                    try JSONDecoder().decode(
                        DriveFileListResponse.self,
                        from: data
                    )

                DispatchQueue.main.async {
                    completionHandler(
                        response.files.first?.id,
                        nil
                    )
                }

            } catch {
                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        error
                    )
                }
            }
        }
        .resume()
    }

    private func downloadLyricsJSON(
        fileID: String,
        cacheURL: URL,
        completionHandler: @escaping ([String: String]?, Error?) -> Void
    ) {
        var components = URLComponents(
            string:
                "https://www.googleapis.com/drive/v3/files/\(fileID)"
        )

        components?.queryItems = [
            URLQueryItem(
                name: "alt",
                value: "media"
            )
        ]

        guard let url = components?.url else {
            completionHandler(
                nil,
                URLError(.badURL)
            )
            return
        }

        var request = URLRequest(url: url)
        addHeaders(to: &request)

        urlSession.dataTask(
            with: request
        ) { data, response, error in

            if let error {
                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        error
                    )
                }
                return
            }

            guard let httpResponse =
                    response as? HTTPURLResponse else {

                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        URLError(
                            .badServerResponse
                        )
                    )
                }
                return
            }

            #if DEBUG
            print(
                "Lyrics HTTP status:",
                httpResponse.statusCode
            )
            #endif

            guard (200..<300).contains(
                httpResponse.statusCode
            ) else {

                #if DEBUG
                if let data,
                   let responseText = String(
                        data: data,
                        encoding: .utf8
                   ) {

                    print(
                        "Lyrics Google response:",
                        responseText
                    )
                }
                #endif

                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        URLError(
                            .badServerResponse
                        )
                    )
                }
                return
            }

            guard let data else {
                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        URLError(
                            .cannotDecodeContentData
                        )
                    )
                }
                return
            }

            do {
                let lyrics =
                    try JSONDecoder().decode(
                        [String: String].self,
                        from: data
                    )

                try data.write(
                    to: cacheURL
                )

                #if DEBUG
                print(
                    "Loaded \(lyrics.count) lyrics"
                )

                print(
                    "Lyrics saved at:",
                    cacheURL.path
                )
                #endif

                DispatchQueue.main.async {
                    completionHandler(
                        lyrics,
                        nil
                    )
                }

            } catch {
                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        error
                    )
                }
            }
        }
        .resume()
    }

    // MARK: - Audio

    func downloadAudioFile(
        fileID: String,
        completionHandler: @escaping (URL?, Error?) -> Void
    ) {
        let targetURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "\(fileID).m4a"
            )

        // bereits heruntergeladene songs verwenden wir wieder
        if FileManager.default.fileExists(
            atPath: targetURL.path
        ) {
            do {
                let attributes =
                    try FileManager.default
                        .attributesOfItem(
                            atPath:
                                targetURL.path
                        )

                let fileSize =
                    attributes[.size]
                        as? Int ?? 0

                if fileSize > 0 {
                    #if DEBUG
                    print(
                        "Using cached audio: \(targetURL.lastPathComponent)"
                    )
                    #endif

                    DispatchQueue.main.async {
                        completionHandler(
                            targetURL,
                            nil
                        )
                    }

                    return
                }

                try FileManager.default
                    .removeItem(
                        at: targetURL
                    )

            } catch {
                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        error
                    )
                }
                return
            }
        }

        var components = URLComponents(
            string:
                "https://www.googleapis.com/drive/v3/files/\(fileID)"
        )

        components?.queryItems = [
            URLQueryItem(
                name: "alt",
                value: "media"
            )
        ]

        guard let url = components?.url else {
            completionHandler(
                nil,
                URLError(.badURL)
            )
            return
        }

        var request = URLRequest(url: url)
        addHeaders(to: &request)

        urlSession.downloadTask(
            with: request
        ) {
            temporaryURL,
            response,
            error in

            if let error {
                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        error
                    )
                }
                return
            }

            guard let httpResponse =
                    response as? HTTPURLResponse else {

                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        URLError(
                            .badServerResponse
                        )
                    )
                }
                return
            }

            #if DEBUG
            print(
                "HTTP status:",
                httpResponse.statusCode
            )

            print(
                "Content-Type:",
                httpResponse.value(
                    forHTTPHeaderField:
                        "Content-Type"
                ) ?? "unknown"
            )
            #endif

            guard (200..<300).contains(
                httpResponse.statusCode
            ) else {

                #if DEBUG
                if let temporaryURL,
                   let data = try? Data(
                        contentsOf:
                            temporaryURL
                   ),
                   let responseText = String(
                        data: data,
                        encoding: .utf8
                   ) {

                    print(
                        "Google response:",
                        responseText
                    )
                }
                #endif

                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        URLError(
                            .badServerResponse
                        )
                    )
                }

                return
            }

            guard let temporaryURL else {
                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        URLError(
                            .cannotCreateFile
                        )
                    )
                }
                return
            }

            do {
                try FileManager.default
                    .moveItem(
                        at: temporaryURL,
                        to: targetURL
                    )

                #if DEBUG
                let attributes =
                    try FileManager.default
                        .attributesOfItem(
                            atPath:
                                targetURL.path
                        )

                let fileSize =
                    attributes[.size]
                        as? Int ?? 0

                print(
                    "Downloaded bytes:",
                    fileSize
                )

                print(
                    "Saved at:",
                    targetURL.path
                )
                #endif

                DispatchQueue.main.async {
                    completionHandler(
                        targetURL,
                        nil
                    )
                }

            } catch {
                DispatchQueue.main.async {
                    completionHandler(
                        nil,
                        error
                    )
                }
            }
        }
        .resume()
    }

    // MARK: - Headers

    private func addHeaders(
        to request: inout URLRequest
    ) {
        request.setValue(
            apiKey,
            forHTTPHeaderField:
                "x-goog-api-key"
        )

        if let bundleID =
            Bundle.main.bundleIdentifier {

            request.setValue(
                bundleID,
                forHTTPHeaderField:
                    "X-Ios-Bundle-Identifier"
            )
        }
    }
}


