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
    
    var io: PythonObject!
    var driver: PythonObject!
    var tiffUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the Python
        let sys = Python.import("sys")
        let os = Python.import("os")
        self.io = Python.import("io")
        sys.path.append("/Users/osnr/aux/Cat-Printer")
        os.chdir("/Users/osnr/aux/Cat-Printer")
        let printer = Python.import("printer")
        driver = printer.PrinterDriver()
        driver.dump = true
        // MX05-F57F
        driver.connect(address: "7F4F5A11-4A6F-EB58-0089-56B126124A02")
        
        // Set up the browser
        self.webView.pageZoom = 0.5;
        self.webView.load(URLRequest(url: URL(string: "https://en.m.wikipedia.org/wiki/Receipt")!))
        self.webView.navigationDelegate = self
    }
    var lastToY: Int = 0
    func printPage(fromY: Int, toY: Int) {
        guard let tiffUrl = self.tiffUrl else { return }
        var startY = fromY
        if lastToY > startY { startY = lastToY }
    
        lastToY = toY
        if startY > toY { return }

        let task = Process()
        
        let directory = NSTemporaryDirectory()
        let fileName = NSUUID().uuidString + ".pbm"
        guard let tempPbm = NSURL.fileURL(withPathComponents: [directory, fileName]) else { return }
        
        task.launchPath = "/opt/homebrew/bin/convert"
        task.arguments = [tiffUrl.path(),
                          "-crop", "x\(toY - startY)+0+\(startY)",
                          "-resize", "384x",
                          tempPbm.path()]
        task.launch()
        task.waitUntilExit()
        
        print("PRINTPAGE \(startY) \(toY) \(tempPbm.path())")
        
        guard let pbmData = NSData(contentsOf: tempPbm) else { return }
        self.driver.print(io.BytesIO(PythonBytes(pbmData)), mode: "pbm")
            // driver.print(io.BytesIO(PythonBytes(pbmData)), mode: "pbm")
        
    }
    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        print("Finished nav")
        
        webView.takeSnapshot(with: nil) { im, err in
            guard let tiff = im?.tiffRepresentation else { return }
            let directory = NSTemporaryDirectory()
            let fileName = NSUUID().uuidString
            self.tiffUrl = NSURL.fileURL(withPathComponents: [directory, fileName])
            if let tiffUrl = self.tiffUrl {
                try? tiff.write(to: tiffUrl)
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
           guard let body = message.body as? NSNumber else { return }
           let toY = Int(truncating: body)
           printPage(fromY: 0, toY: toY)
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
