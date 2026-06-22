import Foundation

// Register each area's tests, then run. Later tasks append their <area>Tests() call here.
sanityTests()

exit(Int32(TestRunner.shared.runAll()))
