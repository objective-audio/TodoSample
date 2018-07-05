import Foundation
import FlowGraphDotConverterCore

// 状態遷移図を作るSwiftファイルのリスト
let inFileNames: [String] = ["Controller/TodoCloudController.swift"]

@discardableResult
func execute(command: String) -> String {
    let process = Process()
    let pipe = Pipe()
    
    process.standardOutput = pipe
    process.launchPath = "/bin/sh"
    process.arguments = ["-c", command]
    
    process.launch()
    
    let handle = pipe.fileHandleForReading
    let data = handle.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}

guard let command = CommandLine.arguments.first else {
    print("command not found.")
    exit(0)
}

let commandDirUrl = URL(fileURLWithPath: command).deletingLastPathComponent()
let outFileDirUrl = commandDirUrl.appendingPathComponent("../../../StateTransitionDiagram")
let inFileDirUrl = commandDirUrl.appendingPathComponent("../../../Todo")

guard !execute(command: "which brew").isEmpty else {
    print("brew not found. please install homebrew.")
    exit(0)
}

guard execute(command: "brew list").contains("graphviz") else {
    print("graphviz not found. 'brew install graphviz'")
    exit(0)
}

for inFileName in inFileNames {
    let inFileUrl = inFileDirUrl.appendingPathComponent(inFileName)
    
    FlowGraphDotConverter.convert(inFileUrl: inFileUrl, outDirUrl: outFileDirUrl, isRemoveEnter: true)
}

var dotFileNames: [String] = []

do {
    dotFileNames = try FileManager.default.contentsOfDirectory(atPath: outFileDirUrl.path).filter({ $0.hasSuffix(".dot")})
} catch {
    print("get dot file names failed.")
}

for dotFileName in dotFileNames {
    let dotFileUrl = outFileDirUrl.appendingPathComponent(dotFileName)
    let svgFileUrl = dotFileUrl.deletingPathExtension().appendingPathExtension("svg")
    
    if FileManager.default.fileExists(atPath: svgFileUrl.path) {
        try? FileManager.default.removeItem(at: svgFileUrl)
    }
    
    execute(command: "dot -T svg \(dotFileUrl.path) -o \(svgFileUrl.path)")
    
    if FileManager.default.fileExists(atPath: svgFileUrl.path) {
        print("write svg file: \(svgFileUrl.path)")
    } else {
        print("write svg file failed.")
    }
    
    try? FileManager.default.removeItem(at: dotFileUrl)
}
