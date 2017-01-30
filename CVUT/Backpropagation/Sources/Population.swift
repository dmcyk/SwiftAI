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
    mutating func initializePopulation(withSize size: Int)
    mutating func evolve() -> Double
    var best: Double { get }
}

protocol EvolutionAlgorithm {
    associatedtype Member: Indv
    associatedtype Input
    /// isBetter:, than:
    typealias FitnessComparisonFunction = (Member, Member) -> Bool
    typealias FitnessFunction = ((Member, Input) -> Double)
    var fitnessCounter: Int { get }
    var fitnessOptimization: FitnessComparisonFunction { get }
    func evolve(forInput input: Input, currentPopulation: [Member], currentBest: Member, maxFitness: Double) -> (EvolutionResult<Member>, maxFitness: Double)
    func evaluateFitness(_ member: Member, input: Input) -> Double
    func initializePopulation(withSize size: Int, forInput input: Input, newInstance: () -> Member) -> [Member]
}


struct GradientPopulation: GenericPopulation {
    var neurons: [Int]
    var maxValue: Double
    var best: Double  {
        return optimalNetwork.fitness
    }
    let input: [([Double], [Double])]
    let epochs: Int
    let eta: Double
    let momentum: Double
    
    private var stuckLocalOptimum = 0
    
    private var network: GradientNNetwork! {
        didSet {
            if network.fitness < optimalNetwork.fitness {
                optimalNetwork = network
            } else {
                stuckLocalOptimum += 1
                if stuckLocalOptimum > 10 && network.eta >= 0.06 {
                    stuckLocalOptimum = 0
                    network.eta -= 0.05
                }
            }
        }
    }
    private var optimalNetwork: GradientNNetwork!
    
    mutating func evolve() -> Double {
        _ = network.learn(data: input, epochs: epochs)
        return best 
    }

    mutating func initializePopulation(withSize size: Int) {
        var candidates = [GradientNNetwork]()
        
        for _ in 0 ..< size {
            var net = GradientNNetwork.random(neurons: neurons, maxValue: maxValue)
            net.eta = eta
            net.momentum = momentum
            net.fitness = rmse(input.map {
                (result: net.feedforward(acc: $0.0)[0], expected: $0.1[0])
            })
            candidates.append(net)
            
        }
        network = candidates.min(by: { (lhs, rhs) -> Bool in
            lhs.fitness < rhs.fitness
        })!
        optimalNetwork = network
        
    }
    
    init(neurons: [Int], maxValue: Double, epochs: Int, momentum: Double, eta: Double, input: [([Double], [Double])]) {
        self.neurons = neurons
        self.maxValue = maxValue
        self.input = input
        self.epochs = epochs
        self.eta = eta
        self.momentum = momentum
    
    }
    
}

struct Population<T: EvolutionAlgorithm>: GenericPopulation {

    private(set) var individuals: [T.Member]
    private(set) var size: Int
    private var maxFitness: Double = -1
    let evolver: T
    let input: T.Input
    let newInstance: () -> T.Member
    
    var best: Double {
        return bestIndividual.fitness
    }
    
    private(set) var bestIndividual: T.Member!

    init?(withInput input: T.Input, size: Int, evolutionAlgorithm: T, newInstanceFunction: @escaping () -> T.Member) {
        guard size > 0 else {
            return nil
        }
        self.input = input
        self.size = size
        self.evolver = evolutionAlgorithm
        self.individuals = []
        self.bestIndividual = nil
        self.newInstance = newInstanceFunction
        self.initializePopulation(withSize: size)
    }
    
    init?(withInput input: T.Input, initialPopulation: [T.Member], evolutionAlgorithm: T, newInstanceFunction: @escaping () -> T.Member) {
        guard !initialPopulation.isEmpty else {
            return nil
        }
        self.input = input
        self.evolver = evolutionAlgorithm
        self.individuals = []
        self.bestIndividual = nil
        self.individuals = initialPopulation
        self.size = initialPopulation.count
        self.newInstance = newInstanceFunction
        setupPopulation()
        
        
    }
    
    mutating func generateResults(forIterations iterations: Int) -> (bestFitness: Double, fitnessCount: Int) {
        let best = evolve(times: iterations)
        return (best.fitness, evolver.fitnessCounter)
    }

    mutating func initializePopulation(withSize size: Int) {
        self.individuals = evolver.initializePopulation(withSize: size, forInput: input, newInstance: newInstance)
        setupPopulation()

    }
    
    mutating func expand(bySize size: Int) {
        self.individuals.append(contentsOf: evolver.initializePopulation(withSize: size, forInput: input, newInstance: newInstance))
        self.size = individuals.count
        setupPopulation()
    }
    
    mutating private func setupPopulation() {
        if individuals.count > 1 {
            var best = individuals[0]
            var maxFit = best.fitness
            for individual in individuals.suffix(from: 1) {
                if evolver.fitnessOptimization(individual, best) {
                    best = individual
                }
                if individual.fitness > maxFit {
                    maxFit = individual.fitness
                }
            }
            maxFitness = maxFit
            bestIndividual = best
        } else {
            bestIndividual = individuals[0]
        }
    }
    
    @discardableResult
    mutating func evolve() -> T.Member {
        
        let resultOfEvolution = evolver.evolve(forInput: input, currentPopulation: individuals, currentBest: bestIndividual, maxFitness: maxFitness)
        individuals = resultOfEvolution.0.newPopulation
        bestIndividual = resultOfEvolution.0.best
        maxFitness = resultOfEvolution.maxFitness
        return resultOfEvolution.0.best
        
    }
    
    mutating func evolve() -> Double {
        return evolve().fitness
    }
    
    @discardableResult
    mutating func evolve(times: Int) -> T.Member {
        var best: T.Member = bestIndividual
        var times = times
        while times > 0 {
            best = evolve()
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

