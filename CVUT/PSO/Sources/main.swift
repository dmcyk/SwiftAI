//
//  main.swift
//  Genetic
//
//  Created by Damian Malarczyk on 28.10.2016.
//
//


import Foundation
import Utils
import Console

class PSOParameters: Command {
    var name: String = "psoparameters"
    
    var parameters: [CommandParameter] = [
        .argument(Argument("source", expectedValue: .string, description: "Path to source file")),
        .option(Option("sourceId",  description: "Source identifier - necessary when using PSO cache, if not given found parameters will just be printed", mode: .value(expected: .string, default: nil))),
        .option(Option("cache", description: "Path to folder with PSO parameteres cache, if not given parameters will just be printed", mode: .value(expected: .string, default: nil))),
        .option(Option("size", description: "Size of populations", mode: .value(expected: .int, default: .int(100)))),
        .option(Option("iterations", description: "Amount of algorithms generations/iterations", mode: .value(expected: .int, default: .int(100)))),
        .option(Option("position", description: "Maximum value that individuals may have", mode: .value(expected: .int, default: .int(500)))),
        .option(Option("repeats", description: "Amount of algorithms repetitions to improve results accuray", mode: .value(expected: .int, default: .int(5))))

    ]
    
    func run(data: CommandData) throws {
        let src = try data.value("source").stringValue()
        let srcId = try data.optionalValue("sourceId")?.stringValue()
        let input =  try forestFiresInput(sourcePath: src)
        let _cache = try data.optionalValue("cache")?.stringValue()
        let size = try data.optionalValue("size")!.intValue()
        let iterations = try data.optionalValue("iterations")!.intValue()
        let position = try  data.optionalValue("position")!.intValue()
        let repeats = try data.optionalValue("repeats")!.intValue()
        
        print("\nRunning with configuration: \n\tsource: \(src)\n\tsize: \(size)\n\titerations: \(iterations)\n\tposition: \(position)\n\trepeats \(repeats)")
        if _cache != nil && srcId != nil {
            print("\tcache: \(_cache!)\n\tsourceId: \(srcId!)")
        }
        var results: [Double] = [0, 0, 0]
        for i in 0 ..< repeats {
            zip(results, ParticleEvolver.calculateBest(input: input, size: size, iterations: iterations, min: 0.01, max: 0.99, increment: 0.3, maxPositionValue: position)).enumerated().forEach {
                results[$0.offset] = $0.element.0 + $0.element.1
            }
            print("Progres: \(i + 1)/\(repeats)")
        }
        results = results.map {
            $0 / Double(repeats)
        }
        let params = ParticleEvolver.Parameters.init(omega: results[0], delta1: results[1], delta2: results[2])
        
        if let cache = _cache, let id = srcId {
            let entry = ParticleEvolver.Cache.Entry.init(inputId: id, size: size, iterations: iterations, maxPositionValue: position)
            try ParticleEvolver.Cache(path: cache).cache(parameters: params, entry: entry)
        } else {
            print()
            dump(params)
            print()
        }
        print("Finished with success\n")


    }
}

class Generate: Command {
    var name: String = "generate"
    
    enum Error: Swift.Error {
        case noCacheNorParameters
        case noCacheEntryFound
        case incorrectParameters
        case populationInitializationError
        case missingSourceId
    }
    
    
    var parameters: [CommandParameter] = [
        .argument(Argument("source", expectedValue: .string, description: "Path to source file")),
        .argument(Argument("size", expectedValue: .int, description: "Size of populations")),
        .argument(Argument("iterations", expectedValue: .int, description: "Amount of algorithms generations/iterations")),
        .argument(Argument("result", expectedValue: .string, description: "Path to folder for storing measurements")),
        .option(Option("sourceId",  description: "Source identifier - necessary when using PSO cache", mode: .value(expected: .string, default: nil))),
        .option(Option("cache", description: "Path to folder with PSO parameteres cache", mode: .value(expected: .string, default: nil))),
        .option(Option("parameters", description: "PSO parameters array - 3 values", mode: .value(expected: .array(.double), default: nil))),
        .option(Option("position", description: "Maximum value that individuals may have", mode: .value(expected: .int, default: .int(500)))),
        .option(Option("repeats", description: "Amount of algorithms repetitions to improve results accuray", mode: .value(expected: .int, default: .int(5)))),
        .option(Option("pso", mode: .flag)),
        .option(Option("genetic", mode: .flag)),
        .option(Option("random", mode: .flag))
        
    ]
    
    struct DataGenerator {
        var population: GenericPopulation
        var name: String
        var entries: [(String, [Int: Double])]
    }
    
    func run(data: CommandData) throws {
        let _cache = try data.optionalValue("cache")?.stringValue()
        let rawParameters = try data.optionalValue("parameters")?.arrayValue().map {
            try $0.doubleValue()
        }
        let srcId = try data.optionalValue("sourceId")?.stringValue()
        let src = try data.value("source").stringValue()
        let input =  try forestFiresInput(sourcePath: src)
        let size = try data.value("size").intValue()
        
        let iterations = try data.value("iterations").intValue()
        let position = try  data.optionalValue("position")!.intValue()
        
        let pso = try data.flag("pso")
        let genetic = try data.flag("genetic")
        let random = try data.flag("random")
        let resultFolder = try URL(fileURLWithPath: data.value("result").stringValue())
        
        let repeats = try data.optionalValue("repeats")!.intValue()
        
        print("\nRunning with configuration: \n\tsource: \(src)\n\tsize: \(size)\n\titerations: \(iterations)\n\tposition: \(position)\n\trepeats \(repeats)")
        print("\tresultFolder: \(resultFolder.path)")
        
        print("\talgorithms: ", separator: "", terminator: "")
        [("Random", random), ("PSO", pso), ("Genetic", genetic)].forEach {
            if $0.1 {
                print("\($0.0) ", separator: "", terminator: "")
            }
        }
        print()
        
        var parameters: ParticleEvolver.Parameters!
        
        
        if pso {
            if let rawParams = rawParameters {
                guard rawParams.count == 3 else {
                    throw Error.incorrectParameters
                }
                parameters = ParticleEvolver.Parameters(omega: rawParams[0], delta1: rawParams[1], delta2: rawParams[2])
            } else {
                
                guard let cache = _cache else {
                    throw Error.noCacheNorParameters
                }
                
                guard let id = srcId else {
                    throw Error.missingSourceId
                }
                let entry = ParticleEvolver.Cache.Entry(inputId: id, size: size, iterations: iterations, maxPositionValue: position)
                parameters = try ParticleEvolver.Cache(path: cache).parameters(forEntry: entry, rounding: true)
                
                if parameters == nil {
                    throw Error.noCacheEntryFound
                }
                
            }
            if let nonOptional = parameters {
                dump(nonOptional)
            }
        }
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        
        var populations: [DataGenerator] = []
        
        let dirs = ["best", "average", "worst"]
        var emptyEntry: [(String, [Int: Double])] = []
        for dir in dirs {
            guard FileManager.default.exists(atPath: resultFolder.appendingPathComponent(dir).path).isDir else {
                fatalError("Missing \(dir) directory in results target")
            }
            emptyEntry.append((dir, [:]))
        }
        if parameters != nil {
            guard let population = Population<ParticleEvolver>.init(withInput: input, size: size, evolutionAlgorithm: ParticleEvolver.init(parameters: parameters, maxPostitionValue: position, fitnessFunction: FitnessFunctionType.rmst.function(), fitnessOptimization: <)) else {
                throw Error.populationInitializationError
            }
            populations.append(DataGenerator(population: population, name: "PSO", entries: emptyEntry))
        }
        
        if genetic {
            guard let population = Population<GeneticEvolver>.init(withInput: input, size: size, evolutionAlgorithm: GeneticEvolver.init(maxChromosomeValue: position, mutationProbability: 0.6, fitnessFunction: FitnessFunctionType.rmst.function(), fitnessOptimization: <)) else {
                throw Error.populationInitializationError
            }
            populations.append(DataGenerator(population: population, name: "Genetic", entries: emptyEntry))
        }
        
        if random  {
            guard let population = Population<RandomEvolver>.init(withInput: input, size: size, evolutionAlgorithm: RandomEvolver.init(maxChromosomeValue: position, fitnessFunction: FitnessFunctionType.rmst.function(), fitnessOptimization: <)) else {
                throw Error.populationInitializationError
            }
            populations.append(DataGenerator(population: population, name: "Random", entries: emptyEntry))
        }
        
        for i in 0 ..< populations.count {
            var population = populations[i]
            
            var entries = population.entries
            for _ in 0 ..< repeats {
                population.population.initializePopulation(withSize: size)
                for _ in 0 ..< iterations {
                    let res = population.population.generateDetailedResults(forIterations: 1)

                    for  (key, val) in entries.enumerated() {
                        var current: Double
                        switch key {
                        case 0:
                            current = res.bestFitness
                        case 1:
                            current = res.averageFitness
                        case 2:
                            current = res.worstFitness
                        default:
                            fatalError("unexpected entry")
                        }

                        if var values = val.1[res.fitnessCount] {
                            values += current
                            entries[key].1[res.fitnessCount] = values
                        } else {
                            entries[key].1[res.fitnessCount] = current
                        }
                    }
                }
                
            }
            for (key, value) in entries.enumerated() {
                var value = value
                for (vKey, v) in value.1 {
                    value.1[vKey] = v / Double(repeats)
                }
                
                entries[key] = value
            }
            
            for (key, entry) in entries {
                
                let str: String = entry.reduce("") {
                    $0.0 + "\($0.1.key) \(formatter.string(for: $0.1.value)!)\n"
                }
                try str.write(toFile: resultFolder.appendingPathComponent(key).appendingPathComponent(population.name).path, atomically: true, encoding: .utf8)
            }
            
        }
    }
}

do {
    try Console(arguments: CommandLine.arguments,
                commands: [
                    Generate(),
                    PSOParameters()
                ]
        )
        .run()
} catch {
    dump(error)
}



