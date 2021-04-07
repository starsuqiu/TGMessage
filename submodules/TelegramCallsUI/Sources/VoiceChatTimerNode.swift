import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import TelegramStringFormatting

private let purple = UIColor(rgb: 0x3252ef)
private let pink = UIColor(rgb: 0xef436c)

final class VoiceChatTimerNode: ASDisplayNode {
    private let strings: PresentationStrings
    private let dateTimeFormat: PresentationDateTimeFormat
    
    private let titleNode: ImmediateTextNode
    private let subtitleNode: ImmediateTextNode
    
    private let timerNode: ImmediateTextNode
    
    private let foregroundView = UIView()
    private let foregroundGradientLayer = CAGradientLayer()
    private let maskView = UIView()
    
    private var validLayout: CGSize?
    
    private var updateTimer: SwiftSignalKit.Timer?
    
    init(strings: PresentationStrings, dateTimeFormat: PresentationDateTimeFormat) {
        self.strings = strings
        self.dateTimeFormat = dateTimeFormat
        
        self.titleNode = ImmediateTextNode()
        self.subtitleNode = ImmediateTextNode()
        
        self.timerNode = ImmediateTextNode()
        
        super.init()
        
        self.allowsGroupOpacity = true
        
        self.foregroundGradientLayer.type = .radial
        self.foregroundGradientLayer.colors = [pink.cgColor, purple.cgColor, purple.cgColor]
        self.foregroundGradientLayer.locations = [0.0, 0.85, 1.0]
        self.foregroundGradientLayer.startPoint = CGPoint(x: 1.0, y: 0.0)
        self.foregroundGradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        
        self.foregroundView.mask = self.maskView
        self.foregroundView.layer.addSublayer(self.foregroundGradientLayer)
        
        self.view.addSubview(self.foregroundView)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.subtitleNode)
        
        self.maskView.addSubnode(self.timerNode)
    }
    
    deinit {
        self.updateTimer?.invalidate()
    }
    
    func animateIn() {
        self.foregroundView.layer.animateSpring(from: 0.01 as NSNumber, to: 1.0 as NSNumber, keyPath: "transform.scale", duration: 0.42, damping: 104.0)
    }
    
    private func setupGradientAnimations() {
        if let _ = self.foregroundGradientLayer.animation(forKey: "movement") {
        } else {
            let previousValue = self.foregroundGradientLayer.startPoint
            let newValue = CGPoint(x: CGFloat.random(in: 0.65 ..< 0.85), y: CGFloat.random(in: 0.1 ..< 0.45))
            self.foregroundGradientLayer.startPoint = newValue
            
            CATransaction.begin()
            
            let animation = CABasicAnimation(keyPath: "startPoint")
            animation.duration = Double.random(in: 0.8 ..< 1.4)
            animation.fromValue = previousValue
            animation.toValue = newValue
            
            CATransaction.setCompletionBlock { [weak self] in
//                if let isCurrentlyInHierarchy = self?.isCurrentlyInHierarchy, isCurrentlyInHierarchy {
                    self?.setupGradientAnimations()
//                }
            }
            
            self.foregroundGradientLayer.add(animation, forKey: "movement")
            CATransaction.commit()
        }
    }
    
    func update(size: CGSize, scheduleTime: Int32?, transition: ContainedViewLayoutTransition) {
        if self.validLayout == nil {
            self.setupGradientAnimations()
        }
        self.validLayout = size
                
        guard let scheduleTime = scheduleTime else {
            return
        }
        
        self.foregroundView.frame = CGRect(origin: CGPoint(), size: size)
        self.foregroundGradientLayer.frame = self.foregroundView.bounds
        self.maskView.frame = self.foregroundView.bounds
        
        let currentTime = Int32(CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970)
        let elapsedTime = scheduleTime - currentTime
        let timerText: String
        if elapsedTime >= 86400 {
            timerText = timeIntervalString(strings: self.strings, value: elapsedTime)
        } else if elapsedTime < 0 {
            timerText = "\(textForTimeout(value: abs(elapsedTime)))"
        } else {
            timerText = textForTimeout(value: elapsedTime)
        }
        
        if self.updateTimer == nil {
            let timer = SwiftSignalKit.Timer(timeout: 0.5, repeat: true, completion: { [weak self] in
                if let strongSelf = self, let size = strongSelf.validLayout {
                    strongSelf.update(size: size, scheduleTime: scheduleTime, transition: .immediate)
                }
            }, queue: Queue.mainQueue())
            self.updateTimer = timer
            timer.start()
        }
        
        let subtitle = humanReadableStringForTimestamp(strings: self.strings, dateTimeFormat: self.dateTimeFormat, timestamp: scheduleTime)
        
        self.titleNode.attributedText = NSAttributedString(string: elapsedTime < 0 ?  self.strings.VoiceChat_LateBy :  self.strings.VoiceChat_StartsIn, font: Font.with(size: 23.0, design: .round, weight: .semibold, traits: []), textColor: .white)
        let titleSize = self.titleNode.updateLayout(size)
        self.titleNode.frame = CGRect(x: floor((size.width - titleSize.width) / 2.0), y: 48.0, width: titleSize.width, height: titleSize.height)
        
        self.timerNode.attributedText = NSAttributedString(string: timerText, font: Font.with(size: 68.0, design: .round, weight: .semibold, traits: [.monospacedNumbers]), textColor: .white)
        
        let timerSize = self.timerNode.updateLayout(size)
        self.timerNode.frame = CGRect(x: floor((size.width - timerSize.width) / 2.0), y: 80.0, width: timerSize.width, height: timerSize.height)
        
        self.subtitleNode.attributedText = NSAttributedString(string: subtitle, font: Font.with(size: 21.0, design: .round, weight: .semibold, traits: []), textColor: .white)
        let subtitleSize = self.subtitleNode.updateLayout(size)
        self.subtitleNode.frame = CGRect(x: floor((size.width - subtitleSize.width) / 2.0), y: 164.0, width: timerSize.width, height: subtitleSize.height)
        
        self.foregroundView.frame = CGRect(origin: CGPoint(), size: size)
    }
}