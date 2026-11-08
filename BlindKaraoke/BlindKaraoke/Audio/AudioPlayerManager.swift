//
//  AudioPlayerManager.swift
//  BlindKaraoke
//
//  Created by Hamza Ahmad
//

import Foundation
import AVFoundation
import Combine

final class AudioPlayerManager: ObservableObject {

    private var audioPlayer: AVAudioPlayer?

    func prepareAudio(from url: URL) throws {
        let audioSession = AVAudioSession.sharedInstance()

        try audioSession.setCategory(
            .playback,
            mode: .default
        )

        try audioSession.setActive(true)

        audioPlayer = try AVAudioPlayer(
            contentsOf: url
        )

        // lädt den song schon in den player, spielt ihn aber noch nicht ab
        audioPlayer?.prepareToPlay()
    }

    func play() {
        audioPlayer?.play()
    }

    func restart() {
        // beim neustart springen wir einfach wieder auf sekunde 0
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
    }
}


