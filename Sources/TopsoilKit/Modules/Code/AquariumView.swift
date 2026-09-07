import SwiftUI
import Combine

// MARK: - Pixel Art Data Structures

struct PixelFishData {
    static let names = [
        "Clownfish", "Blue Tang", "Goldfish", "Angelfish", "Pufferfish", "Swordfish",
        "Betta Fish", "Koi Fish", "Shark", "Catfish", "Lionfish", "Sunfish"
    ]
    
    static let grids: [[String]] = [
        // 1. Clownfish
        [
            "...................",
            ".......kk..........",
            ".....oddoak........",
            "...oodoooooo...kk..",
            "..ooodwwoowwoooook.",
            ".ookodwwoowwooooook",
            "ooooooooooooooooook",
            ".oooodwwoowwooooook",
            "..ooodwwoowwoooook.",
            "...oodoooooo...kk..",
            ".....oddoak........",
            ".......kk..........",
            "..................."
        ],
        // 2. Blue Tang
        [
            "...................",
            "....kkkk...........",
            "...kbbbbk..........",
            "..kbbbkkkk....kk...",
            ".kbwkkbbbbk..kyyk..",
            ".kbbkkbbbbbbkkyyyk.",
            "kbbbkkbbbbbbbyyyyk.",
            ".kbbbkbbbbbbkkyyyk.",
            "..kbbbkbbbbbb.kyyk.",
            "...kbbbbbbbk....kk.",
            "....kkkkkk.........",
            "...................",
            "..................."
        ],
        // 3. Goldfish
        [
            "...................",
            ".....gg............",
            "....goog....gg.....",
            "...goooog..goog....",
            "..gowkoooggoooog...",
            ".gowkooooooooooog..",
            "gooooooooooggoooog.",
            ".gooooooogg..gooog.",
            "..gooooogg....ggg..",
            "...gooogg..........",
            "....gggg...........",
            "...................",
            "..................."
        ],
        // 4. Angelfish
        [
            "......k............",
            ".....kyk...........",
            "....kyyyk..........",
            "...kysksyk.........",
            "..kywksksyk........",
            ".kyssksssyk...kk...",
            "kyssskskssyk.kssk..",
            ".kyssksssyk...ksk..",
            "..kyskssyk.....k...",
            "...kysksyk.........",
            "....kyyyk..........",
            ".....kyk...........",
            "......k............"
        ],
        // 5. Pufferfish
        [
            "...................",
            "....knknknk........",
            "...knhnhnhnk.......",
            "..knhhhhhhhnk..kk..",
            ".knwkhhnhhhnkkhhk..",
            ".knwkhhnhnhhnkhhhk.",
            "knhhhhhnhhhhkhhk...",
            ".knhhhnhnhhnkhhhk..",
            ".knhhhhnhhhnkkhhk..",
            "..knhhhhhhhnk..kk..",
            "...knhnhnhnk.......",
            "....knknknk........",
            "..................."
        ],
        // 6. Swordfish
        [
            "........k..........",
            ".......ksk.........",
            "......ksssk........",
            ".....ksssssk...kk..",
            "....kswkssssk.kssk.",
            "kkkkkksssssssssssk.",
            "....ksssssssssssk..",
            ".....kssssssskk....",
            "......ksssssk......",
            ".......ksssk.......",
            "........ksk........",
            ".........k.........",
            "..................."
        ],
        // 7. Betta Fish
        [
            ".....ppppp.........",
            "....ppmmmpp........",
            "...ppmmmmmpp.......",
            "..pmwkmmmmmp..pp...",
            ".pmmmmmmmmmpppmpp..",
            "pmmmmmmmmmmmmmmmmp.",
            ".pmmmmmmmmmpppmpp..",
            "..pmmmmmmmpp..pp...",
            "...ppmmmpp.........",
            "....ppppp..........",
            "...................",
            "...................",
            "..................."
        ],
        // 8. Koi Fish
        [
            "...................",
            ".......rr..........",
            ".....wwrrw.........",
            "...wwwwwwww........",
            "..wwwrrrwkww...ww..",
            ".wwkwwrrwwwwww.wwww",
            "wwwwwwwwkkwwwwwwww.",
            ".wwkwwwwwwwww.wwww.",
            "..wwwrrrwkww...ww..",
            "...wwwwwwww........",
            ".....wwrrw.........",
            ".......rr..........",
            "..................."
        ],
        // 9. Shark
        [
            "...................",
            ".......g...........",
            "......ggg..........",
            ".....gggg......g...",
            "....gggggg....gg...",
            "...gggggggg..ggg...",
            "..ggkgggggggggggg..",
            ".ggggggggggggggggg.",
            "ggggrrgggggggggggg.",
            ".wwwwwwwwwww..ggg..",
            "..wwwwwwww.....gg..",
            "................g..",
            "..................."
        ],
        // 10. Catfish
        [
            "...................",
            "...................",
            "......nnnnn........",
            ".....nnnnnnn.......",
            "...nnnnnnnnnn..n...",
            "..nnknnnnnnnn.nn...",
            "nnnnnnnnnnnnnnnnn..",
            ".n.nnnnnnnnnnnn....",
            "n...nnwwwwwwnn.....",
            "....nwwwwwwn.......",
            ".....wwwww.........",
            "...................",
            "..................."
        ],
        // 11. Lionfish
        [
            "...r...r...r.......",
            "....r..r..r........",
            ".....rrrrr.........",
            "....rwrwrwr....r...",
            "...rwrwrwrwr..rr...",
            "..rwkwrwrwrwrrrrr..",
            ".rwwrwrwrwrwrrrrr..",
            "..rwrwrwrwrwrrrrr..",
            "...rwrwrwrwr..rr...",
            "....rwrwrwr....r...",
            ".....rrrrr.........",
            "....r..r..r........",
            "...r...r...r......."
        ],
        // 12. Sunfish
        [
            "......kk...........",
            ".....kssk..........",
            ".....kssk..........",
            "....kssssk.........",
            "...kssssssk........",
            "..ksswkkssssk......",
            ".ksssssssssssk.....",
            "..ksssssssssk......",
            "...kssssssk........",
            "....kssssk.........",
            ".....kssk..........",
            ".....kssk..........",
            "......kk..........."
        ]
    ]
    
    static let palettes: [[Character: Color]] = [
        // 1. Clownfish
        [
            "k": Color(red: 0.05, green: 0.05, blue: 0.05),
            "w": .white,
            "o": Color(red: 1.0, green: 0.42, blue: 0.0),
            "d": Color(red: 0.8, green: 0.32, blue: 0.0),
            "a": Color(red: 0.0, green: 0.8, blue: 1.0)
        ],
        // 2. Blue Tang
        [
            "k": Color(red: 0.05, green: 0.05, blue: 0.05),
            "w": .white,
            "b": Color(red: 0.0, green: 0.27, blue: 0.8),
            "y": Color(red: 1.0, green: 0.82, blue: 0.0)
        ],
        // 3. Goldfish
        [
            "g": Color(red: 1.0, green: 0.27, blue: 0.0),
            "o": Color(red: 1.0, green: 0.67, blue: 0.0),
            "w": .white,
            "k": Color(red: 0.05, green: 0.05, blue: 0.05)
        ],
        // 4. Angelfish
        [
            "k": Color(red: 0.05, green: 0.05, blue: 0.05),
            "y": Color(red: 1.0, green: 0.82, blue: 0.0),
            "s": Color(red: 0.88, green: 0.88, blue: 0.88),
            "w": .white,
            "m": Color(red: 0.72, green: 0.0, blue: 0.36),
            "b": Color(red: 0.29, green: 0.0, blue: 0.16)
        ],
        // 5. Pufferfish
        [
            "k": Color(red: 0.05, green: 0.05, blue: 0.05),
            "n": Color(red: 0.84, green: 0.63, blue: 0.36),
            "h": Color(red: 0.96, green: 0.89, blue: 0.76),
            "w": .white
        ],
        // 6. Swordfish
        [
            "k": Color(red: 0.05, green: 0.05, blue: 0.05),
            "s": Color(red: 0.36, green: 0.46, blue: 0.55),
            "w": .white
        ],
        // 7. Betta Fish
        [
            "m": Color(red: 0.72, green: 0.0, blue: 0.36),
            "p": Color(red: 1.0, green: 0.31, blue: 0.61),
            "k": Color(red: 0.05, green: 0.05, blue: 0.05),
            "w": .white
        ],
        // 8. Koi Fish
        [
            "w": .white,
            "r": Color(red: 0.9, green: 0.12, blue: 0.08),
            "k": Color(red: 0.1, green: 0.1, blue: 0.1)
        ],
        // 9. Shark
        [
            "g": Color(red: 0.44, green: 0.5, blue: 0.56),
            "w": .white,
            "k": Color(red: 0.05, green: 0.05, blue: 0.05),
            "r": Color(red: 1.0, green: 0.2, blue: 0.2)
        ],
        // 10. Catfish
        [
            "n": Color(red: 0.54, green: 0.44, blue: 0.31),
            "w": .white,
            "k": Color(red: 0.05, green: 0.05, blue: 0.05)
        ],
        // 11. Lionfish
        [
            "r": Color(red: 0.7, green: 0.14, blue: 0.14),
            "w": Color(red: 0.99, green: 0.99, blue: 0.99),
            "k": Color(red: 0.07, green: 0.07, blue: 0.07)
        ],
        // 12. Sunfish
        [
            "k": Color(red: 0.05, green: 0.05, blue: 0.05),
            "s": Color(red: 0.69, green: 0.77, blue: 0.87),
            "w": .white
        ]
    ]
}

// MARK: - Simulation Models

final class PixelFish: Identifiable, @unchecked Sendable {
    let id = UUID()
    var index: Int // 0 to 11
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var scale: CGFloat = 2.0 // each sprite pixel is 2x2 physical pixels
    var wigglePhase: Double
    var swimSpeed: Double
    var flipX: Bool
    
    // AI target
    var targetFoodID: UUID?
    
    init(index: Int, x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat) {
        self.index = index
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.wigglePhase = Double.random(in: 0...100)
        self.swimSpeed = Double.random(in: 0.12...0.22)
        self.flipX = vx < 0
    }
}

struct PixelFood: Identifiable, Sendable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vy: CGFloat
    var color: Color
}

struct PixelBubble: Identifiable, Sendable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var radius: CGFloat
    var speed: CGFloat
}

struct PixelSparkle: Identifiable, Sendable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var size: CGFloat
    var alpha: Double
    var color: Color
}

// MARK: - Simulator State

@MainActor
final class PixelAquariumState: ObservableObject {
    @Published var fishList: [PixelFish] = []
    @Published var foods: [PixelFood] = []
    @Published var bubbles: [PixelBubble] = []
    @Published var sparkles: [PixelSparkle] = []
    
    private var isInitialized = false
    
    func initializeIfNeeded(width: CGFloat, height: CGFloat) {
        guard !isInitialized && width > 50 && height > 20 else { return }
        isInitialized = true
        
        // Spawn 8 active fish
        for i in 0..<8 {
            let index = i % 12
            let fx = CGFloat.random(in: 40...(width - 40))
            let fy = CGFloat.random(in: 18...(height - 18))
            let speed = index == 11 ? CGFloat(0.28) : CGFloat.random(in: 0.5...0.9)
            let vx = (Bool.random() ? 1 : -1) * speed
            let vy = CGFloat.random(in: -0.1...0.1)
            
            fishList.append(PixelFish(index: index, x: fx, y: fy, vx: vx, vy: vy))
        }
        
        // Spawn initial bubbles
        for _ in 0..<8 {
            bubbles.append(PixelBubble(
                x: CGFloat.random(in: 15...(width - 15)),
                y: CGFloat.random(in: 10...(height - 10)),
                radius: CGFloat(Int.random(in: 1...2)),
                speed: CGFloat.random(in: 0.2...0.5)
            ))
        }
    }
    
    func feed(x: CGFloat, y: CGFloat) {
        // Spawn 2 food particles
        for _ in 0..<2 {
            foods.append(PixelFood(
                x: x + CGFloat.random(in: -8...8),
                y: y + CGFloat.random(in: -5...5),
                vy: CGFloat.random(in: 0.25...0.45),
                color: Color(red: 0.88, green: 0.58, blue: 0.36) // Pixelated food flake
            ))
        }
    }
    
    func update(width: CGFloat, height: CGFloat, isBatterySaver: Bool) {
        guard isInitialized else { return }
        
        // 1. Spawning bubbles
        let maxBubbles = isBatterySaver ? 6 : 18
        if bubbles.count < maxBubbles && Double.random(in: 0...1) < (isBatterySaver ? 0.01 : 0.03) {
            bubbles.append(PixelBubble(
                x: CGFloat.random(in: 10...(width - 10)),
                y: height + 3,
                radius: CGFloat(Int.random(in: 1...2)),
                speed: CGFloat.random(in: 0.2...0.5)
            ))
        }
        
        // 2. Update Bubbles
        for i in (0..<bubbles.count).reversed() {
            bubbles[i].y -= bubbles[i].speed
            bubbles[i].x += sin(Double(bubbles[i].y) * 0.06) * 0.15
            if bubbles[i].y < -3 {
                bubbles.remove(at: i)
            }
        }
        
        // 3. Update Food
        for i in (0..<foods.count).reversed() {
            foods[i].y += foods[i].vy
            foods[i].x += sin(Double(foods[i].y) * 0.1) * 0.08
            if foods[i].y > height - 8 {
                foods.remove(at: i)
            }
        }
        
        // 4. Update Sparkles
        for i in (0..<sparkles.count).reversed() {
            sparkles[i].x += sparkles[i].vx
            sparkles[i].y += sparkles[i].vy
            sparkles[i].alpha -= 0.04
            if sparkles[i].alpha <= 0 {
                sparkles.remove(at: i)
            }
        }
        
        // 5. Update Fish AI & physics
        for fish in fishList {
            fish.wigglePhase += fish.swimSpeed
            
            // Food targeting
            if !foods.isEmpty {
                var nearestFlake: PixelFood? = nil
                var minDistance: CGFloat = 180.0
                
                for flake in foods {
                    let dx = flake.x - fish.x
                    let dy = flake.y - fish.y
                    let dist = sqrt(dx*dx + dy*dy)
                    if dist < minDistance {
                        minDistance = dist
                        nearestFlake = flake
                    }
                }
                
                if let target = nearestFlake {
                    fish.targetFoodID = target.id
                    
                    let dx = target.x - fish.x
                    let dy = target.y - fish.y
                    let dist = sqrt(dx*dx + dy*dy)
                    
                    if dist > 3 {
                        let targetVx = (dx / dist) * (isBatterySaver ? 0.6 : 0.9)
                        let targetVy = (dy / dist) * (isBatterySaver ? 0.6 : 0.9)
                        
                        fish.vx = fish.vx * 0.93 + targetVx * 0.07
                        fish.vy = fish.vy * 0.93 + targetVy * 0.07
                        fish.flipX = fish.vx < 0
                    }
                    
                    if dist < 8 {
                        // eat!
                        if let idx = foods.firstIndex(where: { $0.id == target.id }) {
                            foods.remove(at: idx)
                        }
                        fish.targetFoodID = nil
                        
                        // spawn tiny pixel sparkles
                        for _ in 0..<(isBatterySaver ? 2 : 5) {
                            sparkles.append(PixelSparkle(
                                x: fish.x,
                                y: fish.y,
                                vx: CGFloat.random(in: -0.9...0.9),
                                vy: CGFloat.random(in: -0.9...0.9),
                                size: CGFloat(Int.random(in: 1...2)),
                                alpha: 1.0,
                                color: .white
                            ))
                        }
                    }
                } else {
                    fish.targetFoodID = nil
                }
            } else {
                fish.targetFoodID = nil
            }
            
            // wander drift
            if fish.targetFoodID == nil {
                if Double.random(in: 0...1) < 0.015 {
                    fish.vy += CGFloat.random(in: -0.06...0.06)
                    fish.vy = max(-0.22, min(0.22, fish.vy))
                }
                
                let targetSpeed = fish.index == 11 ? CGFloat(0.3) : CGFloat(0.6)
                let currentSpeed = abs(fish.vx)
                if currentSpeed < targetSpeed {
                    fish.vx += (fish.vx > 0 ? 1 : -1) * 0.012
                }
            }
            
            fish.x += fish.vx
            fish.y += fish.vy
            
            // Wall bounce
            if fish.x < 19 {
                fish.x = 19
                fish.vx = abs(fish.vx)
                fish.flipX = false
            } else if fish.x > width - 19 {
                fish.x = width - 19
                fish.vx = -abs(fish.vx)
                fish.flipX = true
            }
            
            // Top/bottom limits
            if fish.y < 12 {
                fish.y = 12
                fish.vy = abs(fish.vy)
            } else if fish.y > height - 12 {
                fish.y = height - 12
                fish.vy = -abs(fish.vy)
            }
        }
    }
}

// MARK: - SwiftUI View Component

struct AquariumView: View {
    @EnvironmentObject var windowModel: NotchWindowModel
    @StateObject private var simulator = PixelAquariumState()
    
    var body: some View {
        if !windowModel.isExpanded {
            Color.clear
                .frame(height: 64)
        } else {
            if windowModel.settings.isAquariumBatterySaverEnabled {
                TimelineView(.periodic(from: Date(), by: 0.12)) { timeline in
                    aquariumCanvas
                }
            } else {
                TimelineView(.animation) { timeline in
                    aquariumCanvas
                }
            }
        }
    }
    
    private var aquariumCanvas: some View {
        Canvas { context, size in
            simulator.initializeIfNeeded(width: size.width, height: size.height)
            simulator.update(width: size.width, height: size.height, isBatterySaver: windowModel.settings.isAquariumBatterySaverEnabled)
            
            // 1. Draw Deep Blue water wash
            let waterRect = CGRect(origin: .zero, size: size)
            context.fill(Path(waterRect), with: GraphicsContext.Shading.linearGradient(
                Gradient(colors: [
                    Color(red: 0.04, green: 0.08, blue: 0.16),
                    Color(red: 0.06, green: 0.13, blue: 0.24)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)
            ))
            
            // Soft glow background spotlight under notch
            context.fill(Path(waterRect), with: GraphicsContext.Shading.radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.0, green: 0.6, blue: 1.0).opacity(0.12), location: 0),
                    .init(color: .clear, location: 1)
                ]),
                center: CGPoint(x: size.width / 2, y: -10),
                startRadius: 0,
                endRadius: size.width * 0.4
            ))
            
            // 2. Draw Bubbles
            for bubble in simulator.bubbles {
                let rect = CGRect(
                    x: bubble.x - bubble.radius,
                    y: bubble.y - bubble.radius,
                    width: bubble.radius * 2,
                    height: bubble.radius * 2
                )
                context.fill(Path(rect), with: GraphicsContext.Shading.color(.white.opacity(0.18)))
            }
            
            // 3. Draw Food Particles
            for food in simulator.foods {
                let rect = CGRect(x: food.x - 1, y: food.y - 1, width: 2, height: 2)
                context.fill(Path(rect), with: GraphicsContext.Shading.color(food.color))
            }
            
            // 4. Draw Sparkle Flakes
            for sparkle in simulator.sparkles {
                let rect = CGRect(
                    x: sparkle.x - sparkle.size/2,
                    y: sparkle.y - sparkle.size/2,
                    width: sparkle.size,
                    height: sparkle.size
                )
                context.fill(Path(rect), with: GraphicsContext.Shading.color(sparkle.color.opacity(sparkle.alpha)))
            }
            
            // 5. Draw Pixel Art Fish
            for fish in simulator.fishList {
                drawPixelFish(context: &context, fish: fish)
            }
            
            // 6. Draw Sandy Floor (Pixelated line)
            let floorRect = CGRect(x: 0, y: size.height - 4, width: size.width, height: 4)
            context.fill(Path(floorRect), with: GraphicsContext.Shading.color(Color(red: 0.72, green: 0.54, blue: 0.32).opacity(0.42)))
        }
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.36))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 0.75)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture { location in
            simulator.feed(x: location.x, y: location.y)
        }
    }
    
    private func drawPixelFish(context: inout GraphicsContext, fish: PixelFish) {
        let grid = PixelFishData.grids[fish.index]
        let palette = PixelFishData.palettes[fish.index]
        
        let scale = fish.scale
        let w = 19
        let h = 13
        
        let startX = fish.x - (CGFloat(w) * scale) / 2
        let startY = fish.y - (CGFloat(h) * scale) / 2
        
        for r in 0..<h {
            let rowChars = Array(grid[r])
            for c in 0..<w {
                let char = rowChars[c]
                guard char != "." else { continue }
                
                let color = palette[char] ?? .clear
                guard color != .clear else { continue }
                
                // Tail wiggle offset wave
                var yOffset: CGFloat = 0
                if c > 8 {
                    let progress = CGFloat(c - 8) / CGFloat(w - 8)
                    yOffset = CGFloat(sin(fish.wigglePhase + Double(c) * 0.45)) * 0.8 * progress * scale
                }
                
                // Horizontal flip mapping
                let drawC = fish.flipX ? (w - 1 - c) : c
                let px = startX + CGFloat(drawC) * scale
                let py = startY + CGFloat(r) * scale + yOffset
                
                let pixelRect = CGRect(x: px, y: py, width: scale, height: scale)
                context.fill(Path(pixelRect), with: GraphicsContext.Shading.color(color))
            }
        }
    }
}
