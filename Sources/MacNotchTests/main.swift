import Foundation

// Register each area's tests, then run. Later tasks append their <area>Tests() call here.
sanityTests()
macNotchAppTests()
notchStateMachineTests()
notchWindowTests()
settingsStoreTests()
moduleRegistryTests()
screenLocatorTests()
systemSampleTests()
mediaControllerTests()
calendarFormatTests()
shelfStoreTests()

exit(Int32(TestRunner.shared.runAll()))
