import SwiftUI
import IOKit.ps
import Combine

// MARK: - 言語設定
enum AppLanguage: String, CaseIterable {
    case english = "en"
    case japanese = "ja"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .japanese: return "日本語"
        }
    }
}

// MARK: - ローカライズ文字列
struct L10n {
    let language: AppLanguage
    
    var onBattery: String { language == .japanese ? "バッテリー駆動" : "On Battery" }
    var charging: String { language == .japanese ? "充電中" : "Charging" }
    var notConnected: String { language == .japanese ? "未接続" : "Not Connected" }
    var battery: String { language == .japanese ? "バッテリー" : "Battery" }
    var power: String { language == .japanese ? "電力" : "Power" }
    var temperature: String { language == .japanese ? "温度" : "Temperature" }
    var health: String { language == .japanese ? "ヘルス" : "Health" }
    var discharging: String { language == .japanese ? "放電中" : "Discharging" }
    var toBattery: String { language == .japanese ? "充電中" : "To Battery" }
    var normal: String { language == .japanese ? "正常" : "Normal" }
    var warm: String { language == .japanese ? "やや高温" : "Warm" }
    var hot: String { language == .japanese ? "高温" : "Hot" }
    var cycles: String { language == .japanese ? "サイクル" : "cycles" }
    var capacity: String { language == .japanese ? "容量" : "Capacity" }
    var voltage: String { language == .japanese ? "電圧" : "Voltage" }
    var current: String { language == .japanese ? "電流" : "Current" }
    var adapter: String { language == .japanese ? "アダプター" : "Adapter" }
    var status: String { language == .japanese ? "状態" : "Status" }
    var recommendedRange: String { language == .japanese ? "推奨範囲" : "Recommended" }
    var cycleCount: String { language == .japanese ? "サイクル数" : "Cycle Count" }
    var settings: String { language == .japanese ? "設定" : "Settings" }
    var language_: String { language == .japanese ? "言語" : "Language" }
    var credits: String { language == .japanese ? "クレジット" : "Credits" }
    var quitApp: String { language == .japanese ? "終了" : "Quit App" }
    var calculating: String { language == .japanese ? "計算中..." : "Calculating..." }
    var serviceRecommended: String { language == .japanese ? "要点検" : "Service Recommended" }
    var timeToFull: String { language == .japanese ? "満充電まで" : "Full in" }
    var menuBarDisplay: String { language == .japanese ? "メニューバー表示" : "Menu Bar Display" }
    var designCapacity: String { language == .japanese ? "設計容量" : "Design Capacity" }
    var currentCapacity: String { language == .japanese ? "現在の容量" : "Current Capacity" }
}

// MARK: - テーマカラー
struct ThemeColors {
    let colorScheme: ColorScheme
    
    var tileBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8)
    }
    
    var tileBackgroundAlt: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.9)
    }
    
    var headerBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.6)
    }
    
    var textPrimary: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    var textSecondary: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color.secondary
    }
    
    func gradientColors(isCharging: Bool) -> [Color] {
        if colorScheme == .dark {
            return [
                isCharging ? Color.green.opacity(0.15) : Color.blue.opacity(0.1),
                Color.black.opacity(0.3)
            ]
        } else {
            return [
                isCharging ? Color.green.opacity(0.1) : Color.blue.opacity(0.1),
                Color.cyan.opacity(0.05)
            ]
        }
    }
}

// MARK: - メインメニュー
struct MenuContentView: View {
    @ObservedObject var batteryManager: BatteryManager
    @State private var showSettings = false
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @Environment(\.colorScheme) private var colorScheme
    
    var language: AppLanguage {
        AppLanguage(rawValue: appLanguage) ?? .english
    }
    
    var l10n: L10n {
        L10n(language: language)
    }
    
    var theme: ThemeColors {
        ThemeColors(colorScheme: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // ヘッダー
            HeaderView(batteryManager: batteryManager, l10n: l10n, showSettings: $showSettings, theme: theme)
            
            // タイルグリッド
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                // Battery タイル（グラフ付き）
                FlipTileWithGraph(
                    icon: "battery.100",
                    iconColor: .green,
                    title: l10n.battery,
                    mainValue: "\(batteryManager.batteryLevel)%",
                    subValue: batteryManager.getTimeRemainingShort(l10n: l10n),
                    backDetails: [
                        (l10n.capacity, String(format: "%.1f Wh", batteryManager.whCapacity)),
                        (l10n.voltage, batteryManager.voltage),
                        (l10n.current, batteryManager.amperage)
                    ],
                    theme: theme,
                    historyData: batteryManager.batteryHistory,
                    graphColor: .green,
                    minValue: 0,
                    maxValue: 100
                )
                
                // Power タイル（グラフ付き）
                FlipTileWithGraph(
                    icon: "bolt.fill",
                    iconColor: batteryManager.isCharging ? .green : .yellow,
                    title: batteryManager.isCharging ? l10n.charging : l10n.power,
                    mainValue: batteryManager.wattage,
                    subValue: batteryManager.isCharging ? l10n.toBattery : l10n.discharging,
                    backDetails: [
                        (l10n.adapter, batteryManager.adapterWattage),
                        (l10n.voltage, batteryManager.voltage),
                        (l10n.current, batteryManager.amperage)
                    ],
                    theme: theme,
                    historyData: batteryManager.powerHistory,
                    graphColor: batteryManager.isCharging ? .green : .yellow,
                    minValue: 0,
                    maxValue: max(batteryManager.powerHistory.max() ?? 50, 50)
                )
                
                // Temperature タイル（グラフ付き）
                FlipTileWithGraph(
                    icon: "thermometer.medium",
                    iconColor: .orange,
                    title: l10n.temperature,
                    mainValue: batteryManager.temperature,
                    subValue: batteryManager.getTempStatus(l10n: l10n),
                    backDetails: [
                        (l10n.status, batteryManager.getTempStatus(l10n: l10n)),
                        (l10n.recommendedRange, "10°C - 35°C"),
                        ("", "")
                    ],
                    theme: theme,
                    historyData: batteryManager.temperatureHistory,
                    graphColor: .orange,
                    minValue: 20,
                    maxValue: 50
                )
                
                // Health タイル（グラフなし）
                FlipTile(
                    icon: "heart.fill",
                    iconColor: .pink,
                    title: l10n.health,
                    mainValue: batteryManager.batteryHealth,
                    subValue: "\(batteryManager.cycleCountValue) \(l10n.cycles)",
                    backDetails: [
                        (l10n.designCapacity, batteryManager.designCapacityText),
                        (l10n.currentCapacity, batteryManager.currentCapacityText),
                        (l10n.cycleCount, batteryManager.cycleCount)
                    ],
                    theme: theme
                )
            }
        }
        .padding(20)
        .frame(width: 360)
        .background(
            LinearGradient(
                gradient: Gradient(colors: theme.gradientColors(isCharging: batteryManager.isCharging)),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - ミニグラフ
struct MiniGraph: View {
    let data: [Double]
    let color: Color
    let minValue: Double
    let maxValue: Double
    
    var body: some View {
        GeometryReader { geometry in
            if data.count > 1 {
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let range = maxValue - minValue
                    
                    let points = data.enumerated().map { index, value -> CGPoint in
                        let x = width * CGFloat(index) / CGFloat(data.count - 1)
                        let normalizedValue = (value - minValue) / range
                        let y = height * (1 - CGFloat(normalizedValue))
                        return CGPoint(x: x, y: y)
                    }
                    
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(color.opacity(0.3), lineWidth: 1.5)
                
                // 塗りつぶし
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let range = maxValue - minValue
                    
                    let points = data.enumerated().map { index, value -> CGPoint in
                        let x = width * CGFloat(index) / CGFloat(data.count - 1)
                        let normalizedValue = (value - minValue) / range
                        let y = height * (1 - CGFloat(normalizedValue))
                        return CGPoint(x: x, y: y)
                    }
                    
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.2), color.opacity(0.05)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}

// MARK: - グラフ付きフリップタイル
struct FlipTileWithGraph: View {
    let icon: String
    let iconColor: Color
    let title: String
    let mainValue: String
    let subValue: String
    let backDetails: [(String, String)]
    let theme: ThemeColors
    let historyData: [Double]
    let graphColor: Color
    let minValue: Double
    let maxValue: Double
    
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            TileFrontWithGraph(
                icon: icon,
                iconColor: iconColor,
                title: title,
                mainValue: mainValue,
                subValue: subValue,
                theme: theme,
                historyData: historyData,
                graphColor: graphColor,
                minValue: minValue,
                maxValue: maxValue
            )
            .opacity(isFlipped ? 0 : 1)
            .scaleEffect(isFlipped ? 0.95 : 1)
            
            TileBack(
                icon: icon,
                iconColor: iconColor,
                title: title,
                details: backDetails,
                theme: theme
            )
            .opacity(isFlipped ? 1 : 0)
            .scaleEffect(isFlipped ? 1 : 0.95)
        }
        .frame(height: 100)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isFlipped.toggle()
            }
        }
    }
}

// MARK: - グラフ付きタイル表面
struct TileFrontWithGraph: View {
    let icon: String
    let iconColor: Color
    let title: String
    let mainValue: String
    let subValue: String
    let theme: ThemeColors
    let historyData: [Double]
    let graphColor: Color
    let minValue: Double
    let maxValue: Double
    
    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.tileBackground)
            
            // グラフ（背景に薄く表示）
            MiniGraph(
                data: historyData,
                color: graphColor,
                minValue: minValue,
                maxValue: maxValue
            )
            .padding(.top, 30)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            
            // コンテンツ
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 12))
                    Text(title)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textSecondary.opacity(0.5))
                }
                
                Spacer()
                
                Text(mainValue)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text(subValue)
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
            }
            .padding(12)
        }
        .frame(height: 100)
        .cornerRadius(12)
    }
}

// MARK: - フリップタイル（グラフなし）
struct FlipTile: View {
    let icon: String
    let iconColor: Color
    let title: String
    let mainValue: String
    let subValue: String
    let backDetails: [(String, String)]
    let theme: ThemeColors
    
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            TileFront(
                icon: icon,
                iconColor: iconColor,
                title: title,
                mainValue: mainValue,
                subValue: subValue,
                theme: theme
            )
            .opacity(isFlipped ? 0 : 1)
            .scaleEffect(isFlipped ? 0.95 : 1)
            
            TileBack(
                icon: icon,
                iconColor: iconColor,
                title: title,
                details: backDetails,
                theme: theme
            )
            .opacity(isFlipped ? 1 : 0)
            .scaleEffect(isFlipped ? 1 : 0.95)
        }
        .frame(height: 100)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isFlipped.toggle()
            }
        }
    }
}

// MARK: - タイル表面（グラフなし）
struct TileFront: View {
    let icon: String
    let iconColor: Color
    let title: String
    let mainValue: String
    let subValue: String
    let theme: ThemeColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 12))
                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textSecondary.opacity(0.5))
            }
            
            Spacer()
            
            Text(mainValue)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(theme.textPrimary)
            
            Text(subValue)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .background(theme.tileBackground)
        .cornerRadius(12)
    }
}

// MARK: - タイル裏面
struct TileBack: View {
    let icon: String
    let iconColor: Color
    let title: String
    let details: [(String, String)]
    let theme: ThemeColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 12))
                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textSecondary.opacity(0.5))
            }
            
            Spacer()
            
            ForEach(details.indices, id: \.self) { index in
                if !details[index].0.isEmpty {
                    HStack {
                        Text(details[index].0)
                            .font(.system(size: 10))
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text(details[index].1)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .background(theme.tileBackgroundAlt)
        .cornerRadius(12)
    }
}

// MARK: - ヘッダービュー
struct HeaderView: View {
    @ObservedObject var batteryManager: BatteryManager
    let l10n: L10n
    @Binding var showSettings: Bool
    let theme: ThemeColors
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(batteryManager.isCharging ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: batteryManager.isCharging ? "bolt.fill" : "battery.100")
                    .font(.system(size: 24))
                    .foregroundColor(batteryManager.isCharging ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(batteryManager.isCharging ? l10n.charging : l10n.onBattery)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                Text(batteryManager.isCharging ? batteryManager.adapterWattage : batteryManager.wattage)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                Text(batteryManager.isCharging ? batteryManager.adapterInfo : l10n.notConnected)
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showSettings) {
                    SettingsView(appLanguage: $appLanguage)
                }
                
                Text(batteryManager.voltage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                Text(batteryManager.amperage)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        .background(theme.headerBackground)
        .cornerRadius(16)
    }
}

// MARK: - 設定ビュー
struct SettingsView: View {
    @Binding var appLanguage: String
    @AppStorage("menuBarDisplay") private var menuBarDisplay: String = MenuBarDisplayOption.iconOnly.rawValue
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var language: AppLanguage {
        AppLanguage(rawValue: appLanguage) ?? .english
    }
    
    var l10n: L10n {
        L10n(language: language)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(l10n.settings)
                .font(.headline)
            
            Divider()
            
            // メニューバー表示設定
            VStack(alignment: .leading, spacing: 8) {
                Text(l10n.menuBarDisplay)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(spacing: 4) {
                    ForEach(MenuBarDisplayOption.allCases, id: \.rawValue) { option in
                        MenuBarOptionRow(
                            option: option,
                            isSelected: menuBarDisplay == option.rawValue,
                            language: language
                        ) {
                            menuBarDisplay = option.rawValue
                        }
                    }
                }
            }
            
            Divider()
            
            // 言語設定
            HStack {
                Text(l10n.language_)
                    .font(.subheadline)
                Spacer()
                Picker("", selection: $appLanguage) {
                    ForEach(AppLanguage.allCases, id: \.rawValue) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }
            
            Divider()
            
            // クレジット
            VStack(alignment: .leading, spacing: 8) {
                Text(l10n.credits)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("PowerTile")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("Version 1.0.1")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("© 2025 ikepe")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            Divider()
            
            Button(l10n.quitApp) {
                NSApplication.shared.terminate(nil)
            }
            .foregroundColor(.red)
        }
        .padding()
        .frame(width: 260)
    }
}

// MARK: - メニューバー表示オプション行
struct MenuBarOptionRow: View {
    let option: MenuBarDisplayOption
    let isSelected: Bool
    let language: AppLanguage
    let action: () -> Void
    
    var displayName: String {
        language == .japanese ? option.displayName : option.displayNameEn
    }
    
    var previewText: String {
        switch option {
        case .iconOnly: return "🔋"
        case .iconAndPercent: return "🔋 85%"
        case .percentOnly: return "85%"
        case .iconAndTime: return "🔋 2:30"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.system(size: 14))
                
                Text(displayName)
                    .font(.caption)
                
                Spacer()
                
                Text(previewText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - バッテリー情報を管理するクラス
class BatteryManager: ObservableObject {
    @Published var batteryLevel: Int = 0
    @Published var isCharging: Bool = false
    @Published var isPluggedIn: Bool = false
    @Published var timeRemaining: String = "--"
    @Published var powerSource: String = "--"
    @Published var batteryHealth: String = "--"
    @Published var cycleCount: String = "--"
    @Published var temperature: String = "--"
    @Published var voltage: String = "--"
    @Published var amperage: String = "--"
    @Published var wattage: String = "--"
    
    @Published var cycleCountValue: String = "--"
    @Published var rawVoltage: Double = 0
    @Published var rawAmperage: Double = 0
    @Published var rawWattage: Double = 0
    @Published var rawTemperature: Double = 0
    @Published var whCapacity: Double = 0
    @Published var adapterWattage: String = "--"
    @Published var adapterInfo: String = "Not Connected"
    @Published var healthValue: Int = 100
    @Published var timeRemainingMinutes: Int = 0
    
    // 設計容量と現在の容量
    @Published var designCapacity: Int = 0
    @Published var currentMaxCapacity: Int = 0
    
    // 履歴データ（グラフ用）
    @Published var batteryHistory: [Double] = []
    @Published var powerHistory: [Double] = []
    @Published var temperatureHistory: [Double] = []
    
    private let maxHistoryCount = 30  // 最大30ポイント
    
    var designCapacityText: String {
        if designCapacity > 0 {
            return "\(designCapacity) mAh"
        }
        return "--"
    }
    
    var currentCapacityText: String {
        if currentMaxCapacity > 0 {
            return "\(currentMaxCapacity) mAh"
        }
        return "--"
    }
    
    private var timer: Timer?
    private var powerSourceCallback: CFRunLoopSource?
    
    init() {
        updateAllInfo()
        setupPowerSourceNotification()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateAllInfo()
            self?.recordHistory()
        }
        // 初期履歴を作成
        recordHistory()
    }
    
    deinit {
        timer?.invalidate()
        if let source = powerSourceCallback {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
    }
    
    // 履歴を記録
    private func recordHistory() {
        DispatchQueue.main.async {
            // バッテリー残量
            self.batteryHistory.append(Double(self.batteryLevel))
            if self.batteryHistory.count > self.maxHistoryCount {
                self.batteryHistory.removeFirst()
            }
            
            // 電力
            self.powerHistory.append(self.rawWattage)
            if self.powerHistory.count > self.maxHistoryCount {
                self.powerHistory.removeFirst()
            }
            
            // 温度
            self.temperatureHistory.append(self.rawTemperature)
            if self.temperatureHistory.count > self.maxHistoryCount {
                self.temperatureHistory.removeFirst()
            }
        }
    }
    
    // 電源状態変化の通知を設定
    private func setupPowerSourceNotification() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        if let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            let manager = Unmanaged<BatteryManager>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async {
                manager.updateAllInfo()
            }
        }, context)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
            powerSourceCallback = source
        }
    }
    
    var batteryIcon: String {
        if isCharging {
            return "battery.100.bolt"
        }
        switch batteryLevel {
        case 75...100: return "battery.100"
        case 50..<75: return "battery.75"
        case 25..<50: return "battery.50"
        case 10..<25: return "battery.25"
        default: return "battery.0"
        }
    }
    
    var menuBarTimeText: String {
        if timeRemainingMinutes <= 0 {
            return "--:--"
        }
        let hours = timeRemainingMinutes / 60
        let mins = timeRemainingMinutes % 60
        return String(format: "%d:%02d", hours, mins)
    }
    
    func getTimeRemainingShort(l10n: L10n) -> String {
        if timeRemainingMinutes <= 0 {
            return l10n.calculating
        }
        let hours = timeRemainingMinutes / 60
        let mins = timeRemainingMinutes % 60
        if isCharging {
            return "\(l10n.timeToFull) \(hours)h \(String(format: "%02d", mins))m"
        } else {
            return "\(hours)h \(String(format: "%02d", mins))m"
        }
    }
    
    func getTempStatus(l10n: L10n) -> String {
        if rawTemperature < 35 {
            return l10n.normal
        } else if rawTemperature < 40 {
            return l10n.warm
        } else {
            return l10n.hot
        }
    }
    
    func getHealthStatus(l10n: L10n) -> String {
        if healthValue >= 80 {
            return l10n.normal
        } else {
            return l10n.serviceRecommended
        }
    }
    
    func updateAllInfo() {
        updateBasicInfo()
        updateDetailedInfo()
        updateAdapterInfo()
    }
    
    func updateBasicInfo() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any]
        else {
            return
        }
        
        DispatchQueue.main.async {
            if let capacity = info[kIOPSCurrentCapacityKey] as? Int {
                self.batteryLevel = capacity
            }
            if let charging = info[kIOPSIsChargingKey] as? Bool {
                self.isCharging = charging
            }
            if let source = info[kIOPSPowerSourceStateKey] as? String {
                self.isPluggedIn = (source == kIOPSACPowerValue)
                self.powerSource = source == kIOPSACPowerValue ? "AC電源" : "バッテリー"
            }
            if let minutes = info[kIOPSTimeToEmptyKey] as? Int, minutes > 0 {
                self.timeRemainingMinutes = minutes
            } else if let minutes = info[kIOPSTimeToFullChargeKey] as? Int, minutes > 0 {
                self.timeRemainingMinutes = minutes
            }
        }
    }
    
    func updateDetailedInfo() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        
        if service == 0 { return }
        defer { IOObjectRelease(service) }
        
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let properties = props?.takeRetainedValue() as? [String: Any] else {
            return
        }
        
        DispatchQueue.main.async {
            if let connected = properties["ExternalConnected"] as? Bool {
                self.isPluggedIn = connected
            }
            
            if let charging = properties["IsCharging"] as? Bool {
                self.isCharging = charging
            }
            
            if let minutes = properties["TimeRemaining"] as? Int, minutes > 0, minutes < 6000 {
                self.timeRemainingMinutes = minutes
            }
            
            if let value = properties["CycleCount"] as? Int {
                self.cycleCount = "\(value)"
                self.cycleCountValue = "\(value)"
            }
            
            // 設計容量
            if let design = properties["DesignCapacity"] as? Int {
                self.designCapacity = design
            }
            
            // 現在の最大容量
            if let max = properties["AppleRawMaxCapacity"] as? Int {
                self.currentMaxCapacity = max
            } else if let max = properties["MaxCapacity"] as? Int {
                self.currentMaxCapacity = max
            }
            
            // バッテリーヘルス
            if self.designCapacity > 0 && self.currentMaxCapacity > 0 {
                let health = (self.currentMaxCapacity * 100) / self.designCapacity
                self.batteryHealth = "\(health)%"
                self.healthValue = health
            }
            
            if let temp = properties["Temperature"] as? Int {
                let celsius = Double(temp) / 100.0
                self.temperature = String(format: "%.1f°C", celsius)
                self.rawTemperature = celsius
            }
            
            if let volt = properties["Voltage"] as? Int {
                let v = Double(volt) / 1000.0
                self.voltage = String(format: "%.1fV", v)
                self.rawVoltage = v
            }
            
            if let amp = properties["Amperage"] as? Int {
                let a = Double(abs(amp)) / 1000.0
                self.amperage = String(format: "%.2fA", a)
                self.rawAmperage = a
                
                let watts = self.rawVoltage * a
                self.wattage = String(format: "%.1fW", watts)
                self.rawWattage = watts
            }
            
            if let capacity = properties["AppleRawMaxCapacity"] as? Int {
                let wh = Double(capacity) * self.rawVoltage / 1000.0
                self.whCapacity = wh
            }
        }
    }
    
    func updateAdapterInfo() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        
        if service == 0 { return }
        defer { IOObjectRelease(service) }
        
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let properties = props?.takeRetainedValue() as? [String: Any] else {
            return
        }
        
        DispatchQueue.main.async {
            if let adapterDetails = properties["AdapterDetails"] as? [String: Any] {
                var info: [String] = []
                
                if let watts = adapterDetails["Watts"] as? Int {
                    self.adapterWattage = "\(watts)W"
                    info.append("\(watts)W")
                }
                
                if let name = adapterDetails["Name"] as? String {
                    info.append(name)
                } else if let description = adapterDetails["Description"] as? String {
                    info.append(description)
                }
                
                if !info.isEmpty {
                    self.adapterInfo = info.joined(separator: " ")
                } else if self.isPluggedIn {
                    self.adapterInfo = "Power Adapter"
                }
            } else if self.isPluggedIn {
                self.adapterInfo = "Power Adapter"
                self.adapterWattage = self.wattage
            } else {
                self.adapterInfo = "Not Connected"
                self.adapterWattage = "--"
            }
        }
    }
}

#Preview {
    MenuContentView(batteryManager: BatteryManager())
}
