import Foundation

class LocalizationManager {
    static let shared = LocalizationManager()
    
    private init() {}
    
    // MARK: - Localized Strings
    var timer_session_complete: String {
        return NSLocalizedString("timer_session_complete", comment: "Session completion message")
    }
    
    var timer_session_complete_message: String {
        return NSLocalizedString("timer_session_complete_message", comment: "Session completion additional message")
    }
    
    var timer_start: String {
        return NSLocalizedString("timer_start", comment: "Start timer button")
    }
    
    var timer_pause: String {
        return NSLocalizedString("timer_pause", comment: "Pause timer button")
    }
    
    var timer_reset: String {
        return NSLocalizedString("timer_reset", comment: "Reset timer button")
    }
    
    var timer_skip: String {
        return NSLocalizedString("timer_skip", comment: "Skip timer button")
    }
    
    var timer_drag_to_set_time: String {
        return NSLocalizedString("timer_drag_to_set_time", comment: "Drag to set time hint")
    }
    
    var timer_focus_session: String {
        return NSLocalizedString("timer_focus_session", comment: "Focus session label")
    }
    
    var timer_break_session: String {
        return NSLocalizedString("timer_break_session", comment: "Break session label")
    }
    
    var task_manager_title: String {
        return NSLocalizedString("task_manager_title", comment: "Task manager title")
    }
    
    var task_manager_select_category: String {
        return NSLocalizedString("task_manager_select_category", comment: "Select category prompt")
    }
    
    var task_manager_select_task: String {
        return NSLocalizedString("task_manager_select_task", comment: "Select task prompt")
    }
    
    var settings_title: String {
        return NSLocalizedString("settings_title", comment: "Settings title")
    }
    
    var help_title: String {
        return NSLocalizedString("help_title", comment: "Help title")
    }
    
    var statistics_title: String {
        return NSLocalizedString("statistics_title", comment: "Statistics title")
    }
    
    var statistics_completed_count: String {
        return NSLocalizedString("statistics_completed_count", comment: "Completed count label")
    }
    
    var statistics_completed_count_visual: String {
        return NSLocalizedString("statistics_completed_count_visual", comment: "Completed count visual representation")
    }
    
    var statistics_total_focus_time: String {
        return NSLocalizedString("statistics_total_focus_time", comment: "Total focus time label")
    }
    
    var statistics_average_session_length: String {
        return NSLocalizedString("statistics_average_session_length", comment: "Average session length label")
    }
    
    var statistics_longest_streak: String {
        return NSLocalizedString("statistics_longest_streak", comment: "Longest streak label")
    }
    
    // MARK: - Category Names
    var category_work: String {
        return NSLocalizedString("category_work", comment: "Work category")
    }
    
    var category_project: String {
        return NSLocalizedString("category_project", comment: "Project category")
    }
    
    var category_study: String {
        return NSLocalizedString("category_study", comment: "Study category")
    }
    
    var category_personal: String {
        return NSLocalizedString("category_personal", comment: "Personal category")
    }
    
    // MARK: - Help Content
    var help_timer_usage: String {
        return NSLocalizedString("help_timer_usage", comment: "Timer usage help")
    }
    
    var help_swipe_gestures: String {
        return NSLocalizedString("help_swipe_gestures", comment: "Swipe gestures help")
    }
    
    var help_task_management: String {
        return NSLocalizedString("help_task_management", comment: "Task management help")
    }
    
    // MARK: - Settings
    var settings_sound_enabled: String {
        return NSLocalizedString("settings_sound_enabled", comment: "Sound enabled setting")
    }
    
    var settings_haptics_enabled: String {
        return NSLocalizedString("settings_haptics_enabled", comment: "Haptics enabled setting")
    }
    
    var settings_focus_duration: String {
        return NSLocalizedString("settings_focus_duration", comment: "Focus duration setting")
    }
    
    var settings_break_duration: String {
        return NSLocalizedString("settings_break_duration", comment: "Break duration setting")
    }
}
