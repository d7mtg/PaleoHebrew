import SwiftUI
import CoreMotion

struct InteractiveBackgroundView: View {
    // Motion manager to handle device movement
    @StateObject private var motionManager = MotionManager()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background color based on color scheme
            colorScheme == .dark ? Color.black : Color.white
            
            // Grid of Paleo-Hebrew letters
            LetterGridView(motionOffset: motionManager.motionOffset)
        }
        .ignoresSafeArea()
    }
}

// Handles device motion updates
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var motionOffset = CGSize.zero
    
    init() {
        startMotionUpdates()
    }
    
    func startMotionUpdates() {
        // Check if device motion is available
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let motion = motion, error == nil else { return }
                
                // Apply smooth animation to motion changes
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self?.motionOffset = CGSize(
                        width: motion.gravity.x * 50,
                        height: motion.gravity.y * 50
                    )
                }
            }
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct LetterGridView: View {
    let motionOffset: CGSize
    @Environment(\.colorScheme) private var colorScheme
    
    // Array of Paleo-Hebrew letters
    let letters = ["𐤀", "𐤁", "𐤂", "𐤃", "𐤄", "𐤅", "𐤆", "𐤇", "𐤈", "𐤉",
                   "𐤊", "𐤋", "𐤌", "𐤍", "𐤎", "𐤏", "𐤐", "𐤑", "𐤒", "𐤓", "𐤔", "𐤕"]
    
    var body: some View {
        GeometryReader { geo in
            // Create a fixed grid of letters
            let gridSpacing: CGFloat = 60
            let columns = Int(geo.size.width / gridSpacing) + 1
            let rows = Int(geo.size.height / gridSpacing) + 1
            
            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<columns, id: \.self) { col in
                    // Get a consistent letter for this position
                    let letterIndex = (row * 7 + col * 13) % letters.count
                    let letter = letters[letterIndex]
                    
                    // Calculate position with parallax effect
                    let depth = CGFloat((row * col) % 12 + 1) / 12.0  // Depth factor (0.33, 0.67, or 1.0)
                    let baseX = CGFloat(col) * gridSpacing
                    let baseY = CGFloat(row) * gridSpacing
                    
                    Text(letter)
                        .font(.system(size: 24))
                        .foregroundColor(letterColor)
                        .position(
                            x: baseX + motionOffset.width * depth,
                            y: baseY + motionOffset.height * depth
                        )
                }
            }
        }
    }
    
    // Letter color based on color scheme
    private var letterColor: Color {
        colorScheme == .dark ? Color(white: 0.15, opacity: 1) : Color(white: 0.9, opacity: 1)
    }
}

struct InteractiveBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        InteractiveBackgroundView()
    }
}
