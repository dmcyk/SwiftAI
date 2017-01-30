//
//  Individual.swift
//  Genetic
//
//  Created by Damian Malarczyk on 28.10.2016.
//
//

import Foundation


protocol Indv: Comparable {
    var fitness: Double { get set }
}

protocol VectorRepresentable {
    var value: [Double] { get }
    var valueCount: Int { get }
    func value(atIndex: Int) -> Double
    
}


extension Indv {
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.fitness < rhs.fitness
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.fitness == rhs.fitness
    }
}

struct Individual: Indv {
    var chromosome: [Double]
    var fitness: Double = -1
    
    
    init(chromosome: [Double]) {
        self.chromosome = chromosome
    }
    
}

struct Particle: Indv {
    var fitness: Double = -1
    var position: [Double]
    var velocity: [Double]
    var bestPosition: [Double]
    
    init(position: [Double], velocity: [Double]) {
        self.position = position
        self.velocity = velocity
        self.bestPosition = position
    }
}

extension Particle: VectorRepresentable {
    var value: [Double] {
        return position
    }
    
    func value(atIndex: Int) -> Double {
        return position[atIndex]
    }
    
    var valueCount: Int {
        return position.count
    }
}

extension Individual: VectorRepresentable {
    var value: [Double] {
        return chromosome
    }
    
    func value(atIndex: Int) -> Double {
        return chromosome[atIndex]
    }
    
    var valueCount: Int {
        return chromosome.count
    }
}

enum FitnessFunctionType {
    case rmst

    func function<T: VectorRepresentable>() -> (T, [InputData]) -> Double {
        
        switch self {
        case .rmst:
            return fitness_rmst()
        }
    }
}


fileprivate func fitness_rmst<T: VectorRepresentable>() -> (T, [InputData]) -> Double {
    return { individual, input in
        var mean: Double = 0
        
        for i in 0..<input.count {
            let current = input[i]
            var result: Double = 0
            
            for (gene, val) in zip(current.gene, individual.value) {
                result += gene * val
            }
            result = pow(current.expectedResult - result, 2)
            mean += result
        }
        
        return sqrt((1 / Double(input.count)) * mean)
    }
}

