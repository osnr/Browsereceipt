//
//  ViewController.swift
//  Browsereceipt
//
//  Created by Omar Rizwan on 10/26/23.
//

import Cocoa
import WebKit
import PythonKit

class ViewController: NSViewController, WKNavigationDelegate, WKScriptMessageHandler {
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the Python
        let sys = Python.import("sys")
        let os = Python.import("os")
        let io = Python.import("io")
        sys.path.append("/Users/osnr/aux/Cat-Printer")
        os.chdir("/Users/osnr/aux/Cat-Printer")
        let printer = Python.import("printer")
        let driver = printer.PrinterDriver()
        driver.dump = true
        // MX05-F57F
        driver.connect(address: "7F4F5A11-4A6F-EB58-0089-56B126124A02")
        
        driver.print(io.BytesIO(PythonBytes("Hello\n\n\n\n".utf8)), mode: "text")
        
        // Set up the browser
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
                
                // driver.print(io.BytesIO(PythonBytes(pbmData)), mode: "pbm")
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
           // FIXME: Write a slice of the page snapshot bitmap to disk, then dispatch it to the Python
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
