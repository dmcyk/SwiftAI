//
//  Random.swift
//  Genetic
//
//  Created by Damian Malarczyk on 17.11.2016.
//
//

import Foundation

class RandomEvolver: EvolutionAlgorithm {
    typealias Member = Individual
    typealias FitnessComparisonFunction = (Member, Member) -> Bool
    typealias FitnessFunction = ((Member, [InputData]) -> Double)
    
    let maxChromosomeValue: Int
    let fitnessFunction: FitnessFunction
    let fitnessOptimization: FitnessComparisonFunction
    var fitnessCounter: Int = 0
    
    init(maxChromosomeValue: Int, fitnessFunction: @escaping FitnessFunction, fitnessOptimization: @escaping FitnessComparisonFunction) {
        
        self.maxChromosomeValue = maxChromosomeValue
        self.fitnessFunction = fitnessFunction
        self.fitnessOptimization = fitnessOptimization
        
    }
    
    func initializePopulation(withSize size: Int, forInput input: [InputData]) -> [Individual] {
        var pop = [Individual]()
        fitnessCounter = 0
        for _ in 0 ..< size {
            var randomChromosome: [Double] = []
            for _ in 0..<input[0].gene.count {
                randomChromosome.append(Int.arc4random_uniform_d(maxChromosomeValue + 1))
            }
            var individual = Individual(chromosome: randomChromosome)
            individual.fitness = evaluateFitness(individual, input: input)
            pop.append(individual)
        }
        return pop
    }
    
    func evaluateFitness(_ member: Individual, input: [InputData]) -> Double {
        fitnessCounter += 1
        return fitnessFunction(member, input)
    }
    
    func evolve(forInput input: [InputData], currentPopulation: [Individual], currentBest: Individual) -> EvolutionResult<Individual> {
        var newPopulation = [currentBest]
        var newBest = currentBest
        for _ in 1 ..< currentPopulation.count {
            var newChromosome = [Double]()
            for _ in 0 ..< currentBest.chromosome.count {
                newChromosome.append(Int.arc4random_uniform_d(maxChromosomeValue) + Double.arc4random_uniform(101) / 100)
            }
            var indv = Individual(chromosome: newChromosome)
            indv.fitness = evaluateFitness(indv, input: input)
            
            if fitnessOptimization(indv, newBest) {
                newBest = indv
            }
            
            newPopulation.append(indv)
        }
        return EvolutionResult(newPopulation: newPopulation, best: newBest)
    }
    
}
