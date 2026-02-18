//
//  Speaker.swift
//  Saufi
//
//  Created by Andreas Pelczer on 18.02.26.
//


import Foundation
import AVFoundation

final class Speaker {
    
    private let synth = AVSpeechSynthesizer()
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = 0.50
        utterance.pitchMultiplier = 0.9
        
        synth.speak(utterance)
    }
}
