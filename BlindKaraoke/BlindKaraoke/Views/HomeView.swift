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
            
            NavigationLink {
                     PlayerSetupView(gameMode: .singlePlayer)
                 } label: {
                     Text("Single Player")
                         .frame(maxWidth: .infinity)
                         .padding()
                 }
                 .buttonStyle(.borderedProminent)

                 NavigationLink {
                     PlayerSetupView(gameMode: .multiplayer)
                 } label: {
                     Text("Multiplayer")
                         .frame(maxWidth: .infinity)
                         .padding()
                 }
                 .buttonStyle(.bordered)

             }
             .padding()
         }
     }

#Preview {
    HomeView()
}
