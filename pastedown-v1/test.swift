//
//  test.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/7/10.
//

import SwiftUI

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = Bundle.main.url(forResource: "peterpan", withExtension: "rtf")!
        if let content = try? NSAttributedString(url: url, options: [.documentType : NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
            textView.attributedText = content
        }
    }
}

