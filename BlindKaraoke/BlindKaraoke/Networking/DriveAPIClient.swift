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
            ),
        ]

        guard let url = components?.url else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let task = URLSession.shared.dataTask(
            with: request
        ) { data, response, error in

            if let error {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }

            guard let data else {
                DispatchQueue.main.async {
                    completionHandler(nil, URLError(.badServerResponse))
                }
                return
            }

            #if DEBUG
            print(
                String(data: data, encoding: .utf8)
                ?? "Drive response could not be printed"
            )
            #endif

            do {
                let response = try JSONDecoder().decode(
                    DriveFileListResponse.self,
                    from: data
                )

                // aus den Drive-Ordner-Name werden die Kategorien erstellt
                let categories = response.files.map {
                    MusicCategory(
                        id: $0.id,
                        name: $0.name
                    )
                }

                DispatchQueue.main.async {
                    completionHandler(categories, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        }

        task.resume()
    }
}
