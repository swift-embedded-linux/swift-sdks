import Systemd

extension SystemdBus {

    static func getHostname1Property(member: String) async throws -> Any? {
        let hostnameInterface = "org.freedesktop.hostname1"

        return try await system.getProperty(
            destination: hostnameInterface,
            path: "/org/freedesktop/hostname1",
            interface: hostnameInterface,
            member: member
        )
    }

    static var hostname: String {
        get async {
            let hostname = try? await getHostname1Property(member: "Hostname")
            return hostname as? String ?? "Unknown"
        }
    }

    static var kernelName: String {
        get async {
            let kernelName = try? await getHostname1Property(member: "KernelName")
            return kernelName as? String ?? "Unknown"
        }
    }

    static var kernelRelease: String {
        get async {
            let kernelRelease = try? await getHostname1Property(member: "KernelRelease")
            return kernelRelease as? String ?? "Unknown"
        }
    }

    static var kernelVersion: String {
        get async {
            let kernelVersion = try? await getHostname1Property(member: "KernelVersion")
            return kernelVersion as? String ?? "Unknown"
        }
    }

    static var operatingSystem: String {
        get async {
            let operatingSystem = try? await getHostname1Property(member: "OperatingSystemPrettyName")
            return operatingSystem as? String ?? "Unknown"
        }
    }
}
