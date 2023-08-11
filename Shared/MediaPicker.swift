//
//  MediaPicker.swift
//  UnitFunc
//
//  Created by Andy Jin on 8/10/23.
//

import SwiftUI
import Foundation
import AVFoundation
import MediaPlayer

struct MediaPicker: UIViewControllerRepresentable {
    @Binding var mediaItems: [MPMediaItem]
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .anyAudio)
        picker.delegate = context.coordinator
        picker.allowsPickingMultipleItems = true
        return picker
    }

    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        var parent: MediaPicker

        init(_ parent: MediaPicker) {
            self.parent = parent
        }

        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            parent.mediaItems = mediaItemCollection.items
            parent.presentationMode.wrappedValue.dismiss()
        }

        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

