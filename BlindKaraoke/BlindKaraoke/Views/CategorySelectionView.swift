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
                List(categories) { category in
                    Text(category.name)
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
}
