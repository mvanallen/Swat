//
//  String+Pasteboard.swift
//  Swat
//
//  Created by Michael VanAllen on 04.04.17.
//  Copyright © 2017 ReactiveCode Studios. All rights reserved.
//

import Foundation
import AppKit


extension String {
	
	static func pbpaste(from pasteboard: NSPasteboard = NSPasteboard.general()) -> String? {
		return pasteboard.string(forType: NSPasteboardTypeString)
	}
	
	func pbcopy(to pasteboard: NSPasteboard = NSPasteboard.general()) {
		pasteboard.declareTypes([NSPasteboardTypeString], owner: nil)
		pasteboard.setString(self, forType: NSPasteboardTypeString)
	}
}
