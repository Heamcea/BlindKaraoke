//
//  ContentView.swift
//  BlindKaraoke
//
//  Created by Hamza Ahmad
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Logo")
                .font(.system(size: 70))
            
            Text("Blind Karaoke")
                .font(.largeTitle)
                .bold()
            
            Button("Single Player"){
                
            }
            
            Button("Multiplayer"){
                
            }
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
