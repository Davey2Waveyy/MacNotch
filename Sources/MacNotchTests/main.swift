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
calendarModuleTests()
shelfStoreTests()
settingsLogicTests()
codeModuleCoreTests()
screenTimeTrackerTests()
timerSchedulerTests()

exit(Int32(TestRunner.shared.runAll()))
