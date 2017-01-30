//
//  Particle+optiumum.swift
//  Task2
//
//  Created by Damian Malarczyk on 17.11.2016.
//
//

import Foundation

extension ParticleNetworkEvolver {
    
    
    static func calculateBest(input: [InputData], size: Int, iterations: Int, min minVal: Double, max maxVal: Double, increment: Double, maxPositionValue: Int) -> [Double] {
        guard increment >= 0.02 else {
            return []
        }
        var startOmega = minVal
        
        var results: [([Double], Double)] = []
        let opQueue = OperationQueue()
        
        let syncQueue = OperationQueue()
        syncQueue.maxConcurrentOperationCount = 1
        
        while startOmega <= maxVal && startOmega < 1 {
            print("Optimum next step")
            let omegaVal = startOmega
            
            opQueue.addOperation {
                let omega = omegaVal
                var best = Double(Int.max)
                var delta1 = minVal
                var result: [Double] = [minVal, minVal, minVal]
                var delta2 = minVal
                while delta1 <= maxVal {
                    while delta2 <= maxVal {
                        var pop3 = Population(withInput: input, size: size, evolutionAlgorithm: ParticleNetworkEvolver.init(parameters: ParticleNetworkEvolver.Parameters(omega: omega, delta1: delta1, delta2: delta2), fitnessFunction: { (member, input) -> Double in
                            let cmp = input.map { current -> (Double, Double) in
                                let feed = member.feedforward(acc: current.gene)[0]
                                return (feed, current.expectedResult)
                            }
                            return rmse(cmp)
                        }, fitnessOptimization: <), newInstanceFunction: {
                            return ParticleNNetIndividual.random(neurons: [input[0].gene.count, 8, 6, 1], maxValue: 100)
                        })
                        
                        
                        let x = pop3!.generateResults(forIterations: iterations)
                        if x.bestFitness < best {
                            best = x.bestFitness
                            result[0] = omega
                            result[1] = delta1
                            result[2] = delta2
                        }
                        
                        delta2 += increment
                    }
                    
                    delta1 += increment
                    delta2 = minVal
                }
                syncQueue.addOperation {
                    results.append((result, best))
                }
                syncQueue.waitUntilAllOperationsAreFinished()
                print("Optimum finished step")
                
            }
            startOmega += increment
        }
        opQueue.waitUntilAllOperationsAreFinished()
        print("Optimum finished")
        var best = Double(Int.max)
        var bestIndx: Int = 0
        for (indx, queueResult) in results.enumerated() {
            if queueResult.1 < best {
                bestIndx = indx
                best = queueResult.1
            }
        }
        
        let result = results[bestIndx].0
        
        var minVal = min(min(result[0], result[1]), result[2])
        var maxVal = max(max(result[0], result[1]), result[2])
        if (minVal - increment / 2) > 0 {
            minVal -= increment / 2
        }
        if (maxVal + increment / 2) < 1 {
            maxVal += increment / 2
        }
        
        let better = calculateBest(input: input, size: size, iterations: iterations, min: minVal, max: maxVal, increment: increment / 2, maxPositionValue: maxPositionValue)
        guard !better.isEmpty else {
            return result
        }
        return better
    }
    
    
}
