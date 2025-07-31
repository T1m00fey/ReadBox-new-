//
//  VibrationsService.swift
//  ReadBox
//
//  Created by Macbook Pro on 31.07.2025.
//

import SwiftUI

final class VibrationsService {
    
    static let shared = VibrationsService()
    private init() {
        softImpactGenerator.prepare()
        lightImpactGenerator.prepare()
        feedbackGenerator.prepare()
    }
    
    private let softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    func softImpact() {
        softImpactGenerator.impactOccurred()
    }
    
    func lightImpact() {
        lightImpactGenerator.impactOccurred()
    }
    
    func successFeedback() {
        feedbackGenerator.notificationOccurred(.success)
    }
    
    func errorFeedback() {
        feedbackGenerator.notificationOccurred(.error)
    }
    
}
