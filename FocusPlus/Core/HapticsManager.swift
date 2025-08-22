import Foundation
import UIKit

class HapticsManager {
    static let shared = HapticsManager()
    
    private init() {}
    
    // MARK: - Haptic Feedback
    func lightImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func mediumImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func heavyImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    func softImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.impactOccurred()
    }
    
    func rigidImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    func successNotification() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    func warningNotification() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    func errorNotification() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    func selectionChanged() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}
