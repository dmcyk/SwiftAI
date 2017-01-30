//
//  Particle.swift
//  Task2
//
//  Created by Damian Malarczyk on 17.11.2016.
//
//

import Foundation

class ParticleEvolver: EvolutionAlgorithm {
    
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
    
    typealias Member = Particle
    typealias FitnessFunction = ((Member, [InputData]) -> Double)
    
    var fitnessCounter: Int = 0
    var bestKnown: Particle! = nil
    var fitnessOptimization: (Particle, Particle) -> Bool
    let maxPostitionValue: Int
    let fitnessFunction: FitnessFunction
    var parameters: Parameters
    
    init(parameters: Parameters, maxPostitionValue: Int, fitnessFunction: @escaping FitnessFunction, fitnessOptimization: @escaping (Particle, Particle) -> Bool) {
        self.fitnessFunction = fitnessFunction
        self.parameters = parameters
        self.maxPostitionValue = maxPostitionValue
        self.fitnessOptimization = fitnessOptimization
    }
    
    func initializePopulation(withSize size: Int, forInput input: [InputData]) -> [Particle] {
        var pop = [Particle]()
        fitnessCounter = 0
        
        var bestParticle: Particle? = nil
        for _ in 0 ..< size {
            var randomPosition: [Double] = []
            for _ in 0..<input[0].gene.count {
                randomPosition.append(Int.arc4random_uniform_d(maxPostitionValue + 1))
            }
            
            let velocity: [Double] = randomPosition.map {_ in
                return Int.arc4random_uniform_d(2 * maxPostitionValue + 1) - Double(maxPostitionValue)
            }
            var particle = Particle(position: randomPosition, velocity: velocity)
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
    
    func evaluateFitness(_ member: Particle, input: [InputData]) -> Double {
        fitnessCounter += 1
        return fitnessFunction(member, input)
    }
    
    func evolve(forInput input: [InputData], currentPopulation: [Particle], currentBest: Particle) -> EvolutionResult<Particle> {
        
        var best: Particle = bestKnown
        var newPopulation: [Particle] = currentPopulation.map { particle -> (Particle) in
            var new = particle
            
            let alphaAndBetaResult: [Double] = zip(particle.bestPosition, particle.position).enumerated().map { index, elements in
                let alpha = Double.arc4random_uniform(99) / 100 + 0.01
                let beta = Double.arc4random_uniform(99) / 100 + 0.01
                let left = (elements.0 - elements.1) * parameters.delta1 * alpha
                let right = (best.bestPosition[index] - elements.1) * parameters.delta2 * beta
                return left + right
            }
            var newPosition: [Double] = []
            var newVelocity: [Double] = []
            
            zip(particle.velocity, alphaAndBetaResult).enumerated().forEach { index, elements in
                let newV = elements.0 * parameters.omega + elements.1
                
                newPosition.append(particle.position[index] + newV)
                newVelocity.append(newV)
            }
            
            new.velocity = newVelocity
            new.position = newPosition
            
            new.fitness = evaluateFitness(new, input: input)
            
            if fitnessOptimization(new, particle) {
                new.bestPosition = new.position
            }
            
            if fitnessOptimization(new, best) {
                best = new
            }
            
            return new
        }
        
        newPopulation[0] = best
        bestKnown = best
        return EvolutionResult(newPopulation: newPopulation, best: best)
    }

    
}
