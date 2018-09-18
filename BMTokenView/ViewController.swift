//
//  ViewController.swift
//  BMTokenView
//
//  Created by Doheny Yoon on 9/17/18.
//  Copyright © 2018 Doheny Yoon. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tokenView: BMTokenView!
    var array = ["Text","Another text", "Something", "Some long text with some more long text", "A", "B", "C", "ABC", "Tokens","MoreTokens"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tokenView.settings.margins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        self.tokenView.settings.tokenViewBackgroundColorSelected = UIColor.red
        self.tokenView.reloadData()
        self.tokenView.makeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: BMTokenViewDelegate {
    func tokenViewDidBeganEditing(tokenView: BMTokenView, text: String) {
        print("TokenView Did Began Editing: \(text)")
    }
    
    func tokenViewShouldReturn(tokenView: BMTokenView, text: String) {
        print("TokenView Should Return: \(text)")
        self.array.append(text)
        self.tokenView.addedTokenViewData()
    }
    
    func tokenViewChangedText(tokenView: BMTokenView, text: String) {
        print("TokenView Changed Text: \(text)")
    }
    
    func tokenViewWillDeleteToken(tokenView: BMTokenView, index: Int) {
        self.array.remove(at: index)
    }
}

extension ViewController: BMTokenViewDatasource {
    func tokenViewNumberOfItems(tokenView:BMTokenView) -> Int {
        return array.count
    }
    func tokenViewDataForItem(tokenView:BMTokenView, atIndex index:Int) -> TokenViewData {
        let text = array[index]
        return text
    }
    func canEditTokenView(tokenView:BMTokenView) -> Bool {
        return true
    }
}
