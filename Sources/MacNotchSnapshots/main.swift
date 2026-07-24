import Foundation
import MacNotchKit

let outputDir = CommandLine.arguments.dropFirst().first ?? "snapshots"
exit(Int32(NotchSnapshots.run(outputDirectory: outputDir)))
