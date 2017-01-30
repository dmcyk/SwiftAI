//
//  Genetic.swift
//  Genetic
//
//  Created by Damian Malarczyk on 17.11.2016.
//
//

import Foundation



class GeneticEvolver: EvolutionAlgorithm {
    typealias Member = Individual
    typealias FitnessComparisonFunction = (Member, Member) -> Bool
    typealias FitnessFunction = ((Member, [InputData]) -> Double)
    
    var fitnessCounter: Int = 0
    let fitnessOptimization: FitnessComparisonFunction
    let fitnessFunction: FitnessFunction
    let maxChromosomeValue: Int
    let mutationProbability: Double
    private(set) var activeMutationMethods: [Mutator.Method] = []
    
    private var mutatorMethod: Mutator.Method {
        let random = Int.boxMullerRandom(activeMutationMethods.count - 1)
        return activeMutationMethods[random.0]
    }
    
    
    init(maxChromosomeValue: Int, mutationProbability: Double, fitnessFunction: @escaping FitnessFunction, fitnessOptimization: @escaping FitnessComparisonFunction) {
        self.fitnessOptimization = fitnessOptimization
        self.maxChromosomeValue = maxChromosomeValue
        self.fitnessFunction = fitnessFunction
        self.mutationProbability = mutationProbability
        
        activeMutationMethods.append(.adjacentSwap)
        activeMutationMethods.append(.removeal)
        activeMutationMethods.append(.replacement(upperBound: Int(maxChromosomeValue + 1)))
        activeMutationMethods.append(.randomSwap)
        activeMutationMethods.append(.endForEndSwap)
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
    
    private func selection(_ individuals: [Individual]) -> [Individual] {
        
        let averages = individuals.sorted() {
            $0.0.fitness > $0.1.fitness
        }
        var selected = [averages.last!]
        
        let doubleCount = Double(averages.count)
        for x in averages.enumerated() {
            let random = Double.arc4random_uniform(101) / 100
            if random <= Double(x.offset) / doubleCount {
                selected.append(x.element)
            }
        }
        
        return selected
    }
    
    
    
    private func crossover(fromIndividuals parents: [Individual], upTo: Int, input: [InputData]) -> [Individual] {
        var extended: [Individual] = Array<Individual>(parents)
        var indx = 0
        while extended.count < upTo {
            
            let dadIndx = indx
            indx += 1
            
            var mumIndx = dadIndx + 1
            if mumIndx == parents.count {
                mumIndx = 0
                indx = 0
            }
            
            let dad = parents[Int(dadIndx)]
            let mum = parents[Int(mumIndx)]
            
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
            son.fitness = fitnessFunction(son, input)
            daughter.fitness = fitnessFunction(daughter, input)
            
            let best = [dad, mum, son, daughter].sorted() {
                $0.0.fitness < $0.1.fitness
            }
            for element in best.prefix(2) {
                if extended.count < upTo {
                    extended.append(element)
                }
            }
            
        }
        return extended
    }
    
    
    private func mutate(individuals: inout [Individual]) {
        
        for x in 0 ..< individuals.count {
            let method = mutatorMethod
            let mutation = method.mutation()
            
            individuals[x] = mutation(individuals[x])
            
        }
    }
    
    internal func evaluateFitness(_ member: Individual, input: [InputData]) -> Double {
        fitnessCounter += 1
        return fitnessFunction(member, input)
    }
    
    internal func evolve(forInput input: [InputData], currentPopulation: [Individual], currentBest: Individual) -> EvolutionResult<Individual> {
        var newIndividuals = selection(currentPopulation)
        var elite = newIndividuals[0]
        elite.fitness = evaluateFitness(elite, input: input)
        newIndividuals = crossover(fromIndividuals: newIndividuals, upTo: currentPopulation.count - 1, input: input)
        if Double.arc4random_uniform(10) / 10 < mutationProbability {
            mutate(individuals: &newIndividuals)
        }
        
        var best = elite
        
        newIndividuals = newIndividuals.map {
            var new = $0
            new.fitness = evaluateFitness(new, input: input)
            
            if fitnessOptimization(new, best) {
                best = new
            }
            return new
        }
        newIndividuals.append(elite)
        return EvolutionResult(newPopulation: newIndividuals, best: best)
    }
    
    
}
