//
//  ViewController.swift
//  Browsereceipt
//
//  Created by Omar Rizwan on 10/26/23.
//

import Cocoa
import WebKit


class ViewController: NSViewController {
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.webView.pageZoom = 0.5;
        self.webView.load(URLRequest(url: URL(string: "https://en.m.wikipedia.org/wiki/Receipt")!))
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.isOpaque = false
        view.window?.backgroundColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.001)
    }
}

class CatPrinterImageView: NSImageView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}
