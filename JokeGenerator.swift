//
//  JokeGenerator.swift
//  Saufi
//
//  Created by Andreas Pelczer on 18.02.26.
//


import Foundation

final class JokeGenerator {
    
    func joke(for level: Int) -> String {
        
        switch level {
        case 0:
            return "Hier ist es so ruhig… selbst mein Bier schläft schon."
            
        case 1:
            return "Der Barkeeper arbeitet heute ehrenamtlich… er bekommt nur Trinkgeld."
            
        case 2:
            return "Wenn du dein Bier suchst — es steht direkt vor deiner Zukunft."
            
        case 3:
            return "Ab diesem Pegel werden Entscheidungen getroffen, die morgen jemand anders erklären muss."
            
        case 4:
            return "Die Musik ist nicht zu laut… ihr seid zu nüchtern."
            
        default:
            return "Wenn du jetzt noch gerade läufst, bist du nur auf dem Weg zur nächsten Runde."
        }
    }
}
