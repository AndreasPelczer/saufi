//
//  PartyEngine.swift
//  Saufi
//
//  Created by Andreas Pelczer on 18.02.26.
//

import Foundation
import Combine

final class PartyEngine: ObservableObject {

    @Published var partyLevel: Int = 0

    func update(with energy: Float) {
        if energy > 0.05 { partyLevel += 1 }
        if energy < 0.01 { partyLevel -= 1 }

        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 23 { partyLevel += 1 }

        partyLevel = max(0, min(partyLevel, 5))
    }
}

