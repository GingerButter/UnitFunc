//
//  ContentView.swift
//  Shared
//
//  Created by Andy Jin on 7/31/23.
//

import SwiftUI
import MediaPlayer
import UIKit
import MobileCoreServices

struct ContentView: View {
//    var body: some View {
//        Text("Hello, world!")
//            .onAppear {
//                guard let url = Bundle.main.url(forResource: "Pallas", withExtension: "wav") else {
//                    fatalError("Failed to locate file in bundle.")
//                }
//                let data = readAudioFile(url: url)
//                FFT(data: data)
////                showFormat(url: url)
//            }
//            .padding()
//    }
    @State private var mediaItems: [MPMediaItem] = []
    @State private var showingMediaPicker = false
    @State private var players: [AVPlayer] = []

    var body: some View {
        VStack {
            Button("Select Songs") {
                self.showingMediaPicker = true
            }

            Button("Play Songs") {
                self.playSongs()
            }
        }
        .sheet(isPresented: $showingMediaPicker) {
            MediaPicker(mediaItems: self.$mediaItems)
        }
    }

    func playSongs() {
        players.forEach { $0.pause() }  // Stop any previously playing songs
        players.removeAll()  // Remove previous players

        for mediaItem in mediaItems {
            if let assetURL = mediaItem.assetURL {
                let asset = AVAsset(url: assetURL)
                let playerItem = AVPlayerItem(asset: asset)
                let player = AVPlayer(playerItem: playerItem)
                players.append(player)
                player.play()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()

    }
}
