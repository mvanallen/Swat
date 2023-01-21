//
//  String+Pairings.swift
//  MultiParse
//
//  Created by Michael VanAllen on 19.04.17.
//  Copyright © 2017 ReactiveCode Studios. All rights reserved.
//

import Foundation


extension String {
	
	func findPairings(pair: (left: String, right: String)) -> [(left: Range<String.Index>, right: Range<String.Index>)] {
		let string = self
		
		var pairings: [(left: Range<String.Index>, right: Range<String.Index>)] = []
		
		let minPairLength = min(pair.left.characters.count, pair.left.characters.count)
		var searchRange = string.startIndex..<string.endIndex
		var pairStack: [(string: String, pos: Range<String.Index>)] = []
		
		while string.distance(from: searchRange.lowerBound, to: searchRange.upperBound) >= minPairLength {
			let nextLeft	= string.range(of: pair.left, options: .literal, range: searchRange)
			let nextRight	= string.range(of: pair.right, options: .literal, range: searchRange)
			
			var next: (string: String, pos: Range<String.Index>)
			
			if let left = nextLeft, let right = nextRight {
				next = left.lowerBound < right.lowerBound ? (string: pair.left, pos: left) : (string: pair.right, pos: right)
				
			} else if let left = nextLeft {
				next = (string: pair.left, pos: left)
				
			} else if let right = nextRight {
				next = (string: pair.right, pos: right)
				
			} else {
				break
			}
			
			searchRange = next.pos.upperBound..<searchRange.upperBound
			
			if let last = pairStack.last, last.string == pair.left, next.string == pair.right {
				pairStack.removeLast()
				pairings.append( (left: last.pos, right: next.pos) )
				
			} else {
				pairStack.append(next)
			}
		}
		
		if !pairStack.isEmpty {
			print("[String.findPairings()] *** Warning – unpaired elements found!")
		}
		
		return pairings
	}
	
	func contentsOfPair(_ pair: (left: Range<String.Index>, right: Range<String.Index>), includingPairStrings: Bool = false) -> String {
		
		return includingPairStrings ? self[pair.left.lowerBound..<pair.right.upperBound] : self[pair.left.upperBound..<pair.right.lowerBound]
	}
	
	func enumeratePairedSubstrings(of pairs: [(left: Range<String.Index>, right: Range<String.Index>)],
	                               paired: (_ contents: String, _ range: Range<String.Index>, _ pair: (left: String, right: String)) -> (),
	                               gap: (_ contents: String, _ range: Range<String.Index>) -> ()	) {
		let string = self
		
		var leftBound = string.startIndex
		var rightBound = string.endIndex
		
		for pair in pairs {
			
			rightBound = pair.left.lowerBound
			if string.distance(from: leftBound, to: rightBound) > 0 {
				let range = leftBound..<rightBound
				let contents = string.substring(with: range)
				
				gap(contents, range)
			}
			
			leftBound = pair.left.upperBound
			rightBound = pair.right.lowerBound
			if string.distance(from: leftBound, to: rightBound) > 0 {
				let range = leftBound..<rightBound
				let contents = string.substring(with: range)
				let left = string.substring(with: pair.left.lowerBound..<pair.left.upperBound)
				let right = string.substring(with: pair.right.lowerBound..<pair.right.upperBound)
				
				paired(contents, range, (left, right))
			}
			
			leftBound = pair.right.upperBound
			rightBound = string.endIndex
		}
		
		if string.distance(from: leftBound, to: rightBound) > 0 {
			let range = leftBound..<rightBound
			let contents = string.substring(with: range)
			
			gap(contents, range)
		}
	}
}
