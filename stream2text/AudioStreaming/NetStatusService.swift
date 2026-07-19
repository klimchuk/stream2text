//
//  NetStatusService.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import Foundation
import Network

enum NetConnectionType: Equatable {
    case cellular(connected: Bool)
    case wifi(connected: Bool)
    case other(connected: Bool)
    case undetermined

    var isConnected: Bool {
        switch self {
        case let .cellular(connected),
             let .wifi(connected),
             let .other(connected):
            return connected
        default:
            return false
        }
    }
}

protocol NetStatusProvider {
    var isConnected: Bool { get }
    var connectionType: NetConnectionType { get }

    func start(connectionChange: @escaping (NetConnectionType) -> Void)
    func stop()
}

final class NetStatusService: NetStatusProvider {
    var isConnected: Bool {
        network.currentPath.status == .satisfied
    }

    var connectionType: NetConnectionType {
        network.currentPath.toNetConnectionType()
    }

    private let network: NWPathMonitor
    private let monitorQueue: DispatchQueue
    private var isMonitoring = false

    init(network: NWPathMonitor) {
        self.network = network
        monitorQueue = DispatchQueue(label: "net.path.queue", qos: .utility)
    }

    deinit {
        stop()
    }

    /// Starts monitoring connection changes.
    func start(connectionChange: @escaping (NetConnectionType) -> Void) {
        network.pathUpdateHandler = { path in
            let connectionType = path.toNetConnectionType()
            connectionChange(connectionType)
        }
        startIfNeeded()
    }

    func stop() {
        guard isMonitoring else { return }
        network.pathUpdateHandler = nil
        network.cancel()
        isMonitoring = false
    }

    private func startIfNeeded() {
        guard !isMonitoring else { return }
        isMonitoring = true
        network.start(queue: monitorQueue)
    }
}

extension NWPath {
    func toNetConnectionType() -> NetConnectionType {
        let isCellular = usesInterfaceType(.cellular)
        let isWifi = usesInterfaceType(.wifi)
        let isOther = usesInterfaceType(.loopback)
            || usesInterfaceType(.other)
            || usesInterfaceType(.wiredEthernet)
        let isConnected = status == .satisfied

        if isCellular {
            return .cellular(connected: isConnected)
        } else if isWifi {
            return .wifi(connected: isConnected)
        } else if isOther {
            return .other(connected: isConnected)
        }

        return .undetermined
    }
}
