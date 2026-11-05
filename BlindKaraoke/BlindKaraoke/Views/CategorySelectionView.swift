//
//  CategorySelectionView.swift
//  BlindKaraoke
//
//  Created by Hamza Ahmad
//

import SwiftUI

struct CategorySelectionView: View {
    
    let players: [Player]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Categories")
                .font(.largeTitle)
                .bold()
            
            Text("Players: \(players.count)")
                .foregroundStyle(.secondary)
            
            ForEach(players) { player in
                Text(player.name)
            }
        }
        .padding()
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
    }
}
