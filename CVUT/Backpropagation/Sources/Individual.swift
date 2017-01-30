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

struct Individual: GeneticIndividual {

    var chromosome: [Double]
    var fitness: Double = -1
    
    
    init(chromosome: [Double]) {
        self.chromosome = chromosome
    }
    
    static func random(maxChromosomeValue: Int, size: Int) -> () -> Individual {
        return {
            var randomChromosome: [Double] = []
            
            // one extra bias value
            for _ in 0 ... size {
                randomChromosome.append(Int.arc4random_uniform_d(maxChromosomeValue + 1))
            }
            return Individual(chromosome: randomChromosome)
        }
    }
    
    static func crossover(_ dad: Individual, _ mum: Individual) -> (Individual, Individual) {
        let floatCount = Double(dad.chromosome.count)
        var crossoverPointsCount = Int(round(Double.arc4random_uniform(floor(floatCount / 3))))
        crossoverPointsCount += 1
        let points = dad.chromosome.divide(withCrossoverPoints: crossoverPointsCount)
        var son = dad
        var daughter = mum
        
        for point in points {
            let range = point.0 ... point.1
            let dadGenom = dad.chromosome[range]
            let mumGenom = mum.chromosome[range]
            son.chromosome[range] = mumGenom
            daughter.chromosome[range] = dadGenom
        }
        return (son, daughter)
    }
}

extension Individual {
    
    
    private mutating func replacement(upperBound: Int) {
        let newValue: Double = Int.arc4random_uniform_d(upperBound) + Double.arc4random_uniform(101) / 100
        
        let atIndex = Int.arc4random_uniform(self.chromosome.count)
        self.chromosome[atIndex] = newValue
    }
    
    private mutating func removeal() {
        let atIndex = Int.arc4random_uniform(self.chromosome.count)
        self.chromosome[atIndex] = 0
    }
    
    private mutating func randomSwap() {
        let upperBound = self.chromosome.count
        let left = Int.arc4random_uniform(upperBound)
        var right = Int.arc4random_uniform(upperBound)
        if left == right {
            right = left > 0 ? left - 1 : left + 1
        }
        let current = self.chromosome
        let p = current[left]
        self.chromosome[left] = self.chromosome[right]
        self.chromosome[right] = p
        
    }
    
     private mutating func adjacentSwap() {
        let left = Int.arc4random_uniform(self.chromosome.count)
        let right: Int
        if left < self.chromosome.count - 1 {
            right = left + 1
        } else {
            right = left - 1
        }
        let current = self.chromosome
        let p = current[left]
        self.chromosome[left] = self.chromosome[right]
        self.chromosome[right] = p
        
    }
    
    private mutating func endForEndSwap() {
        
        let swapPoint = self.chromosome.count / 2
        let swapEnd = self.chromosome.count % 2 == 0 ? self.chromosome.count : self.chromosome.count - 1
        let firstHalf = self.chromosome[0 ..< swapPoint]
        self.chromosome[0 ..< swapPoint] = self.chromosome[swapPoint ..< swapEnd]
        self.chromosome[swapPoint ..< swapEnd] = firstHalf
    }
    
    mutating func mutate(withMethod method: Mutation.Method) {
        switch method {
        case .adjacentSwap:
            adjacentSwap()
        case .endForEndSwap:
            endForEndSwap()
        case .randomSwap:
            randomSwap()
        case .removeal:
            removeal()
        case .replacement(let bound):
            replacement(upperBound: bound)
        }
    }
    
}

func replacement(_ buff: inout [Double], upperBound: Int) {
    let newValue: Double = Int.arc4random_uniform_d(upperBound) + Double.arc4random_uniform(101) / 100
    
    let atIndex = Int.arc4random_uniform(buff.count)
    buff[atIndex] = newValue
}

func removeal(_ buff: inout [Double]) {
    let atIndex = Int.arc4random_uniform(buff.count)
    buff[atIndex] = 0
}

func randomSwap(_ buff: inout [Double]) {
    
    let upperBound = buff.count
    let left = Int.arc4random_uniform(upperBound)
    var right = Int.arc4random_uniform(upperBound)
    if left == right {
        right = left > 0 ? left - 1 : left + 1
    }
    let current = buff
    let p = current[left]
    buff[left] = buff[right]
    buff[right] = p
    
}

func adjacentSwap(_ buff: inout [Double]) {
    
    let left = Int.arc4random_uniform(buff.count)
    let right: Int
    if left < buff.count - 1 {
        right = left + 1
    } else {
        right = left - 1
    }
    let current = buff
    let p = current[left]
    buff[left] = buff[right]
    buff[right] = p
    
}

func endForEndSwap(_ buff: inout [Double]) {
    
    let swapPoint = buff.count / 2
    let swapEnd = buff.count % 2 == 0 ? buff.count : buff.count - 1
    let firstHalf = buff[0 ..< swapPoint]
    buff[0 ..< swapPoint] = buff[swapPoint ..< swapEnd]
    buff[swapPoint ..< swapEnd] = firstHalf
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
    
    static func random(maxPostitionValue: Int, positionSize: Int) -> () -> Particle {
        return {
            var randomPosition: [Double] = []
    //        for _ in 0..<input[0].gene.count {
            for _ in 0 ..< positionSize {
                randomPosition.append(Int.arc4random_uniform_d(maxPostitionValue + 1))
            }

            let velocity: [Double] = randomPosition.map {_ in
                return Int.arc4random_uniform_d(2 * maxPostitionValue + 1) - Double(maxPostitionValue)
            }
            return Particle(position: randomPosition, velocity: velocity)
        }
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

struct ParticleNNetIndividual: NNetwork, Indv {
    var fitness: Double = -1
    var bestPosition: ([Double], sizes: [NNetworkSizeStructure])? = nil
    var bias: [[Double]] = []
    var weights: [[[Double]]] = []
    var velocity: [Double] = []
    var numLayers: Int = 0
    
    init() {
        
    }
    
    mutating func postInitSetup() {
        bestPosition = vector
        velocity = bestPosition!.0.map { _ in
            return Int.arc4random_uniform_d(2 * 100 + 1) - 100 // TODO TMP
        }
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
    func rawFunction<T: VectorRepresentable>() -> ([T], [([Double], [Double])]) -> [Double] {
        switch self {
        case .rmst:
            return fitness_rmst()
        }
    }
    
}

func rmse(_ data: [(result: Double, expected: Double)]) -> Double {
    var mean: Double = 0
    for d in data {
        mean += pow(d.result - d.expected, 2)
    }
    return sqrt((1 / Double(data.count)) * mean )
}

func fitness_rmst<T: VectorRepresentable>() -> ([T], [([Double], [Double])]) -> [Double] {
    return { (individuals, pairs) in
        var results: [Double] = [Double](repeating: 0, count: individuals.count)
        
        
        for pair in pairs {
            let currentInput = pair.0
            for individual in individuals{
                var result: Double = 0
                
                for (gene, val) in zip(currentInput, individual.value) {
                    result += gene * val
                }
                if individual.value.count > currentInput.count {
                    individual.value[currentInput.count ..< individual.value.count].forEach {
                        result += $0
                    }
                    
                }
                
                for (index, output) in pair.1.enumerated() {
                    results[index] += pow(output - result, 2)
                }
                
            }
        }
        return results.map { mean in
            sqrt((1 / Double(pairs.count)) * mean)
        }
    }
}

func fitness_rmst() -> ([[Double]], [([Double], [Double])]) -> [Double] {
    return { (individuals, pairs) in
        var results: [Double] = [Double](repeating: 0, count: individuals.count)
        
        
        for pair in pairs {
            let currentInput = pair.0
            for individual in individuals{
                var result: Double = 0
                
                for (gene, val) in zip(currentInput, individual) {
                    result += gene * val
                }
                if individual.count > currentInput.count {
                    individual[currentInput.count ..< individual.count].forEach {
                        result += $0
                    }
                    
                }
                
                for (index, output) in pair.1.enumerated() {
                    results[index] += pow(output - result, 2)
                }
                
            }
        }
        return results.map { mean in
            sqrt((1 / Double(pairs.count)) * mean)
        }
    }
}

fileprivate func fitness_rmst<T: VectorRepresentable>() -> (T, [([Double], Double)]) -> Double {
    return { individual, input in
        var mean: Double = 0
        
        for i in 0..<input.count {
            let current = input[i]
            var result: Double = 0
            
            for (gene, val) in zip(current.0, individual.value) {
                result += gene * val
            }
            if individual.value.count > current.0.count {
                individual.value[current.0.count ..< individual.value.count].forEach {
                    result += $0
                }
                
            }
            result = pow(current.1 - result, 2)
            mean += result
        }
        
        return sqrt((1 / Double(input.count)) * mean)
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
            if individual.value.count > current.gene.count {
                individual.value[current.gene.count ..< individual.value.count].forEach {
                    result += $0
                }
                
            }
            result = pow(current.expectedResult - result, 2)
            mean += result
        }
        
        return sqrt((1 / Double(input.count)) * mean)
    }
}

