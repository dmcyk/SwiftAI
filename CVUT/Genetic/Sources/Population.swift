//
//  Population.swift
//  Genetic
//
//  Created by Damian Malarczyk on 28.10.2016.
//
//

import Foundation

enum EvolutionMethod {
    case random, genetic
}

struct EvolutionResult<T: Indv> {
    var newPopulation: [T]
    var best: T
}

protocol GenericPopulation {
    mutating func generateResults(forIterations: Int) -> (bestFitness: Double, fitnessCount: Int)
    mutating func generateDetailedResults(forIterations: Int) -> (bestFitness: Double, worstFitness: Double, averageFitness: Double, fitnessCount: Int)
    mutating func initializePopulation(withSize size: Int)
}

protocol EvolutionAlgorithm {
    associatedtype Member: Indv, VectorRepresentable
    
    /// isBetter:, than:
    typealias FitnessComparisonFunction = (Member, Member) -> Bool
    typealias FitnessFunction = ((Member, [InputData]) -> Double)
    var fitnessCounter: Int { get }
    var fitnessOptimization: FitnessComparisonFunction { get }
    func evolve(forInput input: [InputData], currentPopulation: [Member], currentBest: Member) -> EvolutionResult<Member>
    func evaluateFitness(_ member: Member, input: [InputData]) -> Double
    func initializePopulation(withSize size: Int, forInput input: [InputData]) -> [Member]
}


struct Population<T: EvolutionAlgorithm>: GenericPopulation {

    private(set) var individuals: [T.Member]
    let size: Int
    let evolver: T
    let input: [InputData]
    
    private(set) var bestIndividual: T.Member!

    init?(withInput input: [InputData], size: Int, evolutionAlgorithm: T) {
        guard size > 0 else {
            return nil
        }
        self.input = input
        self.size = size
        self.evolver = evolutionAlgorithm
        self.individuals = []
        self.bestIndividual = nil
        self.initializePopulation(withSize: size)
        
        
    }
    
    mutating func generateResults(forIterations iterations: Int) -> (bestFitness: Double, fitnessCount: Int) {
        let best = evolve(times: iterations)
        return (best.fitness, evolver.fitnessCounter)
    }
    
    mutating func generateDetailedResults(forIterations iterations: Int) -> (bestFitness: Double, worstFitness: Double, averageFitness: Double, fitnessCount: Int) {
        guard individuals.count > 0 else {
            fatalError("Results for empty population cant be generated")
        }
        let res = generateResults(forIterations: iterations)
        var worst = individuals[0]
        var average: Double = worst.fitness
        
        for indx in 1 ..< individuals.count {
            let element = individuals[indx]
            
            if evolver.fitnessOptimization(worst, element) {
                worst = element
            }
            average += element.fitness
            
        }
        
        average /= Double(individuals.count)
        
        return (bestFitness: res.bestFitness, worstFitness: worst.fitness, averageFitness: average, fitnessCount: res.fitnessCount)
    }

    mutating func initializePopulation(withSize size: Int) {
        self.individuals = evolver.initializePopulation(withSize: size, forInput: input)
        
        if individuals.count > 1 {
            var best = individuals[0]
            
            for individual in individuals.suffix(from: 1) {
                if evolver.fitnessOptimization(individual, best) {
                    best = individual
                }
            }
            bestIndividual = best
        } else {
            bestIndividual = individuals[0]
        }

    }
    
    @discardableResult
    mutating func evolve() -> T.Member {
        
        let resultOfEvolution = evolver.evolve(forInput: input, currentPopulation: individuals, currentBest: bestIndividual)
        individuals = resultOfEvolution.newPopulation
        bestIndividual = resultOfEvolution.best
        return resultOfEvolution.best
        
    }
    
    @discardableResult
    mutating func evolve(times: Int, printFittest: Bool = false, printRepetition: Bool = false) -> T.Member {
        var best: T.Member = bestIndividual
        var times = times
        var previousFitness: Double = 1
        while times > 0 {
            best = evolve()
            if printFittest {
                if printRepetition || previousFitness != best.fitness {
                    print(best.fitness)
                }
            }
            previousFitness = best.fitness
            times -= 1
        }
        return best
    }
    
}

extension Array where Element: Comparable {
    func max() -> Element? {
        guard !self.isEmpty else {
            return nil
        }
        var best = self[0]
        
        for element in self {
            if element > best {
                best = element
            }
        }
        return best
    }
    
    func min() -> Element? {
        guard !self.isEmpty else {
            return nil
        }
        var best = self[0]
        
        for element in self {
            if element < best {
                best = element
            }
        }
        return best
    }
}

