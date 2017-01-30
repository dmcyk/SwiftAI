//
//  Task.swift
//  Genetic
//
//  Created by Damian Malarczyk on 16.10.2016.
//
//

import Utils
import Foundation

struct InputData {
    var gene: [Double]
    var expectedResult: Double
    
    init(_ gene: [Double], expectedResult: Double = -1) {
        self.gene = gene
        self.expectedResult = expectedResult
    }
    
    static func raw(_ data: [InputData]) -> [([Double], [Double])] {
        return data.map {
            ($0.gene, [$0.expectedResult])
        }
    }
}



enum InputError: Swift.Error {
    case emptyInput
    case incorrectInput
}

func forestFiresInput(sourcePath: String) throws -> [InputData]  {
    let input: [InputData] = FileManager.default.lineReadSourceFile(sourcePath) { (line, _) in
        
        var parts: [Double] = line.components(separatedBy: " ").flatMap() { cmp -> Double? in
            
            let trimmed: String = cmp.trimmingCharacters(in: .whitespacesAndNewlines)
            return Double(trimmed)
        }
        guard parts.count > 1 else {
            return nil
        }
        
        // all genes beside last one (which is an expected result), plus one extra
        var genes: [Double] = Array(parts[0 ..< (parts.count - 1)])
        genes.append(1)
        return InputData(genes, expectedResult: parts.last!)
    }
    
    
    guard !input.isEmpty else {
        throw InputError.emptyInput
    }
    
    let firstCount = input[0].gene.count
    
    // each input row should have the same amount of genes
    for i in input.suffix(from: 1) {
        if i.gene.count != firstCount {
            throw InputError.incorrectInput
        }
    }
    return input
}

