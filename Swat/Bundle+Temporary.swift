//
//  Bundle+Temporary.swift
//  Swat
//
//  Created by Michael VanAllen on 04.04.17.
//  Copyright © 2017 ReactiveCode Studios. All rights reserved.
//

import Foundation


/* See:
	http://stackoverflow.com/questions/32657533/temporary-file-path-using-swift
	http://www.cocoawithlove.com/2009/07/temporary-files-and-folders-in-cocoa.html
*/


extension Bundle {
	
	static func temporary(_ identifier: String? = Bundle.main.bundleIdentifier) -> TemporaryBundle? {
		guard let identifier = identifier else {
			print("[Bundle.temporary()] *** WARNING – cannot create temporary bundle without identifier.")
			return nil
		}
		
		let tempPath	= URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
		let bundlePath	= tempPath.appendingPathComponent(identifier)
		
		let fm = FileManager.default
		var isDir = ObjCBool(false)
		if !(fm.fileExists(atPath: bundlePath.path, isDirectory: &isDir) && isDir.boolValue) {
			do {
				try fm.createDirectory(at: bundlePath, withIntermediateDirectories: false, attributes: nil)
			} catch {
				print("[Bundle.temporary()] *** WARNING – failed to create temporary bundle at path '\(bundlePath.absoluteString)'")
				return nil
			}
		}
		
		return TemporaryBundle(url: bundlePath)
	}
}


class TemporaryBundle: Bundle {
	
	func clean() {
		let fm = FileManager.default
		
		do {
			let files = try fm.contentsOfDirectory(at: self.bundleURL, includingPropertiesForKeys: nil, options: [])
			for file in files {
				try fm.removeItem(at: file)
			}
		} catch { }
	}
}


/*
if let bundle = Bundle.temporary("com.reactivecode-studios.Swat") {
	print("Temporary bundle: \(bundle)")
	bundle.clean()
}
*/
