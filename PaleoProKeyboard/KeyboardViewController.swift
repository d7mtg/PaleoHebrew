import UIKit

// MARK: - Extensions

extension UIView {
    /// Recursively returns all subviews.
    func subviewsRecursive() -> [UIView] {
        return subviews + subviews.flatMap { $0.subviewsRecursive() }
    }
}

extension UIColor {
    /// Initializes a UIColor from a hex string.
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

// MARK: - KeyButton

/// A custom UIButton representing an individual key in the keyboard.
class KeyButton: UIButton {
    
    // MARK: UI Elements
    let primaryLabel = UILabel()
    let secondaryLabel = UILabel()
    
    // MARK: Properties
    var isSpecialKey = false
    var modernValue: String?
    var inputValue: String?
    
    /// Controls the visibility of the secondary label.
    var showsHint = true {
        didSet { secondaryLabel.isHidden = !showsHint }
    }
    
    /// Determines which language is shown on the key.
    var primaryModeIsPaleo: Bool = true {
        didSet { updateDisplayMode() }
    }
    
    // MARK: Backspace Timer Properties
    private var deleteTimer: Timer?
    private var deleteInterval: TimeInterval = 0.5
    
    // MARK: Initialization
    init(paleo: String, modern: String?, isBackspace: Bool = false) {
        super.init(frame: .zero)
        isSpecialKey = isBackspace
        inputValue = paleo      // Always store Paleo value for input
        modernValue = modern    // Store modern value for display
        
        setupLabels(paleo: paleo, modern: modern, isBackspace: isBackspace)
        setupLayout(isBackspace: isBackspace)
        styleButton()
        
        // Set up backspace specific logic if needed
        if isBackspace {
            setupBackspaceGesture()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup Methods
    private func setupLabels(paleo: String, modern: String?, isBackspace: Bool) {
        // Configure primary label
        primaryLabel.text = paleo
        primaryLabel.font = UIFont.systemFont(ofSize: 24)
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        primaryLabel.textAlignment = .center
        
        // Configure secondary label (hint)
        secondaryLabel.text = modern
        secondaryLabel.font = UIFont.systemFont(ofSize: 10)
        secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
        secondaryLabel.textColor = .secondaryLabel
        secondaryLabel.isHidden = !showsHint
    }
    
    private func setupLayout(isBackspace: Bool) {
        addSubview(primaryLabel)
        addSubview(secondaryLabel)
        
        if isBackspace {
            // For backspace, use a system image instead of text labels.
            let imageView = UIImageView(image: UIImage(systemName: "delete.left"))
            imageView.tintColor = .label
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)
            imageView.tag = 100
            
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            primaryLabel.isHidden = true
            secondaryLabel.isHidden = true
        } else {
            NSLayoutConstraint.activate([
                primaryLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                primaryLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                secondaryLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
                secondaryLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
            ])
        }
        
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 45).isActive = true
    }
    
    // MARK: UI Update Methods
    /// Updates the displayed text based on the current display mode.
    func updateDisplayMode() {
        if primaryModeIsPaleo {
            primaryLabel.text = inputValue
            secondaryLabel.text = modernValue
        } else {
            primaryLabel.text = modernValue
            secondaryLabel.text = inputValue
        }
        primaryLabel.font = UIFont.systemFont(ofSize: 24)
        secondaryLabel.font = UIFont.systemFont(ofSize: 10)
        primaryLabel.isHidden = isSpecialKey
        secondaryLabel.isHidden = isSpecialKey || !showsHint
    }
    
    /// Styles the button (corner radius, shadow, and colors).
    func styleButton() {
        layer.cornerRadius = 4.6
        updateColors()
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 0
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColors()
    }
    
    /// Updates the button’s colors and overlay based on the current interface style.
    func updateColors() {
        if traitCollection.userInterfaceStyle == .dark {
            backgroundColor = isSpecialKey ? UIColor(hex: "3d3d3d") : UIColor(hex: "757575")
            primaryLabel.textColor = .white
            viewWithTag(100)?.tintColor = .white
            addOverlay()
        } else {
            backgroundColor = isSpecialKey ? UIColor(hex: "ABB4C1") : .white
            primaryLabel.textColor = .black
            viewWithTag(100)?.tintColor = .black
            removeOverlay()
        }
    }
    
    private func addOverlay() {
        removeOverlay()  // Remove any existing overlay
        let overlayLayer = CALayer()
        overlayLayer.name = "blendOverlay"
        overlayLayer.frame = bounds
        overlayLayer.backgroundColor = UIColor(white: 1.0, alpha: 0.15).cgColor
        layer.insertSublayer(overlayLayer, at: 0)
    }
    
    private func removeOverlay() {
        layer.sublayers?.removeAll { $0.name == "blendOverlay" }
    }
    
    // MARK: Backspace Gesture & Timer Methods
    /// Sets up a long-press gesture to handle continuous backspace deletion.
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
            // Gradually increase deletion speed.
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
    
    /// Triggers the backspace action.
    func sendDeleteAction() {
        sendActions(for: .touchUpInside)
    }
}

// MARK: - KeyboardViewController

/// The main view controller for the custom keyboard.
class KeyboardViewController: UIInputViewController {

    // MARK: Properties
    var showHints = true
    var primaryModeIsPaleo = true {
        didSet { updateKeyboardMode() }
    }
    
    var blurEffectView: UIVisualEffectView?
    private let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    /// Defines the keyboard layout rows.
    var layout: [[(paleo: String, modern: String, isBackspace: Bool)]] = [
        [("𐤒", "ק", false), ("𐤓", "ר", false), ("𐤀", "א", false), ("𐤈", "ט", false),
         ("𐤅", "ו", false), ("𐤍", "ן", false), ("𐤌", "ם", false), ("𐤐", "פ", false),
         ("⌫", "", true)],
        [("𐤔", "ש", false), ("𐤃", "ד", false), ("𐤂", "ג", false), ("𐤊", "כ", false),
         ("𐤏", "ע", false), ("𐤉", "י", false), ("𐤇", "ח", false), ("𐤋", "ל", false),
         ("𐤊", "ך", false)],
        [("𐤆", "ז", false), ("𐤎", "ס", false), ("𐤁", "ב", false), ("𐤄", "ה", false),
         ("𐤍", "נ", false), ("𐤌", "מ", false), ("𐤑", "צ", false), ("𐤕", "ת", false),
         ("𐤑", "ץ", false)]
    ]
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        updateBackgroundColor()
        setupKeyboard()
        UserDefaults(suiteName: "group.com.d7mtg.paleopro")?.set(true, forKey: "keyboardHasLaunched")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateBackgroundColor()
    }
    
    // MARK: UI Setup Methods
    func updateBackgroundColor() {
        blurEffectView?.removeFromSuperview()
        blurEffectView = nil
        
        if traitCollection.userInterfaceStyle == .dark {
            view.backgroundColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 0.0)
            let blurEffect = UIBlurEffect(style: .regular)
            blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView!.frame = view.bounds
            blurEffectView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.insertSubview(blurEffectView!, at: 0)
        } else {
            view.backgroundColor = UIColor(hex: "D0D5DC")
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
        
        // Add character key rows.
        for row in layout {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 4
            rowStack.distribution = .fillEqually
            rowStack.semanticContentAttribute = .forceLeftToRight  // Flipped for backspace on left
            
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
        
        // Bottom row with swap, space, and return buttons.
        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.spacing = 4
        
        let swapModeButton = specialButton("", action: #selector(toggleMode), isSpecial: true)
        let swapImage = UIImage(systemName: "arrow.up.arrow.down.circle")
        swapModeButton.setImage(swapImage, for: .normal)
        swapModeButton.tintColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
        
        let spaceButton = specialButton("Space", action: #selector(spaceTapped), isSpecial: false)
        
        let returnButton = specialButton("", action: #selector(returnTapped), isSpecial: true)
        let returnImage = UIImage(systemName: "return")?.withHorizontallyFlippedOrientation()
        returnButton.setImage(returnImage, for: .normal)
        returnButton.tintColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
        
        bottomRow.addArrangedSubview(swapModeButton)
        bottomRow.addArrangedSubview(spaceButton)
        bottomRow.addArrangedSubview(returnButton)
        
        // Set width constraints for a balanced layout.
        returnButton.widthAnchor.constraint(equalTo: swapModeButton.widthAnchor).isActive = true
        spaceButton.widthAnchor.constraint(equalTo: bottomRow.widthAnchor, multiplier: 0.6).isActive = true
        
        stack.addArrangedSubview(bottomRow)
    }
    
    // MARK: - Update Keyboard Mode
    func updateKeyboardMode() {
        for view in self.view.subviewsRecursive() {
            if let key = view as? KeyButton {
                key.primaryModeIsPaleo = primaryModeIsPaleo
            }
        }
    }
    
    // MARK: Button Factory Method
    func specialButton(_ title: String, action: Selector, isSpecial: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 4.6
        
        if traitCollection.userInterfaceStyle == .dark {
            button.backgroundColor = isSpecial ? UIColor(hex: "3d3d3d") : UIColor(hex: "757575")
            button.setTitleColor(.white, for: .normal)
            addOverlay(to: button)
        } else {
            button.backgroundColor = isSpecial ? UIColor(hex: "ABB4C1") : .white
            button.setTitleColor(.black, for: .normal)
        }
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.35
        button.layer.shadowRadius = 0
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        
        button.registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { (button: UIButton, previousTraitCollection: UITraitCollection) in
            if button.traitCollection.userInterfaceStyle == .dark {
                button.backgroundColor = isSpecial ? UIColor(hex: "555555") : UIColor(hex: "959595")
                button.setTitleColor(.white, for: .normal)
                button.tintColor = .white
                self.addOverlay(to: button)
            } else {
                button.backgroundColor = isSpecial ? UIColor(hex: "ABB4C1") : .white
                button.setTitleColor(.black, for: .normal)
                button.tintColor = .black
                button.layer.sublayers?.removeAll { $0.name == "blendOverlay" }
            }
        })
        return button
    }
    
    func addOverlay(to button: UIButton) {
        if let sublayer = button.layer.sublayers?.first(where: { $0.name == "blendOverlay" }) {
            sublayer.removeFromSuperlayer()
        }
        let overlayLayer = CALayer()
        overlayLayer.name = "blendOverlay"
        overlayLayer.frame = button.bounds
        overlayLayer.backgroundColor = UIColor(white: 1.0, alpha: 0.15).cgColor
        button.layer.insertSublayer(overlayLayer, at: 0)
    }
    
    // MARK: Keyboard Actions
    @objc func tapKey(_ sender: KeyButton) {
        textDocumentProxy.insertText(sender.inputValue ?? "")
        lightImpactFeedbackGenerator.impactOccurred()
    }
    
    @objc func spaceTapped() {
        textDocumentProxy.insertText(" ")
        lightImpactFeedbackGenerator.impactOccurred()
    }
    
    @objc func returnTapped() {
        textDocumentProxy.insertText("\n")
        lightImpactFeedbackGenerator.impactOccurred()
    }
    
    @objc func toggleMode() {
        primaryModeIsPaleo.toggle()
        mediumImpactFeedbackGenerator.impactOccurred()
    }
    
    @objc func backspaceTapped() {
        textDocumentProxy.deleteBackward()
        lightImpactFeedbackGenerator.impactOccurred()
    }
    
    @objc func toggleHints() {
        showHints.toggle()
        for view in self.view.subviewsRecursive() {
            if let key = view as? KeyButton {
                key.showsHint = showHints
            }
        }
        mediumImpactFeedbackGenerator.impactOccurred()
    }
    
    // MARK: Text Input Mode
    override var textInputMode: UITextInputMode? {
        return UITextInputMode.activeInputModes.first { $0.primaryLanguage == "he" }
    }
}
