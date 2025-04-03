import UIKit

class KeyButton: UIButton {
    
    
    let primaryLabel = UILabel()
    let secondaryLabel = UILabel()
    
    var isSpecialKey = false
    var modernValue: String?

    var showsHint = true {
        didSet {
            secondaryLabel.isHidden = !showsHint
        }
    }

    var primaryModeIsPaleo: Bool = true {
        didSet {
            updateDisplayMode()
        }
    }
    
    private var deleteTimer: Timer?
    private var deleteInterval: TimeInterval = 0.5

    func setupBackspaceGesture() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        addGestureRecognizer(longPress)
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            startDeleteTimer()
        } else if gesture.state == .ended || gesture.state == .cancelled {
            stopDeleteTimer()
        }
    }

    func startDeleteTimer() {
        deleteTimer = Timer.scheduledTimer(withTimeInterval: deleteInterval, repeats: true) { [weak self] timer in
            self?.sendDeleteAction()
            // Gradually increase deletion speed
            if let interval = self?.deleteInterval, interval > 0.1 {
                self?.deleteInterval -= 0.05
                self?.stopDeleteTimer()
                self?.startDeleteTimer()
            }
        }
    }

    func stopDeleteTimer() {
        deleteTimer?.invalidate()
        deleteTimer = nil
        deleteInterval = 0.5
    }

    func sendDeleteAction() {
        // Trigger the backspace action in the keyboard controller
        sendActions(for: .touchUpInside)
    }

    
    // Store the actual input value (always Paleo Hebrew)
    var inputValue: String?

    init(paleo: String, modern: String?, isBackspace: Bool = false) {
        super.init(frame: .zero)
        
        isSpecialKey = isBackspace
        inputValue = paleo // Always store the Paleo value for input
        modernValue = modern // Store the modern value

        
        // Set up primary label
        primaryLabel.text = paleo
        primaryLabel.font = UIFont.systemFont(ofSize: 24)
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        primaryLabel.textAlignment = .center
        
        // Set up secondary label
        secondaryLabel.text = modern
        secondaryLabel.font = UIFont.systemFont(ofSize: 10)
        secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
        secondaryLabel.textColor = .secondaryLabel
        secondaryLabel.isHidden = !showsHint
        
        addSubview(primaryLabel)
        addSubview(secondaryLabel)
        
        // For backspace button, use system image instead of text
        if isBackspace {
            let imageView = UIImageView(image: UIImage(systemName: "delete.left"))
            imageView.tintColor = .label
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            
            // Store the image view as a tag for later reference
            imageView.tag = 100
            
            primaryLabel.isHidden = true
            secondaryLabel.isHidden = true
        }
        else {
            NSLayoutConstraint.activate([
                primaryLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                primaryLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                secondaryLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
                secondaryLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
            ])
        }
        
        // Style the button
        layer.cornerRadius = 4.6
        updateColors()
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 0
        
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        // Add trait collection change observer
        registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { (self: Self, previousTraitCollection: UITraitCollection) in
            self.updateColors()
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateColors() {
        if traitCollection.userInterfaceStyle == .dark {
            // For dark mode, create a gradient background with plus-lighter blend mode
            backgroundColor = isSpecialKey ? UIColor(hex: "3d3d3d") : UIColor(hex: "757575")
            primaryLabel.textColor = .white
            viewWithTag(100)?.tintColor = .white
            

            
            // Add a slight overlay to simulate the background-blend-mode effect
            if let sublayer = layer.sublayers?.first(where: { $0.name == "blendOverlay" }) {
                sublayer.removeFromSuperlayer()
            }
            
            let overlayLayer = CALayer()
            overlayLayer.name = "blendOverlay"
            overlayLayer.frame = bounds
            overlayLayer.backgroundColor = UIColor(white: 1.0, alpha: 0.15).cgColor

            layer.insertSublayer(overlayLayer, at: 0)
        } else {
            // For light mode, use regular background
            backgroundColor = isSpecialKey ? UIColor(hex: "ABB4C1") : .white
            primaryLabel.textColor = .black
            viewWithTag(100)?.tintColor = .black
            
            // Remove any blend mode effects
            layer.compositingFilter = nil
            
            // Remove any overlay layers
            if let sublayer = layer.sublayers?.first(where: { $0.name == "blendOverlay" }) {
                sublayer.removeFromSuperlayer()
            }
        }
    }


    func updateDisplayMode() {
        if primaryModeIsPaleo {
            // Display Paleo Hebrew
            primaryLabel.text = inputValue
            secondaryLabel.text = modernValue
        } else {
            // Display Modern Hebrew
            primaryLabel.text = modernValue
            secondaryLabel.text = inputValue
        }
        
        primaryLabel.font = UIFont.systemFont(ofSize: 24)
        secondaryLabel.font = UIFont.systemFont(ofSize: 10)
        
        primaryLabel.isHidden = isSpecialKey
        secondaryLabel.isHidden = isSpecialKey || !showsHint
    }


}

class KeyboardViewController: UIInputViewController {
    var showHints = true
    var primaryModeIsPaleo = true {
        didSet {
            updateKeyboardMode()
        }
    }
    
    // Visual effect view for backdrop blur in dark mode
    var blurEffectView: UIVisualEffectView?
    private let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
     private let mediumImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    // Store the keyboard layout
    var layout: [[(paleo: String, modern: String, isBackspace: Bool)]] = [
        [("𐤒","ק", false),("𐤓","ר", false),("𐤀","א", false),("𐤈","ט", false),("𐤅","ו", false),("𐤍","ן", false),("𐤌","ם", false),("𐤐","פ", false),("⌫","", true)],
        [("𐤔","ש", false),("𐤃","ד", false),("𐤂","ג", false),("𐤊","כ", false),("𐤏","ע", false),("𐤉","י", false),("𐤇","ח", false),("𐤋","ל", false),("𐤊","ך", false)],
        [("𐤆","ז", false),("𐤎","ס", false),("𐤁","ב", false),("𐤄","ה", false),("𐤍","נ", false),("𐤌","מ", false),("𐤑","צ", false),("𐤕","ת", false),("𐤑","ץ", false)]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        updateBackgroundColor()
        setupKeyboard()
        let defaults = UserDefaults(suiteName: "group.com.d7mtg.paleopro")
        defaults?.set(true, forKey: "keyboardHasLaunched")
        
        // Add trait collection change observer
        registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { (self: Self, previousTraitCollection: UITraitCollection) in
            self.updateBackgroundColor()
        })
    }
    
    func updateBackgroundColor() {
        // Remove existing blur if any
        blurEffectView?.removeFromSuperview()
        blurEffectView = nil
        
        if traitCollection.userInterfaceStyle == .dark {
            // Create semi-transparent background
            view.backgroundColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 0.00)
            
            // Add blur effect
            let blurEffect = UIBlurEffect(style: .regular)
            blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView!.frame = view.bounds
            blurEffectView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.insertSubview(blurEffectView!, at: 0)
        } else {
            view.backgroundColor = UIColor(hex: "D0D5DC")
        }
    }
    
    func updateKeyboardMode() {
        // Update all key buttons with the new mode
        for view in view.subviewsRecursive() {
            if let key = view as? KeyButton {
                key.primaryModeIsPaleo = primaryModeIsPaleo
            }
        }
    }

    func setupKeyboard() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.semanticContentAttribute = .forceRightToLeft
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])

        // Add the character key rows
        for row in layout {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 4
            rowStack.distribution = .fillEqually
            rowStack.semanticContentAttribute = .forceLeftToRight // Flipped to move backspace to left side
            
            for key in row {
                let button = KeyButton(paleo: key.paleo, modern: key.modern, isBackspace: key.isBackspace)
                button.showsHint = showHints
                button.primaryModeIsPaleo = primaryModeIsPaleo
                
                if key.isBackspace {
                    button.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
                } else {
                    button.addTarget(self, action: #selector(tapKey(_:)), for: .touchUpInside)
                }
                
                rowStack.addArrangedSubview(button)
            }

            stack.addArrangedSubview(rowStack)
        }

        // Bottom row with swap, space, and return buttons
        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.spacing = 4
        
        // Swap mode button (left side now)
        let swapModeButton = specialButton("", #selector(toggleMode), isSpecial: true)
        let swapImage = UIImage(systemName: "arrow.up.arrow.down.circle")
        swapModeButton.setImage(swapImage, for: .normal)
        if traitCollection.userInterfaceStyle == .dark {
            swapModeButton.tintColor = .white
        } else {
            swapModeButton.tintColor = .black
        }

        // Space button (center, wide)
        let space = specialButton("Space", #selector(spaceTapped), isSpecial: false)

        // Return button (right side now)
        let enter = specialButton("", #selector(returnTapped), isSpecial: true)
        let returnImage = UIImage(systemName: "return")?.withHorizontallyFlippedOrientation()
        enter.setImage(returnImage, for: .normal)
        if traitCollection.userInterfaceStyle == .dark {
            enter.tintColor = .white
        } else {
            enter.tintColor = .black
        }

        
        bottomRow.addArrangedSubview(swapModeButton)
        bottomRow.addArrangedSubview(space)
        bottomRow.addArrangedSubview(enter)
        
        // Set width constraints to make space wider
        enter.widthAnchor.constraint(equalTo: swapModeButton.widthAnchor, multiplier: 1.0).isActive = true
        space.widthAnchor.constraint(equalTo: bottomRow.widthAnchor, multiplier: 0.6).isActive = true
        
        stack.addArrangedSubview(bottomRow)
    }

    func specialButton(_ title: String, _ action: Selector, isSpecial: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 4.6
        
        // Set colors based on interface style
        if traitCollection.userInterfaceStyle == .dark {
            button.backgroundColor = isSpecial ? UIColor(hex: "3d3d3d") : UIColor(hex: "757575")
            

            
            button.setTitleColor(.white, for: .normal)
            
            // Add the plus-lighter blend mode effect

            
            // Add a slight overlay to simulate the background-blend-mode effect
            let overlayLayer = CALayer()
            overlayLayer.name = "blendOverlay"
            overlayLayer.frame = button.bounds
            overlayLayer.backgroundColor = UIColor(white: 1.0, alpha: 0.15).cgColor
            button.layer.insertSublayer(overlayLayer, at: 0)
        } else {
            button.backgroundColor = isSpecial ? UIColor(hex: "ABB4C1") : .white
            button.setTitleColor(.black, for: .normal)
            
            // Remove any blend mode effects
            button.layer.compositingFilter = nil
        }
        
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.35
        button.layer.shadowRadius = 0
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        
        // Add trait collection change observer for color updates
        button.registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { (button: UIButton, previousTraitCollection: UITraitCollection) in
            if button.traitCollection.userInterfaceStyle == .dark {
                button.backgroundColor = isSpecial ? UIColor(hex: "555555") : UIColor(hex: "959595")
                button.setTitleColor(.white, for: .normal)
                button.tintColor = .white
                

                
                // Add a slight overlay to simulate the background-blend-mode effect
                if let sublayer = button.layer.sublayers?.first(where: { $0.name == "blendOverlay" }) {
                    sublayer.removeFromSuperlayer()
                }
                
                let overlayLayer = CALayer()
                overlayLayer.frame = button.bounds
                overlayLayer.backgroundColor = UIColor(white: 1.0, alpha: 0.15).cgColor
                button.layer.insertSublayer(overlayLayer, at: 0)
            } else {
                button.backgroundColor = isSpecial ? UIColor(hex: "ABB4C1") : .white
                button.setTitleColor(.black, for: .normal)
                button.tintColor = .black
                
                // Remove any blend mode effects
                button.layer.compositingFilter = nil
                
                // Remove any overlay layers
                if let sublayer = button.layer.sublayers?.first(where: { $0.name == "blendOverlay" }) {
                    sublayer.removeFromSuperlayer()
                }
            }
        })
        
        return button
    }


    @objc func tapKey(_ sender: KeyButton) {
        // Always insert the Paleo Hebrew character regardless of display mode
        textDocumentProxy.insertText(sender.inputValue ?? "")
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc func spaceTapped() {
        textDocumentProxy.insertText(" ")
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc func returnTapped() {
        textDocumentProxy.insertText("\n")
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc func toggleMode() {
        primaryModeIsPaleo.toggle()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    @objc func backspaceTapped() {
        textDocumentProxy.deleteBackward()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc func toggleHints() {
        showHints.toggle()
        for view in view.subviewsRecursive() {
            if let key = view as? KeyButton {
                key.showsHint = showHints
            }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    override var textInputMode: UITextInputMode? {
        // Hint the system to treat input as Hebrew (RTL)
        return UITextInputMode.activeInputModes.first { $0.primaryLanguage == "he" }
    }
}

extension UIView {
    func subviewsRecursive() -> [UIView] {
        return subviews + subviews.flatMap { $0.subviewsRecursive() }
    }
}

// Add a UIColor extension to handle hex colors
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
