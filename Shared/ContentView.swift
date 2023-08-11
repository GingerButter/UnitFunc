//
//  ContentView.swift
//  Shared
//
//  Created by Andy Jin on 7/31/23.
//

import SwiftUI
import MediaPlayer

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
    @State private var showMediaPicker = false

    var body: some View {
        VStack {
            Button("Pick Songs") {
                showMediaPicker = true
            }

            List(mediaItems, id: \.persistentID) { item in
                Text(item.title ?? "Unknown title")
            }
        }
        .sheet(isPresented: $showMediaPicker) {
            MediaPicker(mediaItems: $mediaItems)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()

    }
}
