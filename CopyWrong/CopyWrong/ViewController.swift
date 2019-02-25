//
//  ViewController.swift
//  CopyWrong
//
//  Created by Arnav Kaushik on 2/24/19.
//  Copyright © 2019 11 Studios. All rights reserved.
//

import Cocoa
import CircularProgressMac
import AVFoundation
import AVKit

class ViewController: NSViewController {
	
	var circleProgress: CircularProgress!
	var originalPath = ""
	var originalFrames = [NSImage]()
	var originalGenerator: AVAssetImageGenerator!
	var testPath = ""
	var testFrames = [NSImage]()
	var testGenerator: AVAssetImageGenerator!
	var originalProcessing = false
	var testProcessing = false
	@IBOutlet weak var originalDropView: DropView!
	@IBOutlet weak var copyDropView: DropView!
	@IBOutlet weak var progressBar: NSProgressIndicator!
	var percentCorrect = 0
	var percentOverall = 0
	var percent = 0.0
	@IBOutlet weak var originalProgress: NSProgressIndicator!
	@IBOutlet weak var testProgress: NSProgressIndicator!
	@IBOutlet weak var originalImageView: NSImageView!
	@IBOutlet weak var copyImageView: NSImageView!
	
	
	override func viewWillAppear() {
		originalDropView.viewTag = 1
		copyDropView.viewTag = 2
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
		circleProgress = CircularProgress(frame: CGRect(x: self.view.frame.width/2-50, y: self.view.frame.height/2-50, width: 100, height: 100))
		
		circleProgress.color = NSColor.windowFrameTextColor
		self.view.addSubview(circleProgress)
		circleProgress.isHidden = true
		
		NotificationCenter.default.addObserver(self, selector: #selector(fileAdded), name: NSNotification.Name("fileAdded") , object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(fileAdded2), name: NSNotification.Name("fileAdded2") , object: nil)
		self.originalProgress.isHidden = true
		self.testProgress.isHidden = true
		
	}
	
	@objc func progressDone(percent: Double) {
		let view = BGView(frame: self.view.frame)
		let progress = Progress(totalUnitCount: Int64(percentOverall))
		circleProgress.progressInstance = progress
		circleProgress.showCheckmarkAtHundredPercent = false
		for i in 0...percentCorrect {
			circleProgress.progressInstance?.completedUnitCount = (circleProgress.progressInstance?.completedUnitCount)! + Int64(i)
		}
		self.view.addSubview(view, positioned: .below, relativeTo: circleProgress)
		circleProgress.isHidden = false
		
		
	}
	
	@objc func fileAdded(_ notificaton: NSNotification) {
		self.originalProgress.isHidden = false
		originalProgress.isIndeterminate = true
		originalProgress.startAnimation(nil)
		progressBar.doubleValue = 0
		DispatchQueue.global(qos: .background).async {
			self.originalProcessing = true
			self.originalPath = notificaton.userInfo!["fileName"]! as! String
			let asset = AVAsset(url: URL(fileURLWithPath: self.originalPath))
			let duration = CMTimeGetSeconds(asset.duration)
			self.originalGenerator = AVAssetImageGenerator(asset: asset)
			self.originalGenerator.appliesPreferredTrackTransform = true
			self.originalFrames = []
			for index:Int in 0 ..< Int(duration) {
				self.getFrame(fromTime: index)
			}
			DispatchQueue.main.async {
				//self.originalImageView.image = self.originalFrames.first
				
			}
			self.originalGenerator = nil
			DispatchQueue.main.async {
				self.originalProgress.stopAnimation(nil)
				self.originalProgress.isHidden = true
				self.originalProcessing = false
				self.originalDropView.layer?.backgroundColor = NSColor.green.cgColor
				self.originalDropView.completed = true
			}
			
		}
		
		
	}
	
	@objc func fileAdded2(_ notificaton: NSNotification) {
		self.testProgress.isHidden = false
		self.testProgress.isIndeterminate = true
		self.testProgress.startAnimation(nil)
		DispatchQueue.global(qos: .background).async {
			self.testProcessing = true
			self.testPath = notificaton.userInfo!["fileName2"]! as! String
			let asset = AVAsset(url: URL(fileURLWithPath: self.testPath))
			let duration = CMTimeGetSeconds(asset.duration)
			self.testGenerator = AVAssetImageGenerator(asset: asset)
			self.testGenerator.appliesPreferredTrackTransform = true
			self.testFrames = []
			for index:Int in 0 ..< Int(duration) {
				self.getFrame2(fromTime: index)
			}
			DispatchQueue.main.async {
				//self.copyImageView.image = self.testFrames.first
			}
			self.testGenerator = nil
			DispatchQueue.main.async {
				self.testProgress.stopAnimation(nil)
				self.testProgress.isHidden = true
				self.testProcessing = false
				self.copyDropView.layer?.backgroundColor = NSColor.green.cgColor
				self.copyDropView.completed = true
			}
		}
		
		
	}
	//MARK: CodeFest
	
	private func getFrame(fromTime:Int) {
		let time:CMTime = CMTimeMakeWithSeconds(Float64(exactly: fromTime)!, preferredTimescale:600)
		let image:CGImage
		do {
			try image = self.originalGenerator.copyCGImage(at:time, actualTime:nil)
		} catch {
			return
		}
		self.originalFrames.append(NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height)))
	}
	
	private func getFrame2(fromTime:Int) {
		let time:CMTime = CMTimeMakeWithSeconds(Float64(exactly: fromTime)!, preferredTimescale:600)
		let image:CGImage
		do {
			try image = self.testGenerator.copyCGImage(at:time, actualTime:nil)
		} catch {
			return
		}
		self.testFrames.append(NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height)))
	}
	
	@IBAction func checkPressed(_ sender: Any) {
		if originalProcessing == true || originalFrames.isEmpty || testFrames.isEmpty || testProcessing == true {
			let a: NSAlert = NSAlert()
			a.messageText = "Error"
			a.informativeText = "Please add videos"
			a.addButton(withTitle: "Ok")
			a.alertStyle = NSAlert.Style.warning
			let delegate = NSApplication.shared.delegate as! AppDelegate
			a.runModal()
		} else {
			if self.originalPath == self.testPath {
				percentCorrect = 1
				percentOverall = 1
				progressDone(percent: percent)
			}
			
			if originalFrames.count > testFrames.count {
				progressBar.maxValue = Double(originalFrames.count)
				percentOverall = originalFrames.count
			} else {
				progressBar.maxValue = Double(testFrames.count)
				percentOverall = testFrames.count
			}
			let frames = commonElements(originalFrames, testFrames)
			
			percentCorrect = frames.count
			percent = Double(percentCorrect/percentOverall)
			print(percent)
			progressDone(percent: percent)
			originalProcessing = false
			
			//			var count = 0
			//
			//			var originalByteArray:[NSNumber] = [NSNumber]()
			//
			//			for image in originalFrames {
			//				for byte in getArrayOfBytesFromImage(imageData: image.tiffRepresentation!) {
			//					originalByteArray.append(byte)
			//				}
			//
			//			}
			//
			//			var copyByteArray:[NSNumber] = [NSNumber]()
			//
			//			for image in testFrames {
			//
			//				for byte in getArrayOfBytesFromImage(imageData: image.tiffRepresentation!) {
			//					copyByteArray.append(byte)
			//				}
			//
			//
			//			}
			//			if originalByteArray.count > copyByteArray.count {
			//				progressBar.maxValue = Double(originalByteArray.count)
			//			} else {
			//				progressBar.maxValue = Double(copyByteArray.count)
			//			}
			//
			//
			//			let frames = commonElements(originalByteArray, copyByteArray)
			//
			//
			//			percentOverall = originalFrames.count
			//			percentCorrect = frames.count
			//			percent = Double(percentCorrect/percentOverall)
			//			print(percent)
		}
		
	}
	
	override var representedObject: Any? {
		didSet {
			// Update the view, if already loaded.
		}
	}
	
	
	func commonElements<T: Sequence, U: Sequence>(_ lhs: T, _ rhs: U) -> [T.Iterator.Element]
		where T.Iterator.Element: Equatable, T.Iterator.Element == U.Iterator.Element {
			var common: [T.Iterator.Element] = []
			
			for lhsItem in lhs {
				for rhsItem in rhs {
					if lhsItem == rhsItem {
						common.append(lhsItem)
					}
				}
				self.progressBar.increment(by: 1)
			}
			return common
	}
	func getArrayOfBytesFromImage(imageData:Data) -> [NSNumber]
	{
		
		// the number of elements:
		let count = imageData.count / MemoryLayout<UInt8>.size
		
		// create array of appropriate length:
		var bytes = [UInt8](repeating: 0, count: count)
		
		// copy bytes into array
		imageData.copyBytes(to: &bytes, count: MemoryLayout<UInt8>.size)
		
		var byteArray:[NSNumber] = [NSNumber]()
		
		for i in 0...count-1 {
			byteArray.append(NSNumber(value: bytes[i]))
		}
		
		return byteArray
		
		
	}
	
	
}



class DropView: NSView {
	
	var filePath: String?
	let expectedExt = ["mov", "mp4"]  //file extensions allowed for Drag&Drop (example: "jpg","png","docx", etc..)
	var viewTag = 0
	var image: NSImageView!
	var completed = false
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		self.wantsLayer = true
		self.layer?.backgroundColor = NSColor.gray.cgColor
		registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
		self.image = NSImageView(frame: (self.layer?.frame)!)
		if viewTag == 1 {
			self.image.image = NSImage(named: NSImage.Name("cwbgleft"))
		} else {
			self.image.image = NSImage(named: NSImage.Name("cwbgright"))

		}
		self.addSubview(self.image, positioned: .above, relativeTo: self)
	}
	
	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		// Drawing code here.
	}
	
	func setImage(_ image: NSImage) {
		self.image = NSImageView(frame: (self.layer?.frame)!)
		self.image.image = image
		self.addSubview(self.image)
		
		
	}
	
	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
		if completed == false {
			if checkExtension(sender) == true {
				self.layer?.backgroundColor = NSColor.blue.cgColor
				return .copy
			} else {
				return NSDragOperation()
			}
		}
		self.layer?.backgroundColor = NSColor.green.cgColor
		return NSDragOperation()
		
	}
	
	
	fileprivate func checkExtension(_ drag: NSDraggingInfo) -> Bool {
		guard let board = drag.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
			let path = board[0] as? String
			else { return false }
		
		let suffix = URL(fileURLWithPath: path).pathExtension
		for ext in self.expectedExt {
			if ext.lowercased() == suffix {
				return true
			}
		}
		return false
	}
	
	override func draggingExited(_ sender: NSDraggingInfo?) {
		if completed == false {
			self.layer?.backgroundColor = NSColor.gray.cgColor
		} else {
			self.layer?.backgroundColor = NSColor.green.cgColor
		}
	}
	
	override func draggingEnded(_ sender: NSDraggingInfo) {
		if completed == false {
			self.layer?.backgroundColor = NSColor.gray.cgColor
		} else {
			self.layer?.backgroundColor = NSColor.green.cgColor
		}
	}
	
	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
			let path = pasteboard[0] as? String
			else { return false }
		
		//GET YOUR FILE PATH !!!
		self.filePath = path
		Swift.print("FilePath: \(path)")
		if self.viewTag == 1 {
			NotificationCenter.default.post(name: NSNotification.Name("fileAdded"), object: nil, userInfo: ["fileName" : path])
		} else if self.viewTag == 2 {
			NotificationCenter.default.post(name: NSNotification.Name("fileAdded2"), object: nil, userInfo: ["fileName2" : path])
		}
		
		
		return true
	}
}

extension NSImage {
	static func ==(lhs: NSImage, rhs: NSImage) -> Bool {
		return  lhs.tiffRepresentation == rhs.tiffRepresentation
	}
}


class BGView: NSView {
	
	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		
		// #1d161d
		NSColor.windowBackgroundColor.setFill()
		dirtyRect.fill()
	}
	
}
