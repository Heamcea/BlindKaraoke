//
//  GameView.swift
//  BlindKaraoke
//
//  Created by Hamza Ahmad
//

import SwiftUI

private struct PlayedSongResult: Identifiable {
    let id = UUID()
    let song: Song
    let wasCorrect: Bool
}

struct GameView: View {

    @Environment(\.dismiss) private var dismiss

    let categories: [MusicCategory]
    let numberOfRounds: Int?

    @State private var gamePlayers: [Player]

    @State private var songs: [Song] = []
    @State private var remainingSongs: [Song] = []
    @State private var currentSong: Song?

    @State private var playedSongs: [PlayedSongResult] = []

    @State private var allLyrics: [String: String] = [:]

    @State private var currentPlayerIndex = 0
    @State private var currentRound = 1

    @State private var isLoading = true
    @State private var isPreparingSong = false
    @State private var isSongReady = false
    @State private var hasStartedSong = false

    @State private var didPrefetchNextSong = false

    @State private var isSongRevealed = false
    @State private var lyrics: String?
    @State private var lyricsErrorMessage: String?

    @State private var isGameFinished = false
    @State private var errorMessage: String?

    @StateObject private var audioPlayer =
        AudioPlayerManager()

    private let driveAPIClient =
        DriveAPIClient()

    init(
        players: [Player],
        categories: [MusicCategory],
        numberOfRounds: Int?
    ) {
        self.categories = categories
        self.numberOfRounds =
            numberOfRounds

        _gamePlayers = State(
            initialValue: players
        )
    }

    var body: some View {
        Group {
            if isGameFinished {
                resultsContent

            } else if isLoading
                        || isPreparingSong {

                loadingContent

            } else if let errorMessage {
                errorContent(
                    errorMessage
                )

            } else {
                gameContent
            }
        }
        .navigationTitle(
            "Blind Karaoke"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .onAppear {
            loadGame()
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }

    // MARK: - Loading

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()

            Text(
                isLoading
                ? "Loading game..."
                : "Preparing song..."
            )
            .foregroundStyle(
                .secondary
            )
        }
    }

    // MARK: - Error

    private func errorContent(
        _ message: String
    ) -> some View {
        VStack(spacing: 12) {
            Text(
                "Something went wrong"
            )
            .font(.headline)

            Text(message)
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )
        }
        .padding()
    }

    // MARK: - Game

    private var gameContent: some View {
        ScrollView {
            VStack(spacing: 24) {

                roundInformation

                playerInformation

                if !isSongRevealed {
                    Text(
                        "Your song is ready!"
                    )
                    .font(.title3)

                    Image(
                        systemName:
                            "music.note"
                    )
                    .font(
                        .system(
                            size: 70
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                if isSongReady {
                    audioControls
                }

                if isSongReady
                    && !isSongRevealed {

                    revealButton
                }

                if isSongRevealed {
                    revealedSongContent

                    resultButtons
                }

                if numberOfRounds == nil {
                    endGameButton
                }
            }
            .padding()
        }
    }

    // MARK: - Round

    private var roundInformation: some View {
        Group {
            if let numberOfRounds {
                Text(
                    "Round \(currentRound) / \(numberOfRounds)"
                )
                .font(.headline)
                .foregroundStyle(
                    .secondary
                )

            } else {
                Text(
                    "Round \(currentRound)"
                )
                .font(.headline)
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }

    // MARK: - Player

    private var playerInformation: some View {
        VStack(spacing: 6) {
            Text(
                currentPlayer.name
            )
            .font(.largeTitle)
            .bold()

            Text(
                "Score: \(currentPlayer.score)"
            )
            .foregroundStyle(
                .secondary
            )
        }
    }

    // MARK: - Audio Controls

    private var audioControls: some View {
        HStack(spacing: 12) {

            Button {
                playOrRestartSong()
            } label: {
                Label(
                    hasStartedSong
                    ? "Restart"
                    : "Start",
                    systemImage:
                        hasStartedSong
                        ? "arrow.counterclockwise"
                        : "play.fill"
                )
                .frame(
                    maxWidth: .infinity
                )
                .padding()
            }
            .buttonStyle(
                .borderedProminent
            )

            if hasStartedSong {
                Button {
                    stopSong()
                } label: {
                    Label(
                        "Stop",
                        systemImage:
                            "stop.fill"
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                    .padding()
                }
                .buttonStyle(
                    .bordered
                )
            }
        }
    }

    // MARK: - Reveal

    private var revealButton: some View {
        Button {
            revealSong()
        } label: {
            Label(
                "Reveal Song",
                systemImage:
                    "eye.fill"
            )
            .frame(
                maxWidth: .infinity
            )
            .padding()
        }
        .buttonStyle(
            .bordered
        )
    }

    private var revealedSongContent: some View {
        VStack(spacing: 16) {

            Divider()

            if let currentSong {
                Text(
                    currentSong.title
                )
                .font(.title)
                .bold()
                .multilineTextAlignment(
                    .center
                )

                Text(
                    currentSong.artist
                )
                .font(.title3)
                .foregroundStyle(
                    .secondary
                )

                Text(
                    currentSong
                        .category
                        .name
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }

            Divider()

            Text("Lyrics")
                .font(.headline)

            if let lyrics {
                Text(lyrics)
                    .frame(
                        maxWidth:
                            .infinity,
                        alignment:
                            .leading
                    )

            } else if let lyricsErrorMessage {
                Text(
                    lyricsErrorMessage
                )
                .foregroundStyle(
                    .secondary
                )

            } else {
                Text(
                    "No lyrics available."
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }

    // MARK: - Result Buttons

    private var resultButtons: some View {
        VStack(spacing: 12) {

            Text(
                "Did you get it?"
            )
            .font(.headline)

            HStack(spacing: 12) {

                Button {
                    submitResult(
                        success: true
                    )
                } label: {
                    Label(
                        "Correct",
                        systemImage:
                            "checkmark"
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                    .padding()
                }
                .buttonStyle(
                    .borderedProminent
                )

                Button {
                    submitResult(
                        success: false
                    )
                } label: {
                    Label(
                        "Wrong",
                        systemImage:
                            "xmark"
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                    .padding()
                }
                .buttonStyle(
                    .bordered
                )
            }
        }
        .padding(.top)
    }

    // MARK: - End Game

    private var endGameButton: some View {
        Button(
            role: .destructive
        ) {
            finishGame()
        } label: {
            Label(
                "End Game",
                systemImage:
                    "flag.checkered"
            )
        }
        .padding(.top)
    }

    // MARK: - Results

    private var resultsContent: some View {
        ScrollView {
            VStack(spacing: 24) {

                Image(
                    systemName:
                        "trophy.fill"
                )
                .font(
                    .system(
                        size: 60
                    )
                )

                Text("Results")
                    .font(.largeTitle)
                    .bold()

                Text(
                    playedRounds == 1
                    ? "1 Round played"
                    : "\(playedRounds) Rounds played"
                )
                .font(.headline)
                .foregroundStyle(
                    .secondary
                )

                if gamePlayers.count == 1 {
                    singlePlayerResults
                } else {
                    multiplayerResults
                }

                Button {
                    audioPlayer.stop()
                    dismiss()
                } label: {
                    Label(
                        "Play Again",
                        systemImage:
                            "arrow.counterclockwise"
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                    .padding()
                }
                .buttonStyle(
                    .borderedProminent
                )
            }
            .padding()
        }
    }

    // MARK: - Single Player Results

    private var singlePlayerResults: some View {
        VStack(spacing: 20) {

            Text(
                "\(gamePlayers[0].score) of \(playedSongs.count) correct"
            )
            .font(.title2)
            .bold()

            VStack(spacing: 10) {
                ForEach(
                    playedSongs
                ) { result in

                    HStack(spacing: 12) {

                        Image(
                            systemName:
                                result.wasCorrect
                                ? "checkmark.circle.fill"
                                : "xmark.circle.fill"
                        )

                        VStack(
                            alignment:
                                .leading,
                            spacing: 3
                        ) {
                            Text(
                                result
                                    .song
                                    .title
                            )
                            .font(
                                .headline
                            )

                            Text(
                                result
                                    .song
                                    .artist
                            )
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .secondary
                            )
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        .secondary
                            .opacity(0.1)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                12
                        )
                    )
                }
            }
        }
    }

    // MARK: - Multiplayer Results

    private var multiplayerResults: some View {
        VStack(spacing: 12) {
            ForEach(
                sortedPlayers
            ) { player in

                HStack {
                    Text(
                        player.name
                    )
                    .font(.headline)

                    Spacer()

                    Text(
                        player.score == 1
                        ? "1 Point"
                        : "\(player.score) Points"
                    )
                    .bold()
                }
                .padding()
                .background(
                    .secondary
                        .opacity(0.1)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )
            }
        }
    }

    // MARK: - Values

    private var currentPlayer: Player {
        gamePlayers[
            currentPlayerIndex
        ]
    }

    private var sortedPlayers: [Player] {
        gamePlayers.sorted {
            $0.score > $1.score
        }
    }

    private var playedRounds: Int {
        guard !gamePlayers.isEmpty,
              !playedSongs.isEmpty else {
            return 0
        }

        return (
            playedSongs.count
            + gamePlayers.count
            - 1
        ) / gamePlayers.count
    }

    private var hasAnotherTurn: Bool {

        if currentPlayerIndex
            < gamePlayers.count - 1 {

            return true
        }

        if let numberOfRounds {
            return currentRound
                < numberOfRounds
        }

        return true
    }

    // MARK: - Load Game

    private func loadGame() {

        guard songs.isEmpty else {
            return
        }

        // lyrics.json laden wir nur einmal und halten danach alles im speicher
        driveAPIClient.fetchLyrics {
            loadedLyrics,
            lyricsError in

            if let loadedLyrics {
                allLyrics =
                    loadedLyrics
            }

            if let lyricsError {
                #if DEBUG
                print(
                    "Lyrics could not be loaded:",
                    lyricsError
                        .localizedDescription
                )
                #endif
            }

            loadSongs()
        }
    }

    private func loadSongs() {
        driveAPIClient.fetchSongs(
            categories: categories
        ) { loadedSongs, error in

            isLoading = false

            if let loadedSongs {
                guard !loadedSongs
                    .isEmpty else {

                    errorMessage =
                        "No songs found."
                    return
                }

                songs =
                    loadedSongs

                remainingSongs =
                    loadedSongs
                        .shuffled()

                prepareNextSong()
                return
            }

            if let error {
                errorMessage =
                    error
                        .localizedDescription
            }
        }
    }

    // MARK: - Song Selection

    private func refillSongsIfNeeded() {

        guard remainingSongs.isEmpty else {
            return
        }

        remainingSongs =
            songs.shuffled()

        // denselben song nicht direkt zweimal hintereinander nehmen
        if songs.count > 1,
           let currentSong,
           remainingSongs.first?.id
                == currentSong.id {

            remainingSongs.swapAt(
                0,
                1
            )
        }
    }

    private func prepareNextSong() {

        guard !songs.isEmpty else {
            errorMessage =
                "No song available."
            return
        }

        audioPlayer.stop()

        refillSongsIfNeeded()

        let song =
            remainingSongs
                .removeFirst()

        currentSong = song

        isPreparingSong = true
        isSongReady = false
        hasStartedSong = false

        didPrefetchNextSong = false

        isSongRevealed = false

        lyrics = nil
        lyricsErrorMessage = nil

        #if DEBUG
        print(
            "Preparing song: \(song.artist) - \(song.title)"
        )
        #endif

        driveAPIClient
            .downloadAudioFile(
                fileID:
                    song.audioFileID
            ) { localURL, error in

                isPreparingSong =
                    false

                if let localURL {
                    do {
                        try audioPlayer
                            .prepareAudio(
                                from:
                                    localURL
                            )

                        isSongReady =
                            true

                    } catch {
                        errorMessage =
                            error
                                .localizedDescription
                    }

                    return
                }

                if let error {
                    errorMessage =
                        error
                            .localizedDescription
                }
            }
    }

    // MARK: - Prefetch

    private func prefetchNextSong() {

        guard hasAnotherTurn else {
            return
        }

        refillSongsIfNeeded()

        guard let nextSong =
                remainingSongs.first else {
            return
        }

        #if DEBUG
        print(
            "Prefetching next song: \(nextSong.artist) - \(nextSong.title)"
        )
        #endif

        driveAPIClient
            .downloadAudioFile(
                fileID:
                    nextSong.audioFileID
            ) { _, error in

                #if DEBUG
                if let error {
                    print(
                        "Prefetch failed:",
                        error
                            .localizedDescription
                    )
                } else {
                    print(
                        "Next song is ready in cache"
                    )
                }
                #endif
            }
    }

    // MARK: - Play Audio

    private func playOrRestartSong() {

        if hasStartedSong {
            audioPlayer.restart()

        } else {
            audioPlayer.play()

            hasStartedSong = true

            // während der aktuelle song läuft laden wir schon den nächsten
            if !didPrefetchNextSong {
                didPrefetchNextSong =
                    true

                prefetchNextSong()
            }
        }
    }

    private func stopSong() {
        audioPlayer.stop()

        hasStartedSong =
            false
    }

    // MARK: - Reveal Song

    private func revealSong() {

        isSongRevealed = true

        guard let currentSong else {
            return
        }

        let key =
            "\(currentSong.artist)__\(currentSong.title)"

        if let songLyrics =
            allLyrics[key] {

            lyrics = songLyrics

        } else {
            lyricsErrorMessage =
                "No lyrics available."
        }
    }

    // MARK: - Result

    private func submitResult(
        success: Bool
    ) {
        audioPlayer.stop()

        if success {
            gamePlayers[
                currentPlayerIndex
            ].score += 1
        }

        if let currentSong {
            playedSongs.append(
                PlayedSongResult(
                    song:
                        currentSong,
                    wasCorrect:
                        success
                )
            )
        }

        moveToNextTurn()
    }

    // MARK: - Next Turn

    private func moveToNextTurn() {

        if currentPlayerIndex
            < gamePlayers.count - 1 {

            currentPlayerIndex += 1

            prepareNextSong()
            return
        }

        if let numberOfRounds,
           currentRound >=
            numberOfRounds {

            finishGame()
            return
        }

        currentPlayerIndex = 0
        currentRound += 1

        prepareNextSong()
    }

    // MARK: - Finish Game

    private func finishGame() {
        audioPlayer.stop()

        isGameFinished = true
        isSongReady = false
    }
}


