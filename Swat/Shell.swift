//
//  Shell.swift
//  Swat
//
//  Created by Michael VanAllen on 04.04.17.
//  Copyright © 2017 ReactiveCode Studios. All rights reserved.
//

import Foundation


struct ShellCommand {
	let launchPath: String
	
	var arguments: [String]
	var environment: [String : String]
	var workingDirectory: String?
	
	init(_ cmd: String, args: [String] = [], env: [String : String] = [:], workDir: String? = nil) {
		self.launchPath			= cmd
		self.arguments			= args
		self.environment		= env
		self.workingDirectory	= workDir
	}
}


class Shell {
	
	struct ConsoleIO {
		let pipe: Pipe = Pipe()
		var observer: NSObjectProtocol?
		var data: Data = Data()
	}
	
	class func exec(_ command: ShellCommand, pipe data: Data? = nil, timeout: DispatchTimeInterval = .seconds(10), completion: @escaping ((code: Int32, reason: Process.TerminationReason), (stdout: Data, stderr: Data)) -> Void = { _ in }) {
		let stdin	= ConsoleIO()
		var stdout	= ConsoleIO()
		var stderr	= ConsoleIO()
		
		let process = Process()
		
		process.launchPath	= command.launchPath
		process.arguments	= command.arguments
		process.environment	= command.environment
		if let currentDirectoryPath = command.workingDirectory {
			process.currentDirectoryPath = currentDirectoryPath
		}
		
		process.standardInput	= stdin.pipe
		process.standardOutput	= stdout.pipe
		process.standardError	= stderr.pipe
		
		stdout.pipe.fileHandleForReading.readabilityHandler = { filehandle in
			print("[Shell.exec()] (..got data..)")
			stdout.data.append(filehandle.availableData)
		}
		
		stderr.pipe.fileHandleForReading.readabilityHandler = { filehandle in
			print("[Shell.exec()] (..got data..)")
			stderr.data.append(filehandle.availableData)
		}
		
		process.terminationHandler = { process in
			print("[Shell.exec()] (..terminated..)")
			stdout.pipe.fileHandleForReading.readabilityHandler = nil
			stderr.pipe.fileHandleForReading.readabilityHandler = nil
		}
		
		if let data = data {
			stdin.pipe.fileHandleForWriting.write(data)
			stdin.pipe.fileHandleForWriting.closeFile()
		}
		
		DispatchQueue.global(qos: .default).async {
			print("[Shell.exec()] Launching '\(process.launchPath!) \(process.arguments!.joined(separator: " "))'")
			
			do {
				try ObjC.catchException { process.launch() }
				
			} catch let error {
				if let terminationHandler = process.terminationHandler {
					terminationHandler(process)
				}
				print("[Shell.exec()] *** ERROR – failed to launch '\(process.launchPath!) \(process.arguments!.joined(separator: " "))' w/ error: \(error)")
				return completion( (-1, .uncaughtSignal), (stdout.data, stderr.data) )
			}
			
			DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + timeout) {	// DispatchAfter termination guard (a.k.a. Plan B)
				if process.isRunning {
					print("[Shell.exec()] ..terminating (dispatch timeout)..")
					process.terminate()
				} else {
					debugPrint("[Shell.exec()] (..terminate dispatch cancelled..)")
				}
			}
			
			process.waitUntilExit()	// ..aaand it's gone.
			
			print("[Shell.exec()] Exited '\(process.launchPath!) \(process.arguments!.joined(separator: " "))' w/ code \(process.terminationStatus), reason: \([1:".exit",2:".uncaughtSignal"][process.terminationReason.rawValue]!)")
			completion( (process.terminationStatus, process.terminationReason), (stdout.data, stderr.data) )
		}
	}
	
	class func execSync(_ command: ShellCommand, pipe data: Data? = nil, timeout: DispatchTimeInterval = .seconds(10)) -> ((code: Int32, reason: Process.TerminationReason), (stdout: Data, stderr: Data)) {
		var exit: (Int32, Process.TerminationReason) = (0, .exit)
		var console: (Data, Data) = (Data(), Data())
		
		let lock = DispatchSemaphore(value: 0)
		Shell.exec(command, pipe: data, timeout: timeout) { status, output in
			exit	= status
			console	= output
			
			lock.signal()
		}
		lock.wait()
		
		return (exit, console)
	}
	
	// TODO: turn into instance method & implement inject()/await() functions
	class func spawn(_ command: ShellCommand, completion: @escaping ((code: Int32, reason: Process.TerminationReason), (stdout: Data, stderr: Data)) -> Void = { _ in }) {
		let stdin	= ConsoleIO()
		var stdout	= ConsoleIO()
		var stderr	= ConsoleIO()
		
		let process = Process()
		
		process.launchPath	= command.launchPath
		process.arguments	= command.arguments
		process.environment	= command.environment
		if let currentDirectoryPath = command.workingDirectory {
			process.currentDirectoryPath = currentDirectoryPath
		}
		
		process.standardInput	= stdin.pipe
		process.standardOutput	= stdout.pipe
		process.standardError	= stderr.pipe
		
		stdout.pipe.fileHandleForReading.readabilityHandler = { filehandle in
			let data = filehandle.availableData
			print("[Shell.spawn()] (..got stdout data » \(data.count) bytes ..)")
			stdout.data.append(data)
		}
		
		stderr.pipe.fileHandleForReading.readabilityHandler = { filehandle in
			let data = filehandle.availableData
			print("[Shell.spawn()] (..got stderr data » \(data.count) bytes ..)")
			stderr.data.append(data)
		}
		
		process.terminationHandler = { process in
			print("[Shell.spawn()] (..terminated..)")
			stdout.pipe.fileHandleForReading.readabilityHandler = nil
			stderr.pipe.fileHandleForReading.readabilityHandler = nil
		}
		
		do {
			print("[Shell.spawn()] Launching '\(process.launchPath!) \(process.arguments!.joined(separator: " "))'")
			try ObjC.catchException { process.launch() }
			
			
			// Option B: use w/o argument for interactive session
			DispatchQueue.global(qos: .default).asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(5)) {
				let cmd = ":help\n"; print("[Shell.spawn()] + Writing: '\(cmd.replacingOccurrences(of: "\n", with: "\\n"))'")
				stdin.pipe.fileHandleForWriting.write((cmd).data(using: .utf8)!)
				stdout.data.append(">> \(cmd)".data(using: .utf8)!)
				
				DispatchQueue.global(qos: .default).asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2)) {
					let cmd = ":version\n"; print("[Shell.spawn()] + Writing: '\(cmd.replacingOccurrences(of: "\n", with: "\\n"))'")
					stdin.pipe.fileHandleForWriting.write((cmd).data(using: .utf8)!)
					stdout.data.append(">> \(cmd)".data(using: .utf8)!)
					
					DispatchQueue.global(qos: .default).asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1)) {
						let cmd = ":quit\n"; print("[Shell.spawn()] + Writing: '\(cmd.replacingOccurrences(of: "\n", with: "\\n"))'")
						stdin.pipe.fileHandleForWriting.write((cmd).data(using: .utf8)!)
						stdout.data.append(">> \(cmd)".data(using: .utf8)!)
					}
				}
			}
			
			
			/*var start = Date(), cnt = 0
			while process.isRunning && abs(start.timeIntervalSinceNow) < 10.0 {		// Runloop termination guard (a.k.a. Plan A)
				print(cnt % 10 == 0 ? "\n[Shell.exec()] Running runloop" : ".", terminator: ""); cnt += 1
				RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
			}
			if process.isRunning {	// Final line of defense.
				print(" terminating (runloop timeout)")
				process.terminate()
			}*/
			
			process.waitUntilExit()	// ..aaand it's gone.
			
			print("[Shell.spawn()] Exited '\(process.launchPath!) \(process.arguments!.joined(separator: " "))' w/ code \(process.terminationStatus), reason: \([1:".exit",2:".uncaughtSignal"][process.terminationReason.rawValue]!)")
			completion( (process.terminationStatus, process.terminationReason), (stdout.data, stderr.data) )
			
		} catch let error {
			if let terminationHandler = process.terminationHandler {
				terminationHandler(process)
			}
			print("[Shell.spawn()] *** ERROR – failed to launch '\(process.launchPath!) \(process.arguments!.joined(separator: " "))' w/ error: \(error)")
			completion( (-1, .uncaughtSignal), (stdout.data, stderr.data) )
		}
	}
}

/*
Shell.exec(ShellCommand("/usr/bin/swift", args: ["-"]), pipe: "print(\"Hello, world!\")".data(using: .utf8), timeout: .seconds(5)) { status, console in
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
}
*/

/*
let (exit, console) = Shell.execSync(ShellCommand("/bin/ls", args: ["-la"]))
print(exit)
print(String(data:console.stdout, encoding:.utf8)!)
*/

/*
let lock = DispatchSemaphore(value: 0)
Shell.spawn(ShellCommand("/usr/bin/swift")) { status, console in
	print("\n##### OUTPUT:\n\(String(data: console.stdout, encoding: .utf8)!)")
	
	lock.signal()
}
lock.wait()
*/
