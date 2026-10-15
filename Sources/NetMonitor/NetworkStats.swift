import Darwin

struct Counters {
    var rx: UInt64
    var tx: UInt64
}

enum NetworkStats {
    /// Interfaces counted toward the total: Wi-Fi/Ethernet (en*), cellular (pdp_ip*),
    /// and bridges. Tunnels (utun*) are excluded so VPN traffic isn't counted twice.
    static let includedPrefixes = ["en", "pdp_ip", "bridge"]

    /// Sums 64-bit byte counters across included interfaces.
    /// Uses net.link.generic.ifdata (IFMIB_IFDATA) per interface; NET_RT_IFLIST2
    /// truncates counters to 32 bits on current macOS.
    static func read() -> Counters? {
        guard let list = if_nameindex() else { return nil }
        defer { if_freenameindex(list) }

        var rx: UInt64 = 0
        var tx: UInt64 = 0
        var i = 0
        while list[i].if_index != 0, let cName = list[i].if_name {
            let name = String(cString: cName)
            if includedPrefixes.contains(where: { name.hasPrefix($0) }),
               let data = ifData(index: Int32(list[i].if_index)) {
                rx &+= data.ifi_ibytes
                tx &+= data.ifi_obytes
            }
            i += 1
        }
        return Counters(rx: rx, tx: tx)
    }

    private static func ifData(index: Int32) -> if_data64? {
        var mib: [Int32] = [CTL_NET, PF_LINK, NETLINK_GENERIC, IFMIB_IFDATA, index, IFDATA_GENERAL]
        var data = ifmibdata()
        var len = MemoryLayout<ifmibdata>.size
        guard sysctl(&mib, UInt32(mib.count), &data, &len, nil, 0) == 0 else { return nil }
        return data.ifmd_data
    }
}
