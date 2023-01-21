//
//  main.swift
//  Swat
//
//  Created by Michael VanAllen on 31.03.17.
//  Copyright © 2017 ReactiveCode Studios. All rights reserved.
//

import Foundation
import AppKit


private func _test() {
	
	
}



private func pbcopy(_ string: String) {
	string.pbcopy()
}



func main () {
	
	func build(artifact: SwatArtifact) {
		let artifactCode = artifact.code()
		pbcopy(artifactCode)	//--> run in terminal: `pbpaste|swift -`
		
		let (errors, output) = SwatCompiler.runSync(script: artifactCode, timeout: .seconds(5))
		
		print("\n##### OUTPUT:\n\(output)")
		output.pbcopy()
		
		/*let lock = DispatchSemaphore(value: 0)
		Shell.exec(ShellCommand("/usr/bin/swift", args: ["-"]), pipe: artifact.code().data(using: .utf8), timeout: .seconds(10)) { status, console in
			print("status\(status), console\(console)")
			
			let stdout = String(data: console.stdout, encoding: .utf8)!
			let stderr = String(data: console.stderr, encoding: .utf8)!
			
			let output: String
			if stderr.lengthOfBytes(using: .utf8) > 0 {
				output = stderr
			} else {
				output = stdout
			}
			
			print("\n##### OUTPUT:\n\(output)")
			output.pbcopy()
			
			lock.signal()
		}
		lock.wait()*/
	}
	
	func verify(artifact: SwatArtifact, filter: Bool = false) {
		var fragments = artifact.fragments
		if filter {
			fragments = fragments.filter { (($0 as? SwatArtifact.SwiftCodeFragment) != nil) || (($0 as? SwatArtifact.SwiftEvalFragment) != nil) }
		}
		let artifactCode = fragments.map { $0.code(using: "__f.append") }.joined(separator: "")
		pbcopy(artifactCode)	//--> run in terminal: `pbpaste > tst.swift && swiftc -parse tst.swift`
		
		
		if let temporary = Bundle.temporary("com.reactivecode-studios.Swat") {
			
			let tempArtifact = temporary.bundleURL.appendingPathComponent("artifact_\(artifact.identifier).swift")
			do {
				try artifactCode.write(toFile: tempArtifact.path, atomically: false, encoding: .utf8)
				
				let (exit, console) = Shell.execSync(ShellCommand("/usr/bin/swiftc", args: ["-parse", tempArtifact.path]))
				print("Exit: \(exit)")
				
				let stdout = String(data: console.stdout, encoding: .utf8)!
				let stderr = String(data: console.stderr, encoding: .utf8)!
				
				let output: String
				if stderr.lengthOfBytes(using: .utf8) > 0 {
					output = stderr
				} else {
					output = stdout
				}
				
				print("\n##### OUTPUT:\n\(output)")
				output.pbcopy()
				
			} catch let error {
				print(error)
			}
			
			temporary.clean()
		}
		
	}
	
	func describe(artifact: SwatArtifact) {
		let artifactDescription = artifact.description
		print(artifactDescription)
		pbcopy(artifactDescription)
	}
	
	guard SwatCompiler.isFullyOperational else {
		return
	}
	
	let (errors, output) = SwatCompiler.runSync(scriptAt: URL(fileURLWithPath: "/Users/michael/Entwicklung/Cocoa/xTemp/test.swiftX"))
	//let (errors, output) = SwatCompiler.runSync(script: "let x = \"Hello, world!\"; print(x)")
	print("##### OUTPUT:\n\(output)")
	print("##### ERRORS:")
	let _ = errors.map { print($0) }
	
	/*
	let sync = DispatchSemaphore(value: 0)
	SwatCompiler.run(scriptAt: URL(fileURLWithPath: "/Users/michael/Entwicklung/Cocoa/xTemp/test.swift")) { (errors, output) in
	//SwatCompiler.run(script: "let x = \"Hello, world!\"; print(y)") { (errors, output) in
		
		print("##### OUTPUT:\n\(output)")
		print("##### ERRORS:")
		let _ = errors.map { print($0) }
		
		sync.signal()
	}
	sync.wait()
	*/
	
	let basePath = URL(fileURLWithPath: "/Users/michael/Entwicklung/Cocoa/Projects/Michael/Swat/Templates")
	
	//let tmpl = URL(fileURLWithPath: "00_SimpleFunction.swat", relativeTo: basePath)
	//let tmpl = URL(fileURLWithPath: "01_ComplexFunction.swat", relativeTo: basePath)
	let tmpl = URL(fileURLWithPath: "11_NystromAST.swat", relativeTo: basePath)
	//let tmpl = URL(fileURLWithPath: "20_CombineLatest.swat", relativeTo: basePath)
	
	if let template = try? SwatTemplate(contentsOf: tmpl) {
		let artifact = template.artifact
		
		print(artifact.code()); artifact.code().pbcopy()
		
		//describe(artifact: artifact)
		//verify(artifact: artifact, filter: true)
		build(artifact: artifact)
		
	}
	
	
	let lock = DispatchSemaphore(value: 0)
	//Shell.exec(ShellCommand("/usr/bin/swift", args: ["-"]), pipe: artifact.code().data(using: .utf8), timeout: .seconds(5)) { status, console in
	Shell.spawn(ShellCommand("/usr/bin/swift")) { status, console in
		print("status\(status), console\(console)")
		
		let stdout = String(data: console.stdout, encoding: .utf8)!
		let stderr = String(data: console.stderr, encoding: .utf8)!
		
		let output: String
		if stderr.lengthOfBytes(using: .utf8) > 0 {
			output = stderr
		} else {
			output = stdout
		}
		
		print("\n##### OUTPUT:\n\(output)")
		output.pbcopy()
		
		lock.signal()
	}
	lock.wait()
	
}

main()
