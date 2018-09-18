# BMTokenView
Token Style UI with UITableView'ish methods

<img src="/BMTokenView/Screenshots/01.png" alt="drawing" width="300"/> <img src="/BMTokenView/Screenshots/02.png" alt="drawing" width="300"/>

BMTokenView let's you create a Token managing view using delegates and datasources, similar to UITableview.

## Installation

You can download/clone the sample app and copy BMTokenView.swift to your project, or simple use pod
```
pod 'BMTokenView'
```

## Setup

There are two ways to implement the token view. 

### 1. Manually
  Simply create a BMTokenView as you would create a UIView. Don't forget to setup delegate & datasource.
  Whenever the height of the BMTokenView changes (when a new line is needed to create a new token), 
  ```
  func tokenViewHeightUpdated(tokenView:BMTokenView, height:CGFloat) -> ()
  ```
  will be called so you can handle height changes.
  
### 2. AutoLayout
  BMTokenView supports autolayout. Just drag an UIView to your viewcontroller and name it BMTokenView. Set it up <b>with an initial height constraint.</b> Connect the heightConstraint to
  ```
  @IBOutlet public var heightConstraint:NSLayoutConstraint
  ```
  once connected, BMTokenView's height will be automatically controlled through the constraint.

## Usage

  Similar to an UITableview, BMTokenView doesn't need to know about the data for display. All the data is managed through the datasource, so you can keep the data in an array as you would on a tableview.
  
  There are three datasource callbacks.
  ```
  func tokenViewNumberOfItems(tokenView:BMTokenView) -> Int // 1
  func tokenViewDataForItem(tokenView:BMTokenView,atIndex index:Int) -> TokenViewData // 2
  func canEditTokenView(tokenView:BMTokenView) -> Bool // 3
  ```
  1) Same as numberOfRowsInTableview. 
  2) actual data that it needs to show for a single token. TokenViewData is just a simple typealias for String.
  3) if false, the tokenView is readonly, and the data cannot be added or removed unless reloading the data itself.
  
  
  BMTokenView has 7 optional delegate callbacks which are self explainable. 
  ```
  @objc protocol BMTokenViewDelegate {
    @objc optional func tokenViewHeightUpdated(tokenView:BMTokenView, height:CGFloat) -> ()
    @objc optional func tokenViewDidDrawView(tokenView:BMTokenView, view:BMToken) -> () // for more customizing
    
    @objc optional func tokenViewDidBeganEditing(tokenView:BMTokenView, text:String) -> ()
    @objc optional func tokenViewShouldReturn(tokenView:BMTokenView, text:String) -> ()
    @objc optional func tokenViewChangedText(tokenView:BMTokenView, text:String) -> ()
    
    @objc optional func tokenViewWillDeleteToken(tokenView:BMTokenView, index:Int) -> () // 1
    @objc optional func tokenViewDidTapToken(tokenView:BMTokenView, index:Int) -> () // 2
}
  ```
  <b>"1"</b> will be called when the user taps a existing token and presses the delete key on the keyboard. It will not automatacally remove the data, since it's managed through the delegate. You will have to implement your own removing logic here and BMTokenView will automatically reload the data.
  <b>"2"</b> works as 1, you will have to add the data in this method. BMTokenView will automatically reload the data.
  
## Customization

BMTokenView has a settings value which has bunch of options so that you can manually design your own tokenview. All of the options are self explanatory. 
```
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
```
- The most important setting will be 'margins', when not defined tokens will be drawn at the very begining of the BMTokenView. 
- 'textMargin' defines the side margins between the text and the token block.
- 'tokenXMargin' and 'tokenYMargin' defines the distance between two token blocks.
