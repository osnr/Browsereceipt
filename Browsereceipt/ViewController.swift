//
//  ViewController.swift
//  Browsereceipt
//
//  Created by Omar Rizwan on 10/26/23.
//

import Cocoa
import WebKit


class ViewController: NSViewController, WKNavigationDelegate, WKScriptMessageHandler {
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.webView.pageZoom = 0.5;
        self.webView.load(URLRequest(url: URL(string: "https://en.m.wikipedia.org/wiki/Receipt")!))
        self.webView.navigationDelegate = self
    }
    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        print("Finished nav")
        
        // TODO: Report entire PDF of rendered page to us
        webView.takeSnapshot(with: nil) { imOpt, err in
            if let im = imOpt {
                try? im.tiffRepresentation?.write(to: URL(filePath: "/Users/osnr/blup.tiff"))
            }
        }
        
        webView.configuration.userContentController.add(self, name:"didScroll")
        webView.evaluateJavaScript("""
window.addEventListener("scroll", (event) => {
   window.webkit.messageHandlers.didScroll.postMessage(window.scrollY);
});

""")
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
       if message.name == "didScroll" {
           print(message.body)
       }
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
