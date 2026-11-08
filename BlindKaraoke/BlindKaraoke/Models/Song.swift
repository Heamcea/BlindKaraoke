//
//  Song.swift
//  BlindKaraoke
//
//  Created by Hamza Ahmad
//

import Foundation

struct Song: Identifiable, Hashable {
    let id: String
    let artist: String
    let title: String
    let audioFileID: String
    let category: MusicCategory
}
