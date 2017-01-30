//
//  Particle+cache.swift
//  Task2
//
//  Created by Damian Malarczyk on 17.11.2016.
//
//

import Foundation



extension ParticleNetworkEvolver {
    class Cache {
        
        struct Entry {
            let inputId: String
            let size: Int
            let iterations: Int
            let maxPositionValue: Int
            
            var string: String {
                let str: [String] = [size, iterations, maxPositionValue].map { String($0) }
                let result: [String] = [inputId] + str
                return result.joined(separator: " ")
                
            }
            
            init(inputId: String, size: Int, iterations: Int, maxPositionValue: Int) {
                self.inputId = inputId
                self.size = size
                self.iterations = iterations
                self.maxPositionValue = maxPositionValue
            }
            
            init?(str: String) {
                let components = str.components(separatedBy: " ")
                guard components.count == 4 else {
                    return nil
                }
                let id = components[0]
                let values = components[1 ... 3].flatMap {
                    Int($0)
                }
                guard values.count == 3 else {
                    return nil
                }
                
                self.init(inputId: id, size: values[0], iterations: values[1], maxPositionValue: values[2])
                
            }
            
            
            static func ==(_ lhs: Entry, _ rhs: Entry) -> Bool {
                return lhs ~= rhs && lhs.iterations == rhs.iterations && lhs.size == rhs.size && lhs.maxPositionValue ==  rhs.maxPositionValue
            }
            
            static func ~=(_ lhs: Entry, _ rhs: Entry) -> Bool {
                return lhs.inputId == rhs.inputId
            }
        }
        
        
        
        
        enum Error: Swift.Error {
            case wrongPath
            case openingFileDescriptor
            case creatingData(String)
            case multipleEntries
        }
        
        private let cacheFile: URL
        
        init(path: String) throws {
            var bool: ObjCBool = false
            
            #if os(Linux)
                guard FileManager.default.fileExists(atPath: path, isDirectory: &bool) && bool else {
                    throw Error.wrongPath
                }
            #else
                guard FileManager.default.fileExists(atPath: path, isDirectory: &bool) && bool.boolValue else {
                    throw Error.wrongPath
                }
            #endif
            self.cacheFile = URL(fileURLWithPath: path).appendingPathComponent("particle_cache.txt")
            
            if !FileManager.default.fileExists(atPath: cacheFile.path) {
                try "".write(to: cacheFile, atomically: true, encoding: .utf8)
            }
        }
        
        
        private func parametersWithLine(forEntry entry: Entry, rounding: Bool) throws -> (Parameters?, Int) {
            var continueFlag = true
            var lNumber = -1
            let res: [Parameters] = FileManager.default.lineReadSourceFile(cacheFile.path, continueFlag: &continueFlag) { (line, lineNumber) in
                let cmp = line.components(separatedBy: " = ").map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                guard cmp.count == 2 else {
                    return nil
                }
                
                if let foundEntry = Entry(str: cmp[0]) {
                    if (rounding && foundEntry ~= entry) || foundEntry == entry {
                        continueFlag = false
                        lNumber  = lineNumber
                        return ParticleNetworkEvolver.Parameters(str: cmp[1])
                    }
                }
                return nil
                
            }
            
            if res.isEmpty {
                return (nil, lNumber)
            }
            
            if res.count > 1 {
                throw Error.multipleEntries
            }
            
            return (res[0], lNumber)
            
        }
        
        func parameters(forEntry entry: Entry, rounding: Bool) throws -> Parameters? {
            return try parametersWithLine(forEntry: entry, rounding: rounding).0
        }
        
        func cache(parameters params: Parameters, entry: Entry) throws {
            let found = try parametersWithLine(forEntry: entry, rounding: true)
            if let _ = found.0 {
                try FileManager.default.remove(line: found.1, atFile: cacheFile.path)
                
            }
            
            guard let handle = FileHandle(forWritingAtPath: cacheFile.path) else {
                throw Error.openingFileDescriptor
            }
            
            let content: String = "\(entry.string) = \(params.string)\n"
            
            guard let data = content.data(using: .utf8) else {
                throw Error.creatingData(content)
            }
            
            handle.write(data)
        }
    }
    
    
}
