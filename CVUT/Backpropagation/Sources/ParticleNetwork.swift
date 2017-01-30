//
//  ParticleNetwork.swift
//  Task2
//
//  Created by Damian Malarczyk on 17.11.2016.
//
//

import Foundation

class ParticleNetworkEvolver: EvolutionAlgorithm {
    
    struct Parameters {
        let omega: Double
        let delta1: Double
        let delta2: Double
        
        var string: String {
            let str = [omega,delta1, delta2].map {
                String($0)
            }
            return str.joined(separator: " ")
        }
        
        init(omega: Double, delta1: Double, delta2: Double) {
            self.omega = omega
            self.delta1 = delta1
            self.delta2 = delta2
        }
        
        init?(str: String) {
            let cmp = str.components(separatedBy: " ")
            
            let doubles = cmp.flatMap {
                Double($0)
            }
            
            guard doubles.count == 3 else {
                return nil
            }
            self.init(omega: doubles[0], delta1: doubles[1], delta2: doubles[2])
            
            
        }
    }
    
    typealias Member = ParticleNNetIndividual
    typealias Input = [InputData]
    typealias FitnessFunction = ((Member, [InputData]) -> Double)
    
    var fitnessCounter: Int = 0
    var bestKnown: Member! = nil
    var fitnessOptimization: (Member, Member) -> Bool
    let fitnessFunction: FitnessFunction
    var parameters: Parameters
    
    init(parameters: Parameters, fitnessFunction: @escaping FitnessFunction, fitnessOptimization: @escaping (Member, Member) -> Bool) {
        self.fitnessFunction = fitnessFunction
        self.parameters = parameters
        self.fitnessOptimization = fitnessOptimization
    }
    
    func initializePopulation(withSize size: Int, forInput input: [InputData], newInstance: () -> Member) -> [Member] {
        var pop = [Member]()
        fitnessCounter = 0
        
        var bestParticle: Member? = nil
        for _ in 0 ..< size {
            
            var particle = newInstance()
            particle.fitness = evaluateFitness(particle, input: input)
            if let b = bestParticle {
                if fitnessOptimization(particle, b) {
                    bestParticle = particle
                }
            } else {
                bestParticle = particle
            }
            pop.append(particle)
        }
        bestKnown = bestParticle!
        
        return pop
    }
    
    func evaluateFitness(_ member: Member, input: [InputData]) -> Double {
        fitnessCounter += 1
        return fitnessFunction(member, input)
    }
    
    func evolve(forInput input: Input, currentPopulation: [Member], currentBest: Member, maxFitness: Double) -> (EvolutionResult<Member>, maxFitness: Double) {
        
        var best: Member = bestKnown
        var maxFitness: Double = DBL_MIN
        var newPopulation: [Member] = currentPopulation.map { particle -> (Member) in
            var new = particle
            var raw = particle.vector
            var bestRaw = best.bestPosition!
            
            let alphaAndBetaResult: [Double] = zip(particle.bestPosition!.0, raw.0).enumerated().map { index, elements in
                let alpha = Double.arc4random_uniform(99) / 100 + 0.01
                let beta = Double.arc4random_uniform(99) / 100 + 0.01
                let left = (elements.0 - elements.1) * parameters.delta1 * alpha
                let right = (bestRaw.0[index] - elements.1) * parameters.delta2 * beta
                return left + right
            }
            var newPosition: [Double] = []
            var newVelocity: [Double] = []
            
            zip(particle.velocity, alphaAndBetaResult).enumerated().forEach { index, elements in
                let newV = elements.0 * parameters.omega + elements.1
                
                newPosition.append(raw.0[index] + newV)
                newVelocity.append(newV)
            }
            
            new.velocity = newVelocity
            (new.bias, new.weights) = ParticleNNetIndividual.extract(vector: newPosition, structure: bestRaw.sizes)
            
            new.fitness = evaluateFitness(new, input: input)
            
            if fitnessOptimization(new, particle) {
                new.bestPosition = (newPosition, raw.sizes)
            }
            
            if fitnessOptimization(new, best) {
                best = new
            }
            if new.fitness > maxFitness {
                maxFitness = new.fitness
            }
            
            return new
        }
        
        newPopulation[0] = best
        bestKnown = best
        return (EvolutionResult(newPopulation: newPopulation, best: best), maxFitness: maxFitness)
    }
    
    
}
