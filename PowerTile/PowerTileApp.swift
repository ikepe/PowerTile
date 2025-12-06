import SwiftUI

// MARK: - メニューバー表示オプション
enum MenuBarDisplayOption: String, CaseIterable {
    case iconOnly = "iconOnly"
    case iconAndPercent = "iconAndPercent"
    case percentOnly = "percentOnly"
    case iconAndTime = "iconAndTime"
    
    var displayName: String {
        switch self {
        case .iconOnly: return "アイコンのみ"
        case .iconAndPercent: return "アイコン + %"
        case .percentOnly: return "%のみ"
        case .iconAndTime: return "アイコン + 残り時間"
        }
    }
    
    var displayNameEn: String {
        switch self {
        case .iconOnly: return "Icon only"
        case .iconAndPercent: return "Icon + %"
        case .percentOnly: return "% only"
        case .iconAndTime: return "Icon + Time"
        }
    }
}

@main
struct BatteryBarApp: App {
    @StateObject private var batteryManager = BatteryManager()
    @AppStorage("menuBarDisplay") private var menuBarDisplay: String = MenuBarDisplayOption.iconOnly.rawValue
    
    var displayOption: MenuBarDisplayOption {
        MenuBarDisplayOption(rawValue: menuBarDisplay) ?? .iconOnly
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuContentView(batteryManager: batteryManager)
        } label: {
            HStack(spacing: 4) {
                switch displayOption {
                case .iconOnly:
                    Image(systemName: batteryManager.batteryIcon)
                    
                case .iconAndPercent:
                    Image(systemName: batteryManager.batteryIcon)
                    Text("\(batteryManager.batteryLevel)%")
                    
                case .percentOnly:
                    Text("\(batteryManager.batteryLevel)%")
                    
                case .iconAndTime:
                    Image(systemName: batteryManager.batteryIcon)
                    Text(batteryManager.menuBarTimeText)
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
