//
//  SwatTemplate.swift
//  Swat
//
//  Created by Michael VanAllen on 19.04.17.
//  Copyright © 2017 ReactiveCode Studios. All rights reserved.
//

import Foundation


class SwatTemplate {
	let contents: String
	
	required init(with contents: String) {
		self.contents = contents
	}
	
	convenience init(contentsOf url: URL) throws {
		self.init(with: try String(contentsOf: url))
	}
	
	public lazy var artifact: SwatArtifact = {
		return self.generateArtifact()
	}()
	
	private func generateArtifact() -> SwatArtifact {
		
		/*//--
		// ..might wanna use regexes: https://code.tutsplus.com/tutorials/swift-and-regular-expressions-swift--cms-26626
		//--*/
		
		let swiftCodeTag = (left: "{*", right: "*}")//(start: "{*", end: "*}")
		let swiftEvalTag = (left: "{(", right: ")}")//(start: "{(", end: ")}")
		
		
		var fragments = [SwatFragment]()
		
		let codeComponents = contents.findPairings(pair: swiftCodeTag)
		let evalComponents = contents.findPairings(pair: swiftEvalTag)
		let components = (codeComponents + evalComponents).sorted { (a, b) in a.left.lowerBound < b.left.lowerBound }
		
		contents.enumeratePairedSubstrings(of: components, paired: { (contents, range, pair) in
			switch pair {
			case let tag where tag == swiftCodeTag: fragments.append(SwatArtifact.SwiftCodeFragment(value: contents.trimmingCharacters(in: .whitespacesAndNewlines)))
			case let tag where tag == swiftEvalTag: fragments.append(SwatArtifact.SwiftEvalFragment(value: contents.trimmingCharacters(in: .whitespacesAndNewlines)))
			default: break
			}
			
		}, gap: { (contents, range) in
			fragments.append(SwatArtifact.TemplateFragment(value: contents))
		})
		
		
		if fragments.count > 1 {
			for idx in 1..<fragments.count {
				let elem = fragments[idx]
				
				let idxBefore = fragments.index(before: idx)
				let elemBefore = fragments[idxBefore]
				
				if        elemBefore is SwatArtifact.TemplateFragment && elem is SwatArtifact.SwiftCodeFragment {
					let oldValue = elemBefore.value
					let newValue = oldValue.replacingOccurrences(of: "\n[ \\t]+$", with: "\n", options: .regularExpression)
					
					fragments[idxBefore] = SwatArtifact.TemplateFragment(value: newValue)
					
				} else if elemBefore is SwatArtifact.SwiftCodeFragment && elem is SwatArtifact.TemplateFragment {
					let oldValue = elem.value
					let newValue = oldValue.replacingOccurrences(of: "^[ \\t]*\n", with: "", options: .regularExpression)
					
					fragments[idx] = SwatArtifact.TemplateFragment(value: newValue)
				}
			}
		}
		
		
		let artifact = SwatArtifact()
		
		artifact.fragments = fragments
		
		return artifact
	}
}
