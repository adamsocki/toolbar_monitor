import Foundation

/// Formats a byte count using 1000-based units, e.g. "12.3 KB", "1.4 MB", "980 B".
func formatBytes(_ value: Double) -> String {
    let units = ["B", "KB", "MB", "GB", "TB"]
    var v = max(value, 0)
    var i = 0
    while v >= 1000 && i < units.count - 1 {
        v /= 1000
        i += 1
    }
    if i == 0 { return String(format: "%.0f %@", v, units[i]) }
    return v < 100 ? String(format: "%.1f %@", v, units[i]) : String(format: "%.0f %@", v, units[i])
}

func formatRate(_ bytesPerSecond: Double) -> String {
    formatBytes(bytesPerSecond) + "/s"
}
