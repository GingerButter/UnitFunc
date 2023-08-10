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
    let sampleRate = file.fileFormat.sampleRate
    print(file.fileFormat)
    let lenFile = AVAudioFrameCount(file.length)
    let lenBuf = AVAudioFrameCount(Int(pow(2, floor(log2(Float(lenFile))))))
    print("lenBuf: \(lenBuf)")
    let startFrame = AVAudioFramePosition(lenFile - lenBuf)
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: lenBuf)!
    file.framePosition = startFrame
    try! file.read(into: buffer, frameCount: lenBuf)
    
    print("Sample rate: \(sampleRate)")
    print("FrameLength: \(buffer.frameLength)")
    return Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
}

func showFormat(url: URL) -> Void {
    let file = try! AVAudioFile(forReading: url)
    print(file.processingFormat)
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

func synthesizeSignal(frequencyAmplitudePairs: [(f: Float, a: Float)],
                             count: Int) -> [Float] {
    
    let tau: Float = .pi * 2
    let signal: [Float] = (0 ..< count).map { index in
        frequencyAmplitudePairs.reduce(0) { accumulator, frequenciesAmplitudePair in
            let normalizedIndex = Float(index) / Float(count)
            return accumulator + sin(normalizedIndex * frequenciesAmplitudePair.f * tau) * frequenciesAmplitudePair.a
        }
    }
    
    return signal
}

func FFT(data:[Float]) -> Void {
    let n = vDSP_Length(data.count)
    let freqResolution = 44100 / Double(n)
    print(n)
    let window = vDSP.window(ofType: Float.self, usingSequence: .hanningDenormalized, count: data.count, isHalfWindow: false)
    let signal = vDSP.multiply(data, window)
    let log2n = vDSP_Length(log2(Float(n)))
    print(log2n)
//    let n = vDSP_Length(2048)
//
//
//    let frequencyAmplitudePairs = [(f: Float(2), a: Float(0.8)),
//                                   (f: Float(7), a: Float(1.2)),
//                                   (f: Float(24), a: Float(0.7)),
//                                   (f: Float(50), a: Float(1.0))]
//
//
//    let data = synthesizeSignal(frequencyAmplitudePairs: frequencyAmplitudePairs,
//                                count: Int(n))
//    let log2n = vDSP_Length(log2(Float(n)))
    guard let fftSetUp = vDSP.FFT(log2n: log2n,
                                  radix: .radix2,
                                  ofType: DSPSplitComplex.self) else {
                                    fatalError("Can't create FFT Setup.")
    }
    let halfN = Int(n / 2)
    var forwardInputReal = [Float](repeating: 0, count: halfN)
    var forwardInputImag = [Float](repeating: 0, count: halfN)
    var forwardOutputReal = [Float](repeating: 0, count: halfN)
    var forwardOutputImag = [Float](repeating: 0, count: halfN)
    forwardInputReal.withUnsafeMutableBufferPointer { forwardInputRealPtr in
        forwardInputImag.withUnsafeMutableBufferPointer { forwardInputImagPtr in
            forwardOutputReal.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
                forwardOutputImag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in
                    
                    // Create a `DSPSplitComplex` to contain the signal.
                    var forwardInput = DSPSplitComplex(realp: forwardInputRealPtr.baseAddress!,
                                                       imagp: forwardInputImagPtr.baseAddress!)
                    
                    // Convert the real values in `signal` to complex numbers.
//                    data.withUnsafeBytes {
                    signal.withUnsafeBytes {
                        vDSP.convert(interleavedComplexVector: [DSPComplex]($0.bindMemory(to: DSPComplex.self)),
                                     toSplitComplexVector: &forwardInput)
                    }
                    
                    // Create a `DSPSplitComplex` to receive the FFT result.
                    var forwardOutput = DSPSplitComplex(realp: forwardOutputRealPtr.baseAddress!,
                                                        imagp: forwardOutputImagPtr.baseAddress!)
                    
                    // Perform the forward FFT.
                    fftSetUp.forward(input: forwardInput,
                                     output: &forwardOutput)
                }
            }
        }
    }
    let autospectrum = [Float](unsafeUninitializedCapacity: halfN) {
        autospectrumBuffer, initializedCount in
        
        // The `vDSP_zaspec` function accumulates its output. Clear the
        // uninitialized `autospectrumBuffer` before computing the spectrum.
        vDSP.clear(&autospectrumBuffer)
        
        forwardOutputReal.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
            forwardOutputImag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in
                
                var frequencyDomain = DSPSplitComplex(realp: forwardOutputRealPtr.baseAddress!,
                                                      imagp: forwardOutputImagPtr.baseAddress!)
                
                vDSP_zaspec(&frequencyDomain,
                            autospectrumBuffer.baseAddress!,
                            vDSP_Length(halfN))
            }
        }
        initializedCount = halfN
    }
//    print(autospectrum.count)
//    let value = vDSP.rootMeanSquare(autospectrum)
//    autospectrum = vDSP.divide(autospectrum, value)
    let componentFrequencyAmplitudePairs = autospectrum.enumerated().filter {
//        print("\($0)")
        return $0.element > 10000
        
    }.map {
        return (Double($0.offset)*freqResolution, sqrt($0.element) / Float(n))
    }
    print(componentFrequencyAmplitudePairs.count)


    // Prints:
    //     ["frequency: 2 | amplitude: 0.80", "frequency: 7 | amplitude: 1.20",
    //      "frequency: 24 | amplitude: 0.70", "frequency: 50 | amplitude: 1.00"]"


    print(componentFrequencyAmplitudePairs.map {
        "frequency: \($0.0) | amplitude: \(String(format: "%.4f", $0.1))"
    })
}
