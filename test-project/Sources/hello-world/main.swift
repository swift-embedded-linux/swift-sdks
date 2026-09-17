// Import all modules we expect to have in Swift
import Dispatch
import DispatchIntrospection
import Distributed
import FoundationNetworking
import FoundationXML
import Glibc
import Observation
import RegexBuilder
import SwiftOverlayShims
import Systemd

#if canImport(FoundationInternationalization)
    import FoundationInternationalization
#endif

#if canImport(Synchronization)
    import Synchronization
#endif

#if canImport(FoundationEssentials)
    import FoundationEssentials
#else
    import Foundation
#endif

print("Hello, World!")

print("")
print("--- Systemd Bus Properties ---")
print("Hostname: \(await SystemdBus.hostname)")
print("Kernel Name: \(await SystemdBus.kernelName)")
print("Kernel Release: \(await SystemdBus.kernelRelease)")
print("Kernel Version: \(await SystemdBus.kernelVersion)")
print("Operating System: \(await SystemdBus.operatingSystem)")
