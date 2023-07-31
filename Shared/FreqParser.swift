//
//  FreqParser.swift
//  UnitFunc
//
//  Created by Andy Jin on 7/31/23.
//

import Foundation
import AVFoundation
import Accelerate

func readAudioFile(url: URL) -> [Float] {
    let file = try! AVAudioFile(forReading: url)
    let format = file.processingFormat
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(file.length))!
    try! file.read(into: buffer)
    let sampleRate = file.fileFormat.sampleRate
    print("Sample rate: \(sampleRate)")
    print("FrameLength: \(buffer.frameLength)")
    return Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
}

func performFFT(data: [Float]) -> [Float] {
    // 1. Setup
    print("Len Data: \(data.count)")
    let log2n = vDSP_Length(log2f(Float(data.count)))
    let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))

    // 2. Transform to complex numbers
    var realp = [Float](repeating: 0, count: data.count/2)
    var imagp = [Float](repeating: 0, count: data.count/2)
    var complexSplit = DSPSplitComplex(realp: &realp, imagp: &imagp)
    data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Void in
        pointer.bindMemory(to: DSPComplex.self).baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: 1) { pointer in
            vDSP_ctoz(pointer, 2, &complexSplit, 1, vDSP_Length(data.count/2))
        }
    }
    
    // 3. Perform FFT
    vDSP_fft_zrip(fftSetup!, &complexSplit, 1, log2n, FFTDirection(kFFTDirection_Forward))

    // 4. Calculate magnitudes
    var magnitudes = [Float](repeating: 0.0, count: data.count/2)
    vDSP_zvmags(&complexSplit, 1, &magnitudes, 1, vDSP_Length(data.count/2))
    
    // 5. Clean up
    vDSP_destroy_fftsetup(fftSetup)
    
    return magnitudes
}
