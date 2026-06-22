import Foundation

// Register each area's tests, then run. Later tasks append their <area>Tests() call here.
sanityTests()
notchStateMachineTests()
settingsStoreTests()
moduleRegistryTests()

exit(Int32(TestRunner.shared.runAll()))
