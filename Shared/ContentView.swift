//
//  ContentView.swift
//  Shared
//
//  Created by Andy Jin on 7/31/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .onAppear {
                guard let url = Bundle.main.url(forResource: "400hz", withExtension: "wav") else {
                    fatalError("Failed to locate file in bundle.")
                }
                let data = readAudioFile(url: url)
                let magnitude = performFFT(data: data)
                print(magnitude.count)
            }
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()

    }
}
