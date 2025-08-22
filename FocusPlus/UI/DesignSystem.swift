import SwiftUI

struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        static let background = Color(red: 0.05, green: 0.05, blue: 0.1)
        static let surface = Color(red: 0.1, green: 0.1, blue: 0.15)
        static let primary = Color.white
        static let secondary = Color.white.opacity(0.7)
        static let accent = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let neonBlue = Color(red: 0.0, green: 0.85, blue: 1.0) // より鮮やかで明るいネオンブルー
        static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)
        static let error = Color(red: 1.0, green: 0.3, blue: 0.3)
        static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Layout
    struct Layout {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 16
        static let padding: CGFloat = 20
        static let smallPadding: CGFloat = 12
        static let largePadding: CGFloat = 32
        static let maxWidth: CGFloat = 400
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
    }
    
    // MARK: - Tone of Voice
    struct ToneOfVoice {
        static let principles = [
            "シンプルで分かりやすい",
            "親しみやすく親近感のある",
            "励ましとサポートを重視",
            "専門的すぎない親しみやすい表現",
            "一貫性のあるメッセージング"
        ]
        
        static let recommendedPhrases = [
            "セッション完了",
            "お疲れ様でした",
            "集中時間を設定",
            "休憩時間です",
            "次のセッションを開始"
        ]
        
        static let avoidPhrases = [
            "セッション完了！",
            "お疲れ様でした！",
            "素晴らしい！",
            "完璧です！",
            "頑張りました！"
        ]
        
        static let buttonGuidelines = [
            "短く、明確な指示",
            "動詞から始める",
            "過度な装飾を避ける"
        ]
        
        static let messageGuidelines = [
            "簡潔で分かりやすい",
            "励ましの要素を含む",
            "過度な感情表現を避ける"
        ]
        
        static let statisticsGuidelines = [
            "数値は分かりやすく表示",
            "視覚的な要素を重視",
            "過度な装飾を避ける"
        ]
    }
}

// MARK: - View Extensions
extension View {
    func primaryText() -> some View {
        self.foregroundColor(DesignSystem.Colors.primary)
    }
    
    func secondaryText() -> some View {
        self.foregroundColor(DesignSystem.Colors.secondary)
    }
    
    func accentText() -> some View {
        self.foregroundColor(DesignSystem.Colors.accent)
    }
    
    func neonBlueText() -> some View {
        self.foregroundColor(DesignSystem.Colors.neonBlue)
    }
    
    func largeTitleStyle() -> some View {
        self.font(DesignSystem.Typography.largeTitle)
    }
    
    func titleStyle() -> some View {
        self.font(DesignSystem.Typography.title)
    }
    
    func title2Style() -> some View {
        self.font(DesignSystem.Typography.title2)
    }
    
    func title3Style() -> some View {
        self.font(DesignSystem.Typography.title3)
    }
    
    func headlineStyle() -> some View {
        self.font(DesignSystem.Typography.headline)
    }
    
    func bodyStyle() -> some View {
        self.font(DesignSystem.Typography.body)
    }
    
    func calloutStyle() -> some View {
        self.font(DesignSystem.Typography.callout)
    }
    
    func subheadlineStyle() -> some View {
        self.font(DesignSystem.Typography.subheadline)
    }
    
    func footnoteStyle() -> some View {
        self.font(DesignSystem.Typography.footnote)
    }
    
    func captionStyle() -> some View {
        self.font(DesignSystem.Typography.caption)
    }
    
    func caption2Style() -> some View {
        self.font(DesignSystem.Typography.caption2)
    }
    
    func standardPadding() -> some View {
        self.padding(DesignSystem.Layout.padding)
    }
    
    func smallPadding() -> some View {
        self.padding(DesignSystem.Layout.smallPadding)
    }
    
    func largePadding() -> some View {
        self.padding(DesignSystem.Layout.largePadding)
    }
    
    func standardCornerRadius() -> some View {
        self.cornerRadius(DesignSystem.Layout.cornerRadius)
    }
    
    func smallCornerRadius() -> some View {
        self.cornerRadius(DesignSystem.Layout.smallCornerRadius)
    }
    
    func largeCornerRadius() -> some View {
        self.cornerRadius(DesignSystem.Layout.largeCornerRadius)
    }
}
