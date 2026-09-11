import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let windowChannel = FlutterMethodChannel(
      name: "squiggle/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    windowChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setTitle",
            let arguments = call.arguments as? [String: Any],
            let title = arguments["title"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }

      self?.title = title
      result(nil)
    }

    super.awakeFromNib()
  }
}
