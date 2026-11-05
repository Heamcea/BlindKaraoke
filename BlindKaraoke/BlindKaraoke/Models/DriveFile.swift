//
//  DriveFile.swift
//  BlindKaraoke
//
//  Created by Hamza Ahmad
//

import Foundation

struct DriveFile: Decodable {
    let id: String
    let name: String
    let mimeType: String
}

struct DriveFileListResponse: Decodable {
    let files: [DriveFile]
}
