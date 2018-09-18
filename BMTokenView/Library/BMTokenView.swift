//
//  BMTokenView.swift
//  BMTokenView
//
//  Created by Doheny Yoon on 9/17/18.
//  Copyright © 2018 Doheny Yoon. All rights reserved.
//

import Foundation
import UIKit

struct BMTokenViewSettings {
    var margins:UIEdgeInsets = UIEdgeInsetsMake(0,0,0,0)
    var textMargin:CGFloat = 16.0
    var tokenHeight:CGFloat = 30.0
    var tokenXMargin:CGFloat = 4.0
    var tokenYMargin:CGFloat = 4.0
    var isRound:Bool = true
    var font:UIFont = UIFont.systemFont(ofSize: 12.0)
    var tintColor:UIColor = UIColor.black
    var textColor:UIColor = UIColor.white
    var textColorSelected:UIColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)
    var tokenViewBackgroundColor:UIColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)
    var tokenViewBackgroundColorSelected:UIColor = UIColor.white
    var firstResponderAtStart:Bool = true
    var canSelectTokens:Bool = true
}

typealias TokenViewData = String

@objc protocol BMTokenViewDatasource {
    func tokenViewNumberOfItems(tokenView:BMTokenView) -> Int
    func tokenViewDataForItem(tokenView:BMTokenView,atIndex index:Int) -> TokenViewData
    func canEditTokenView(tokenView:BMTokenView) -> Bool
}

@objc protocol BMTokenViewDelegate {
    @objc optional func tokenViewHeightUpdated(tokenView:BMTokenView, height:CGFloat) -> ()
    @objc optional func tokenViewDidDrawView(tokenView:BMTokenView, view:BMToken) -> () // for more customizing
    
    @objc optional func tokenViewDidBeganEditing(tokenView:BMTokenView, text:String) -> ()
    @objc optional func tokenViewShouldReturn(tokenView:BMTokenView, text:String) -> ()
    @objc optional func tokenViewChangedText(tokenView:BMTokenView, text:String) -> ()
    
    @objc optional func tokenViewWillDeleteToken(tokenView:BMTokenView, index:Int) -> ()
    @objc optional func tokenViewDidTapToken(tokenView:BMTokenView, index:Int) -> ()
}

@objc class BMTokenView:UIView {
    public var settings = BMTokenViewSettings()
    @IBOutlet public weak var datasource:BMTokenViewDatasource? = nil
    @IBOutlet public weak var delegate:BMTokenViewDelegate? = nil
    @IBOutlet public var heightConstraint:NSLayoutConstraint? = nil
    
    var textField:TokenTextField? = nil
    var isEditing:Bool = false {
        willSet (newVal) {
            if !newVal {
                for tokens in self.tokenViews {
                    tokens.toggleSelected(selected: false, animated: false)
                }
            }
        }
    }
    
    var tokenViews = [BMToken]()
    private var initialHeight:CGFloat = 0.0
    private var marginView:UIView? = nil
    
    private var minimumTextFieldWidth:CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.reloadData()
    }
    
    private func removeAllSubviews() {
        guard let marginView = self.marginView else { return }
        for view in marginView.subviews {
            if view is UITextField { // Do not remove textfield
                continue
            }
            view.removeFromSuperview()
        }
    }
    
    public func makeFirstResponder() {
        self.textField?.becomeFirstResponder()
    }
    
    public func addedTokenViewData() {
        self.textField?.text = ""
        self.reloadData()
    }
    
    public func reloadData() {
        self.removeAllSubviews()
        self.tokenViews.removeAll()
        
        if self.initialHeight > 0 {
            self.heightConstraint?.constant = initialHeight
            if self.heightConstraint == nil {
                self.frame = CGRect(origin: self.frame.origin, size: CGSize(width: self.frame.size.width, height: initialHeight))
            }
        }
        else {
            self.initialHeight = self.heightConstraint?.constant ?? self.frame.size.height
        }
        
        let canEdit = self.datasource?.canEditTokenView(tokenView:self) ?? false
        let numberOfItems = self.datasource?.tokenViewNumberOfItems(tokenView:self) ?? 0
        let lineHeight:CGFloat = self.initialHeight - (settings.margins.top + settings.margins.bottom)
        let minTokenHeight:CGFloat = settings.tokenHeight > lineHeight ? lineHeight : settings.tokenHeight
        let lineWidth:CGFloat = self.frame.size.width - (settings.margins.left + settings.margins.right)
        let textHeight:CGFloat = "O".heightWithConstrainedWidth(width: lineWidth, font: settings.font) // Get the texts height with an obvious one liner
        
        if self.marginView == nil { // if nil initialize for the first time
            self.marginView = UIView(frame: CGRect(x: settings.margins.left, y: settings.margins.top, width: lineWidth, height: lineHeight))
            self.addSubview(self.marginView!)
        }
        else { // else assign only the frame
            self.marginView?.frame = CGRect(x: settings.margins.left, y: settings.margins.top, width: lineWidth, height: lineHeight)
        }
        let marginView = self.marginView!
        
        // Draw Tokens
        var x:CGFloat = 0.0
        var y:CGFloat = (lineHeight - minTokenHeight) / 2
        var prevTokenHeight:CGFloat = settings.tokenHeight
        for i in 0..<numberOfItems {
            let title = self.datasource?.tokenViewDataForItem(tokenView:self, atIndex: i) ?? ""
            let numberOfLines:Int = Int(title.heightWithConstrainedWidth(width: lineWidth, font: settings.font) / textHeight)
            let tokenWidth = numberOfLines > 1 ? lineWidth : title.widthOfString(usingFont: self.settings.font) + (settings.textMargin * 2)
            let tokenHeight = numberOfLines > 1 ? settings.tokenHeight * CGFloat(numberOfLines) : settings.tokenHeight
            
            if x + tokenWidth >= lineWidth {
                // Needs next line
                x = 0
                y += prevTokenHeight + settings.tokenYMargin
                self.heightConstraint?.constant += tokenHeight + settings.tokenYMargin
                self.delegate?.tokenViewHeightUpdated?(tokenView: self, height: initialHeight + tokenHeight + settings.tokenYMargin)
                let frame = CGRect(origin: marginView.frame.origin, size: CGSize(width: marginView.frame.width, height: marginView.frame.height + tokenHeight + settings.tokenYMargin))
                marginView.frame = frame
            }
            
            let rect = CGRect(x: x, y: y, width: tokenWidth, height: tokenHeight)
            let tokenView = BMToken(frame: rect, title: title, setting: settings, delegate:self)
            tokenView.tag = i
            self.tokenViews.append(tokenView)
            self.delegate?.tokenViewDidDrawView?(tokenView:self, view: tokenView)
            marginView.addSubview(tokenView)
            x += tokenWidth + settings.tokenXMargin
            prevTokenHeight = tokenHeight
        }
        
        if canEdit {
            //Fetch last position. If last position has lesser space than the minimum textfield width, add a new line
            if x + (lineWidth/3) > lineWidth {
                // need to add new line
                let tokenHeight = settings.tokenHeight
                x = 0
                y += prevTokenHeight + settings.tokenYMargin
                self.heightConstraint?.constant += tokenHeight + settings.tokenYMargin
                self.delegate?.tokenViewHeightUpdated?(tokenView: self, height: initialHeight + tokenHeight + settings.tokenYMargin)
                let frame = CGRect(origin: marginView.frame.origin, size: CGSize(width: marginView.frame.width, height: marginView.frame.height + tokenHeight + settings.tokenYMargin))
                marginView.frame = frame
            }
            let rect = CGRect(x: x, y: y, width: lineWidth - x, height: settings.tokenHeight)
            
            if self.textField != nil {
                self.textField?.frame = rect
            }
            else {
                self.textField = TokenTextField(frame: rect)
                self.textField?.delegate = self
                self.textField?.myDelegate = self
                self.textField?.font = settings.font
                self.textField?.tintColor = settings.tintColor
                marginView.addSubview(self.textField!)
            }
            
            if settings.firstResponderAtStart {
                self.textField?.becomeFirstResponder()
            }
        }
        else {
            self.textField = nil
        }
        
    }
    
    func hasSeletectedTokenView() -> Int {
        for tokenView in self.tokenViews {
            if tokenView.isSelected {
                
                if self.datasource?.canEditTokenView(tokenView: self) ?? true {
                    self.textField?.becomeFirstResponder()
                }
                
                return tokenView.tag
            }
        }
        
        return -1
    }
}

extension BMTokenView: UITextFieldDelegate, TokenTextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.tokenViewDidBeganEditing?(tokenView: self, text: textField.text ?? "")
        self.isEditing = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.delegate?.tokenViewShouldReturn?(tokenView: self, text: textField.text ?? "")
        self.textField?.resignFirstResponder()
        self.isEditing = false
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text, let textRange = Range(range, in: text) else {
            return true
        }
        
        let selectedIndex = self.hasSeletectedTokenView()
        if ((string.isBackspace) && selectedIndex >= 0) { // Had Text and tap delete when selected.
            self.delegate?.tokenViewWillDeleteToken?(tokenView: self, index: selectedIndex)
            self.reloadData()
            return false
        }
        
        let updatedText = text.replacingCharacters(in: textRange, with: string)
        self.delegate?.tokenViewChangedText?(tokenView: self, text: updatedText)
        
        return true
    }
    
    func textFieldDidDelete() {
        guard let text = textField?.text else { return }
        if text == "" {
            // Tapped delete when selected
            let selectedIndex = self.hasSeletectedTokenView()
            if selectedIndex >= 0 {
                //delete this
                self.delegate?.tokenViewWillDeleteToken?(tokenView: self, index: selectedIndex)
                self.reloadData()
            }
            else {
                //select the last tokenView
                if let token = self.tokenViews.last {
                    token.toggleSelected(selected: true, animated: true)
                }
            }
        }
    }
}

extension BMTokenView: BMTokenDelegate {
    func didTapToken(atIndex index:Int, selected:Bool) {
        let canEdit = self.datasource?.canEditTokenView(tokenView: self) ?? true
        
        if selected {
            self.delegate?.tokenViewDidTapToken?(tokenView: self, index: index)
            if canEdit {
                self.textField?.becomeFirstResponder()
            }
        }
        
        for token in self.tokenViews {
            if token.tag != index && token.isSelected == true {
                token.toggleSelected(selected: false, animated: false)
            }
        }
    }
}

protocol BMTokenDelegate: class {
    func didTapToken(atIndex index:Int, selected:Bool)
}
class BMToken:UIView {
    
    var titleLabel:UILabel!
    let setting:BMTokenViewSettings
    let title:String
    
    public var isSelected:Bool = false
    
    weak var delegate:BMTokenDelegate? = nil
    
    init(frame: CGRect, title:String, setting:BMTokenViewSettings, delegate:BMTokenDelegate?) {
        self.setting = setting
        self.title = title
        self.delegate = delegate
        
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.setting = BMTokenViewSettings()
        self.title = ""
        
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        self.titleLabel = UILabel(frame: CGRect(x: setting.textMargin, y: 0, width: frame.size.width - (setting.textMargin * 2), height: frame.size.height))
        self.titleLabel.font = setting.font
        self.titleLabel.text = title
        self.titleLabel.textColor = setting.textColor
        self.titleLabel.numberOfLines = 0
        
        self.backgroundColor = setting.tokenViewBackgroundColor
        if setting.isRound {
            self.layer.cornerRadius = setting.tokenHeight / 2
        }
        
        self.addSubview(titleLabel)
        
        if setting.canSelectTokens {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapToken))
            self.addGestureRecognizer(tapGesture)
        }
    }
    
    @objc func didTapToken() {
        self.isSelected = !self.isSelected
        self.delegate?.didTapToken(atIndex: self.tag, selected: self.isSelected)
        self.toggleSelected(selected: self.isSelected, animated: true)
    }
    
    func toggleSelected(selected:Bool, animated:Bool) {
        self.isSelected = selected
        let backgroundColor = selected ? setting.tokenViewBackgroundColorSelected : setting.tokenViewBackgroundColor
        let textColor = selected ? setting.textColorSelected : setting.textColor
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.backgroundColor = backgroundColor
                self.titleLabel.textColor = textColor
            })
        }
        else {
            self.backgroundColor = backgroundColor
            self.titleLabel.textColor = textColor
        }
    }
}

protocol TokenTextFieldDelegate {
    func textFieldDidDelete()
}

class TokenTextField: UITextField {
    
    var myDelegate: TokenTextFieldDelegate?
    
    override func deleteBackward() {
        myDelegate?.textFieldDidDelete()
        super.deleteBackward()
    }
    
}

fileprivate extension String {
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let size = self.size(withAttributes: [NSAttributedStringKey.font:font])
        return size.width
    }
    
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedStringKey.font: font], context: nil)
        return boundingBox.height
    }
    
    var isBackspace: Bool {
        let char = self.cString(using: String.Encoding.utf8)!
        return strcmp(char, "\\b") == -92
    }
}
