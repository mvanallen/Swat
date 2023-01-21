//
//  SwatCompiler.swift
//  Swat
//
//  Created by Michael VanAllen on 19.04.17.
//  Copyright © 2017 ReactiveCode Studios. All rights reserved.
//

import Foundation


struct CompilerError: Error {
	let source: String
	let line: Int
	let column: Int
	let type: String
	let reason: String
	
	init(source: String, line: Int, column: Int, type: String, reason: String) {
		self.source	= source
		self.line	= line
		self.column	= column
		self.type	= type
		self.reason	= reason
	}
	
	init?(message: String) {
		var fields = [String]()
		
		let errorPattern = "^(.+?):(\\d+):(\\d+): (\\w+): (.*)$"
		
		if let regex = try? NSRegularExpression(pattern: errorPattern, options: [.dotMatchesLineSeparators]) {
			regex.enumerateMatches(in: message, options: [], range: NSRange(location: 0, length: message.characters.count), using: { (match, flags, stop) in
				if let match = match, match.numberOfRanges > 1 {
					for idx in 1..<match.numberOfRanges {
						
						let range = { m -> Range<String.Index> in
							let r = match.rangeAt(idx)
							let lo = m.index(m.startIndex, offsetBy: r.location)
							let up = m.index(lo, offsetBy: r.length)
							return lo..<up
						}(message)
						
						let value = message.substring(with: range)
						
						fields.append(value)
						//print("\(idx): '\(value)'")
					}
				}
			})
		}
		
		guard fields.count == 5 else {
			return nil
		}
		
		self.init(
			source:	fields[0],
			line:	Int(fields[1]) ?? -1,
			column:	Int(fields[2]) ?? -1,
			type:	fields[3],
			reason:	fields[4].trimmingCharacters(in: .whitespacesAndNewlines)
		)
	}
}


class SwatCompiler {
	
	private class func parseCompilerMessages(_ messages: String) -> [CompilerError] {
		var errors = [CompilerError]()
		
		let sourceFieldBound = messages.range(of: ":")?.lowerBound
		let messageBoundary = sourceFieldBound != nil ? messages.substring(to: sourceFieldBound!) : "<stdin>"
		
		for messagePart in messages.components(separatedBy: messageBoundary) {
			if let error = CompilerError(message: messageBoundary + messagePart) {
				errors.append(error)
			}
		}
		
		return errors
	}
	
	class var isFullyOperational: Bool {
		let (errors, output) = SwatCompiler.runSync(script: "print(\"OK\")")
		
		return errors.isEmpty && output == "OK\n"
	}
	
	class func run(scriptAt url: URL, timeout: DispatchTimeInterval = .seconds(10), completion: @escaping ([CompilerError], _ output: String) -> Void) {
		
		guard let script = try? String(contentsOf: url) else {
			return DispatchQueue.global().async { completion([CompilerError(source: "<internal>", line: 0, column: 0, type: "error", reason: "file not found at '\(url.absoluteString)'")], "") }
		}
		
		self.run(script: script, timeout: timeout, completion: completion)
	}
	
	class func run(script: String, timeout: DispatchTimeInterval = .seconds(10), completion: @escaping ([CompilerError], _ output: String) -> Void) {
		
		Shell.exec(ShellCommand("/usr/bin/swift", args: ["-"]), pipe: script.data(using: .utf8), timeout: timeout) { exit, console in
			print("exit\(exit), console\(console)")
			
			let stdout = String(data: console.stdout, encoding: .utf8)!
			let stderr = String(data: console.stderr, encoding: .utf8)!
			
			let output: String
			let errors: [CompilerError]
			//if stderr.lengthOfBytes(using: .utf8) > 0 {
				output = stdout
				errors = parseCompilerMessages(stderr)
				
			/*} else {
				output = stdout
				errors = []
			}*/
			
			completion(errors, output)
		}
	}
	
	class func runSync(scriptAt url: URL, timeout: DispatchTimeInterval = .seconds(10)) -> ([CompilerError], String) {
		
		guard let script = try? String(contentsOf: url) else {
			return ([CompilerError(source: "<internal>", line: 0, column: 0, type: "error", reason: "file not found at '\(url.absoluteString)'")], "")
		}
		
		return self.runSync(script: script, timeout: timeout)
	}
	
	class func runSync(script: String, timeout: DispatchTimeInterval = .seconds(10)) -> ([CompilerError], String) {
		
		let (exit, console) = Shell.execSync(ShellCommand("/usr/bin/swift", args: ["-"]), pipe: script.data(using: .utf8), timeout: timeout)
		print("exit\(exit), console\(console)")
		
		let stdout = String(data: console.stdout, encoding: .utf8)!
		let stderr = String(data: console.stderr, encoding: .utf8)!
		
		let output = stdout
		let errors = parseCompilerMessages(stderr)
		
		return (errors, output)
	}
}
