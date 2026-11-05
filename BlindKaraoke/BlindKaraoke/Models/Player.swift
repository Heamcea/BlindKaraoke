//
//  Player.swift
//  BlindKaraoke
//
//  Created by Hamza Ahmad
//

import Foundation

struct Player: Identifiable {
    let id = UUID()
    var name: String
    var score: Int = 0
}
