import Foundation
import TopsoilKit

let outputDir = CommandLine.arguments.dropFirst().first ?? "snapshots"
exit(Int32(NotchSnapshots.run(outputDirectory: outputDir)))
