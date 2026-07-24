import SwiftUI
import Combine
import AppKit

// MARK: - Color Palette for Pixel Art

struct GardenPalette {
    static let soil = Color(red: 0.36, green: 0.25, blue: 0.20)
    static let soilSurface = Color(red: 0.54, green: 0.35, blue: 0.17)
    static let seed = Color(red: 0.94, green: 0.85, blue: 0.71)
    static let stem = Color(red: 0.0, green: 0.80, blue: 0.27)
    static let leaf = Color(red: 0.22, green: 1.0, blue: 0.08)
    static let bud = Color(red: 1.0, green: 0.80, blue: 0.0)
    static let petalOuter = Color(red: 1.0, green: 0.0, blue: 0.50)
    static let petalCenter = Color(red: 1.0, green: 0.84, blue: 0.0)
}

// MARK: - Persistent Game State (Swift Mirror of JS Engine)

@MainActor
public final class GardenState: ObservableObject {
    public static let shared = GardenState()
    
    @Published public var plantStage: Int = 0       // 0 to 4
    @Published public var waterLevel: Double = 80.0   // 0.0 to 100.0
    @Published public var growthProgress: Double = 0.0 // 0.0 to 100.0
    @Published public var fertilizerTime: Double = 0.0 // seconds remaining
    @Published public var totalActions: Int = 0
    @Published public var lastUpdateTime: Date = Date()
    @Published public var isCodingFocused: Bool = false // Tracks if IDE boost is active
    @Published public var logs: [String] = ["Garden initialized! 🌱"]
    
    @Published public var isWateringActive: Bool = false
    @Published public var isFertilizingActive: Bool = false
    @Published public var animationFrame: Int = 0
    
    private let waterDecayRate: Double = 0.02 // units per second
    private let baseGrowthRate: Double = 0.05 // percent growth per second
    private let fertilizerMultiplier: Double = 2.5
    private let waterThreshold: Double = 20.0
    
    private let stageNames = ["Seed 🌰", "Sprout 🌱", "Stem & Leaves 🌿", "Budding 🌸", "Blooming Flower 🌺"]
    
    private init() {
        load()
        tick() // Initial update
    }
    
    public func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeStr = formatter.string(from: Date())
        logs.append("[\(timeStr)] \(message)")
        if logs.count > 3 {
            logs.removeFirst()
        }
    }
    
    public func tick() {
        let now = Date()
        let elapsed = max(0.0, now.timeIntervalSince(lastUpdateTime))
        lastUpdateTime = now
        
        if elapsed == 0 { return }
        
        // 1. Water level decay
        waterLevel = max(0.0, waterLevel - (waterDecayRate * elapsed))
        
        // 2. Fertilizer timer
        var activeGrowthMultiplier = 1.0
        if fertilizerTime > 0 {
            fertilizerTime = max(0.0, fertilizerTime - elapsed)
            activeGrowthMultiplier = fertilizerMultiplier
        }
        
        // 3. Coding app active check (3x growth boost)
        var isCodingActive = false
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let bundleID = frontApp.bundleIdentifier {
            let ides = ["xcode", "vscode", "cursor", "android.studio", "sublime", "iterm", "terminal", "jetbrains", "intellij", "webstorm", "pycharm", "clion"]
            isCodingActive = ides.contains { bundleID.lowercased().contains($0) }
            if isCodingActive {
                activeGrowthMultiplier *= 3.0
            }
        }
        
        if isCodingActive && !isCodingFocused {
            addLog("IDE focus: 3.0x growth active ⚡️")
        } else if !isCodingActive && isCodingFocused {
            addLog("IDE focus lost: normal growth")
        }
        
        self.isCodingFocused = isCodingActive
        
        // 4. Growth calculation
        if waterLevel > waterThreshold && plantStage < 4 {
            growthProgress += baseGrowthRate * activeGrowthMultiplier * elapsed
            if growthProgress >= 100.0 {
                plantStage = min(4, plantStage + 1)
                growthProgress = 0.0
                addLog("Grew to \(getStageName())! 🎉")
            }
        }
        
        save()
    }
    
    public func getStageName() -> String {
        guard plantStage >= 0 && plantStage < stageNames.count else { return "Unknown" }
        return stageNames[plantStage]
    }
    
    // MARK: - Webhook Interceptors
    
    public func onTerminalCommandRun() {
        tick()
        waterLevel = min(100.0, waterLevel + 15.0)
        totalActions += 1
        addLog("CLI command run: +15% Water 💧")
        save()
    }
    
    public func onSessionCodeSplitClose() {
        tick()
        fertilizerTime += 120.0
        totalActions += 1
        addLog("Coding split close: +120s Fert 🌸")
        save()
    }
    
    // MARK: - User Controls
    
    public func startWateringAnimation() {
        isWateringActive = true
        animationFrame = 1
        Task {
            for frame in 1...12 {
                try? await Task.sleep(nanoseconds: 120_000_000)
                self.animationFrame = frame
            }
            self.isWateringActive = false
            self.animationFrame = 0
        }
    }
    
    public func startFertilizingAnimation() {
        isFertilizingActive = true
        animationFrame = 1
        Task {
            for frame in 1...12 {
                try? await Task.sleep(nanoseconds: 120_000_000)
                self.animationFrame = frame
            }
            self.isFertilizingActive = false
            self.animationFrame = 0
        }
    }
    
    public func waterPlant() {
        tick()
        waterLevel = min(100.0, waterLevel + 25.0)
        totalActions += 1
        addLog("Watered manually: +25% Water 💧")
        save()
        startWateringAnimation()
    }
    
    public func fertilizePlant() {
        tick()
        fertilizerTime += 60.0
        totalActions += 1
        addLog("Fertilized manually: +60s Fert 🌸")
        save()
        startFertilizingAnimation()
    }
    
    public func reset() {
        plantStage = 0
        waterLevel = 80.0
        growthProgress = 0.0
        fertilizerTime = 0.0
        totalActions = 0
        lastUpdateTime = Date()
        logs = ["Garden reset! 🌱"]
        save()
    }
    
    // MARK: - Persistence
    
    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(plantStage, forKey: "notch_garden_stage")
        defaults.set(waterLevel, forKey: "notch_garden_water")
        defaults.set(growthProgress, forKey: "notch_garden_growth")
        defaults.set(fertilizerTime, forKey: "notch_garden_fertilizer")
        defaults.set(totalActions, forKey: "notch_garden_actions")
        defaults.set(lastUpdateTime.timeIntervalSince1970, forKey: "notch_garden_time")
    }
    
    private func load() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "notch_garden_time") != nil {
            plantStage = defaults.integer(forKey: "notch_garden_stage")
            waterLevel = defaults.double(forKey: "notch_garden_water")
            growthProgress = defaults.double(forKey: "notch_garden_growth")
            fertilizerTime = defaults.double(forKey: "notch_garden_fertilizer")
            totalActions = defaults.integer(forKey: "notch_garden_actions")
            let timeVal = defaults.double(forKey: "notch_garden_time")
            lastUpdateTime = Date(timeIntervalSince1970: timeVal)
        }
    }
}

// MARK: - SwiftUI Canvas Views

struct GardenCanvasView: View {
    @ObservedObject var state = GardenState.shared
    
    var body: some View {
        Canvas { context, size in
            let scale = size.width / 24.0
            
            // 1. Draw soil bed (Rows 20 to 23)
            context.fill(Path(CGRect(x: 0, y: 20 * scale, width: 24 * scale, height: 4 * scale)), with: .color(GardenPalette.soil))
            context.fill(Path(CGRect(x: 0, y: 19 * scale, width: 24 * scale, height: 1 * scale)), with: .color(GardenPalette.soilSurface))
            
            func fillPixel(x: Int, y: Int, color: Color) {
                let rect = CGRect(
                    x: CGFloat(x) * scale,
                    y: CGFloat(y) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(color))
            }
            
            func fillRect(x: Int, y: Int, w: Int, h: Int, color: Color) {
                let rect = CGRect(
                    x: CGFloat(x) * scale,
                    y: CGFloat(y) * scale,
                    width: CGFloat(w) * scale,
                    height: CGFloat(h) * scale
                )
                context.fill(Path(rect), with: .color(color))
            }
            
            // 2. Draw plant based on stage
            switch state.plantStage {
            case 0:
                // Big Seed centered at (10..13, 17..18)
                fillRect(x: 10, y: 17, w: 4, h: 2, color: GardenPalette.seed)
                fillPixel(x: 11, y: 16, color: GardenPalette.seed)
                fillPixel(x: 12, y: 16, color: GardenPalette.seed)
            case 1:
                // Big sprout curved stem
                fillRect(x: 11, y: 14, w: 2, h: 5, color: GardenPalette.stem)
                // Left leaf
                fillPixel(x: 9, y: 15, color: GardenPalette.leaf)
                fillPixel(x: 10, y: 14, color: GardenPalette.leaf)
                // Right leaf
                fillPixel(x: 13, y: 13, color: GardenPalette.leaf)
                fillPixel(x: 14, y: 14, color: GardenPalette.leaf)
            case 2:
                // Tall stem
                fillRect(x: 11, y: 11, w: 2, h: 8, color: GardenPalette.stem)
                // Leaves branching
                fillRect(x: 9, y: 14, w: 2, h: 1, color: GardenPalette.leaf)
                fillPixel(x: 10, y: 13, color: GardenPalette.leaf)
                fillRect(x: 13, y: 12, w: 2, h: 1, color: GardenPalette.leaf)
                fillPixel(x: 14, y: 11, color: GardenPalette.leaf)
            case 3:
                // Tall stem
                fillRect(x: 11, y: 8, w: 2, h: 11, color: GardenPalette.stem)
                fillRect(x: 9, y: 13, w: 2, h: 1, color: GardenPalette.leaf)
                fillRect(x: 13, y: 11, w: 2, h: 1, color: GardenPalette.leaf)
                // Bud at top
                fillRect(x: 10, y: 5, w: 4, h: 3, color: GardenPalette.bud)
                fillRect(x: 11, y: 4, w: 2, h: 1, color: GardenPalette.bud)
            case 4:
                // Massive flower
                fillRect(x: 11, y: 9, w: 2, h: 10, color: GardenPalette.stem)
                fillRect(x: 9, y: 13, w: 2, h: 1, color: GardenPalette.leaf)
                fillRect(x: 13, y: 11, w: 2, h: 1, color: GardenPalette.leaf)
                
                // Outer Petals centered at (12, 5)
                fillRect(x: 9, y: 3, w: 6, h: 6, color: GardenPalette.petalOuter)
                fillRect(x: 8, y: 4, w: 8, h: 4, color: GardenPalette.petalOuter)
                fillRect(x: 11, y: 2, w: 2, h: 8, color: GardenPalette.petalOuter)
                
                // Core
                fillRect(x: 11, y: 4, w: 2, h: 2, color: GardenPalette.petalCenter)
            default:
                break
            }
            
            // 3. Draw water exclamation dot
            if state.waterLevel <= 20.0 {
                fillRect(x: 21, y: 2, w: 1, h: 2, color: Color.red)
                fillPixel(x: 21, y: 5, color: Color.red)
            }
            
            // 4. Draw active pixel-art animations (Watering Can or Fertilizer Bag)
            if state.isWateringActive {
                let canColor = Color(red: 0.2, green: 0.5, blue: 0.9)
                let waterColor = Color(red: 0.0, green: 0.6, blue: 1.0)
                let frame = state.animationFrame
                
                // Drawing tilted watering can floating at x: 3, y: 5
                fillRect(x: 3, y: 5, w: 4, h: 3, color: canColor)
                // Handle (tilted up/left)
                fillPixel(x: 2, y: 5, color: canColor)
                // Spout (tilted down/right)
                fillPixel(x: 7, y: 7, color: canColor)
                fillRect(x: 8, y: 8, w: 2, h: 1, color: canColor)
                
                // Pouring water drops falling down from spout (x: 10) onto soil (y: 19)
                let dropY1 = 9 + ((frame - 1) % 4) * 3
                let dropY2 = 9 + ((frame + 1) % 4) * 3
                if dropY1 < 19 {
                    fillPixel(x: 10, y: dropY1, color: waterColor)
                }
                if dropY2 < 19 {
                    fillPixel(x: 11, y: dropY2, color: waterColor)
                }
            } else if state.isFertilizingActive {
                let bagColor = Color(red: 1.0, green: 0.0, blue: 0.5)
                let leafColor = Color(red: 0.22, green: 0.84, blue: 0.36)
                let frame = state.animationFrame
                
                // Shaking position (frame > 0): wiggle x offset based on frame
                let xOffset = frame % 2 == 0 ? 1 : -1
                let bx = 16 + xOffset
                let by = 5
                
                // Draw bag body (4x5)
                fillRect(x: bx, y: by, w: 4, h: 5, color: bagColor)
                // Draw leaf decoration in the center
                fillPixel(x: bx + 1, y: by + 2, color: leafColor)
                fillPixel(x: bx + 2, y: by + 1, color: leafColor)
                
                // Dropping fertilizer particles
                let pY1 = by + 5 + ((frame - 1) % 3) * 3
                let pY2 = by + 5 + ((frame + 1) % 3) * 3
                if pY1 < 19 {
                    fillPixel(x: bx + 1, y: pY1, color: leafColor)
                }
                if pY2 < 19 {
                    fillPixel(x: bx + 2, y: pY2, color: leafColor)
                }
            }
        }
    }
}

// MARK: - Expanded Panel Card View

struct GardenExpandedView: View {
    @ObservedObject var state = GardenState.shared
    
    // Slow interval updates for UI timer decay visual updates
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("NOTCH GARDEN")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(.white.opacity(0.40))
                
                Spacer()
                
                if state.isCodingFocused {
                    Text("</> CODING BOOST (3x)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color(red: 0.22, green: 1.0, blue: 0.08))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else if state.fertilizerTime > 0 {
                    Text("FERTILIZED")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.0, blue: 0.5))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(red: 1.0, green: 0.0, blue: 0.5).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                // Upscaled Pixel Sprout Card
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 0.75)
                        )
                    
                    GardenCanvasView(state: state)
                        .padding(8)
                }
                .frame(width: 80, height: 80)
                
                // Metrics
                VStack(alignment: .leading, spacing: 6) {
                    Text(state.getStageName())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                    
                    // Water Level progress
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Water Level")
                            Spacer()
                            Text("\(Int(state.waterLevel))%")
                        }
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(.white.opacity(0.08))
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(state.waterLevel <= 20 ? Color.red : Color(red: 0.0, green: 0.6, blue: 1.0))
                                    .frame(width: geo.size.width * CGFloat(state.waterLevel / 100.0))
                            }
                        }
                        .frame(height: 3)
                    }
                    
                    // Growth progress
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Growth Progress")
                            Spacer()
                            Text("\(Int(state.growthProgress))%")
                        }
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(.white.opacity(0.08))
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color(red: 0.22, green: 0.84, blue: 0.36))
                                    .frame(width: geo.size.width * CGFloat(state.growthProgress / 100.0))
                            }
                        }
                        .frame(height: 3)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // Actions
            HStack(spacing: 8) {
                Button(action: { state.waterPlant() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "drop.fill")
                        Text("Water (+25)")
                    }
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(red: 0.0, green: 0.6, blue: 1.0))
                    .frame(maxWidth: .infinity, minHeight: 20)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                
                Button(action: { state.fertilizePlant() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "leaf.fill")
                        Text("Fertilize (+60s)")
                    }
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(red: 1.0, green: 0.0, blue: 0.5))
                    .frame(maxWidth: .infinity, minHeight: 20)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                
                Button(action: { state.reset() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(width: 20, height: 20)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Reset Garden")
            }
        }
        .onReceive(timer) { _ in
            state.tick()
        }
    }
}

// MARK: - Dashboard Terrarium Widget

struct GardenDashboardWidget: View {
    @ObservedObject var state = GardenState.shared
    @Binding var isMinimized: Bool
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 12) {
            // Left: Upscaled pixel art canvas (110x110)
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 0.75)
                    )
                
                GardenCanvasView(state: state)
                    .padding(8)
            }
            .frame(width: 110, height: 110)
            
            // Right: Plant metrics and controls
            VStack(alignment: .leading, spacing: 8) {
                // Header: Title + Coding Boost + Fixed leaf minimize button
                HStack(spacing: 4) {
                    Text(state.getStageName())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    if state.isCodingFocused {
                        Text("</>")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color(red: 0.22, green: 1.0, blue: 0.08))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    
                    // Fixed seedling minimize button: leaf outline (guaranteed to render on macOS 11+)
                    Button(action: {
                        withAnimation(.smooth(duration: 0.25)) {
                            isMinimized = true
                        }
                    }) {
                        Image(systemName: "leaf")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color(red: 0.22, green: 0.84, blue: 0.36))
                            .frame(width: 18, height: 18)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Minimize Garden")
                }
                
                // Compact side-by-side progress pills (takes up very little vertical space)
                HStack(spacing: 6) {
                    // Water Level Pill
                    HStack(spacing: 3) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 7))
                        Text("\(Int(state.waterLevel))%")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(Color(red: 0.0, green: 0.6, blue: 1.0))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(red: 0.0, green: 0.6, blue: 1.0).opacity(0.12))
                    .clipShape(Capsule())
                    
                    // Growth Progress Pill (shows boost speed next to growth percentage!)
                    HStack(spacing: 3) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 7))
                        Text("\(Int(state.growthProgress))%")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                        if state.isCodingFocused {
                            Text("(3x ⚡️)")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.22, green: 1.0, blue: 0.08))
                        }
                    }
                    .foregroundStyle(Color(red: 0.22, green: 0.84, blue: 0.36))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(red: 0.22, green: 0.84, blue: 0.36).opacity(0.12))
                    .clipShape(Capsule())
                }
                
                // Live Activity log console (satisfies "Incentivize actual coding")
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(state.logs, id: \.self) { log in
                        Text(log)
                            .font(.system(size: 7.5, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.38))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(5)
                .background(Color.black.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer(minLength: 0)
                
                // Actions (disabled during animations or when maxed out to prevent spamming)
                HStack(spacing: 6) {
                    Button(action: {
                        guard !state.isWateringActive && state.waterLevel < 100 else { return }
                        state.waterPlant()
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "drop.fill")
                            Text(state.waterLevel >= 100 ? "Full" : "Water")
                        }
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(state.waterLevel >= 100 ? .white.opacity(0.25) : Color(red: 0.0, green: 0.6, blue: 1.0))
                        .frame(maxWidth: .infinity, minHeight: 20)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .disabled(state.waterLevel >= 100 || state.isWateringActive || state.isFertilizingActive)
                    
                    Button(action: {
                        guard !state.isFertilizingActive && state.fertilizerTime < 300 else { return }
                        state.fertilizePlant()
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "leaf.fill")
                            Text(state.fertilizerTime >= 300 ? "Maxed" : "Fertilize")
                        }
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(state.fertilizerTime >= 300 ? .white.opacity(0.25) : Color(red: 1.0, green: 0.0, blue: 0.5))
                        .frame(maxWidth: .infinity, minHeight: 20)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .disabled(state.fertilizerTime >= 300 || state.isFertilizingActive || state.isWateringActive)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.white.opacity(0.05), lineWidth: 0.75)
                )
        )
        .onReceive(timer) { _ in
            state.tick()
        }
    }
}
