//
//  SwatArtifact.swift
//  Swat
//
//  Created by Michael VanAllen on 19.04.17.
//  Copyright © 2017 ReactiveCode Studios. All rights reserved.
//

import Foundation



protocol SwatFragment: CustomStringConvertible {
	var value: String { get }
	func code(using prefix: String) -> String
}


class SwatArtifact: CustomStringConvertible {
	
	struct SwiftCodeFragment: SwatFragment {
		let value: String
		
		func code(using prefix: String) -> String {
			return value + "\n"
		}
		
		var description: String {
			return "\(type(of: self))('\(value)')"
		}
	}
	
	struct SwiftEvalFragment: SwatFragment {
		let value: String
		
		func code(using prefix: String) -> String {
			return "\(prefix)(\"\\(\(value))\")\n"
		}
		
		var description: String {
			return "\(type(of: self))('\(value)')"
		}
	}
	
	struct TemplateFragment: SwatFragment {
		let value: String
		
		func code(using prefix: String) -> String {
			return "\(prefix)(\"\(SwatArtifact.escape(value))\")\n"
		}
		
		var description: String {
			return "\(type(of: self))(\"\(SwatArtifact.escape(value))\")"
		}
	}
	
	static func escape(_ string: String) -> String {
		let backslash = "\\"
		
		return string
			.replacingOccurrences(of: backslash, with: backslash+backslash)
			.replacingOccurrences(of: "\n", with: "\\n")
			.replacingOccurrences(of: "\r", with: "\\r")
			.replacingOccurrences(of: "\t", with: "\\t")
			.replacingOccurrences(of: "\"", with: "\\\"")
	}
	
	public let identifier: String
	
	public let functionName: String
	public var functionParameters: String = ""
	
	var fragments = [SwatFragment]()
	
	private let fragmentVariable: String
	
	init(_ identifier: String = UUID().uuidString.replacingOccurrences(of: "-", with: "")) {
		self.identifier = identifier
		
		self.functionName		= "__artifact_\(identifier)"
		self.fragmentVariable	= "__f_\(identifier.substring(to: identifier.index(identifier.startIndex, offsetBy: 6)).lowercased())"
		
		self.functionParameters	= "Swat: [String:Any], CTX: [String:Any]"
	}
	
	func code() -> String {
		let pre: [SwatFragment] = [
			SwiftCodeFragment(value: "import Foundation"),
			SwiftCodeFragment(value: "let \(functionName) = { (\(functionParameters)) -> String in"),
			SwiftCodeFragment(value: "  var \(fragmentVariable) = [String]()")
		]
		
		let post: [SwatFragment] = [
			SwiftCodeFragment(value: "  return \(fragmentVariable).joined()"),
			SwiftCodeFragment(value: "}"),
			SwiftCodeFragment(value: "print( \(functionName)(\( ["name":"test.swift"] ), \( ["iterations":5] )) )")
		]
		
		return (pre + fragments + post).map { $0.code(using: "  \(fragmentVariable).append") }.joined()
	}
	
	var description: String {
		let indent = "    "
		
		var desc = "\(type(of: self)) \(functionName)(\(functionParameters)) = {\n" + indent
		desc += fragments.map { $0.description }.joined(separator: "\n" + indent)
		desc += "\n}"
		
		return desc
	}
}
