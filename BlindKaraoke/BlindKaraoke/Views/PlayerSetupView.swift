//
//  PlayerSetupView.swift
//  BlindKaraoke
//
//  Created by Hamza Ahmad
//

import SwiftUI

struct PlayerSetupView: View {

    let gameMode: GameMode

    @State private var players: [Player]

    init(gameMode: GameMode) {
        self.gameMode = gameMode

        // im multiplayer -> direkt 2 spielern
        if gameMode == .singlePlayer {
            _players = State(initialValue: [
                Player(name: "")
            ])
        } else {
            _players = State(initialValue: [
                Player(name: ""),
                Player(name: "")
            ])
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                Text(
                    gameMode == .singlePlayer ? "Single Player" : "Multiplayer"
                )
                .font(.largeTitle)
                .bold()

                VStack(spacing: 12) {
                    ForEach($players) { $player in
                        HStack {
                            TextField(
                                "Player name",
                                text: $player.name
                            )
                            .textFieldStyle(.roundedBorder)

                            if gameMode == .multiplayer && players.count > 2 {
                                Button {
                                    removePlayer(player.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .foregroundStyle(.red)
                            }
                        }
                    }
                }

                if gameMode == .multiplayer {
                    Button {
                        addPlayer()
                    } label: {
                        Label(
                            "Add Player",
                            systemImage: "plus"
                        )
                    }
                    .buttonStyle(.bordered)
                    .disabled(players.count >= 8)
                }

                NavigationLink {
                    CategorySelectionView(
                        players: players
                    )
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canContinue)
            }
            .padding()
        }
        .navigationTitle("Players")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canContinue: Bool {
        let allNamesEntered = players.allSatisfy {
            !$0.name
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        }

        if gameMode == .singlePlayer {
            return players.count == 1 && allNamesEntered
        }

        return players.count >= 2 && allNamesEntered
    }

    private func addPlayer() {
        players.append(
            Player(name: "")
        )
    }

    private func removePlayer(_ id: UUID) {
        // mind. zwei spieler bleiben bei multiplayer immer drinnen
        guard players.count > 2 else {
            return
        }

        players.removeAll {
            $0.id == id
        }
    }
}

