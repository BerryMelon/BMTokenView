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
    var array = ["Text","Another text", "Something", "Some long text with some more long text", "A", "B", "C", "A even more longer text with even more longer text with more text at the end", "ABC", "A text\nWith return marks \\n\nWhich will have\nMultiple Lines"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        self.tokenView.addTokenViewData()
    }
    
    func tokenViewChangedText(tokenView: BMTokenView, text: String) {
        print("TokenView Changed Text: \(text)")
    }
    
    func tokenViewWillDeleteToken(tokenView: BMTokenView, index: Int) {
        self.array.remove(at: index)
    }
}

extension ViewController: BMTokenViewDatasource {
    func tokenViewNumberOfItems() -> Int {
        return array.count
    }
    func tokenViewDataForItem(atIndex index:Int) -> TokenViewData {
        let text = array[index]
        return text
    }
    func canEditTokenView() -> Bool {
        return false
    }
}
