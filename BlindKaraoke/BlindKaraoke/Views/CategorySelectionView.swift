//
//  CategorySelectionView.swift
//  BlindKaraoke
//
//  Created by Hamza Ahmad
//

import SwiftUI

struct CategorySelectionView: View {

    let players: [Player]

    @State private var categories: [MusicCategory] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedCategories: Set<MusicCategory> = []
    @State private var numberOfRounds: Int? = 5
    
    private let driveAPIClient = DriveAPIClient()

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    
                    Text("Loading categories...")
                        .foregroundStyle(.secondary)
                }
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Text("Could not load categories")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                VStack {
                    List(categories) { category in
                        Button {
                            toggleCategory(category)
                        } label: {
                            HStack {
                                Text(category.name)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedCategories.contains(category) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rounds")
                            .font(.headline)

                        Picker(
                            "Rounds",
                            selection: $numberOfRounds
                        ) {
                            Text("3")
                                .tag(3 as Int?)

                            Text("5")
                                .tag(5 as Int?)

                            Text("10")
                                .tag(10 as Int?)

                            Text("∞")
                                .tag(nil as Int?)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)

                    NavigationLink {
                        GameView(
                            players: players,
                            categories: Array(selectedCategories),
                            numberOfRounds: numberOfRounds
                        )
                    } label: {
                        Text("Start Game")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedCategories.isEmpty)
                    .padding()
                }
            }
        }
        .navigationTitle("Categories")
        .onAppear {
            loadCategories()
        }
    }

    private func loadCategories() {
        driveAPIClient.fetchCategories {
            loadedCategories,
            error in

            isLoading = false

            if let loadedCategories {
                categories = loadedCategories
                return
            }

            if let error {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func toggleCategory(_ category: MusicCategory) {
        // wenn die kategorie schon ausgewählt ist entfernen wir sie wieder
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

}
