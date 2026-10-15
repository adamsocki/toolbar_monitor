# NetMonitor

A tiny macOS menu bar app that shows your current network upload and download speed.

```
↑ 12.3 KB/s
↓  1.4 MB/s
```

- Updates every second, with a fixed-width label so the menu bar doesn't jitter
- Adapts to light and dark menu bars
- Menu shows total data received/sent since boot, a **Launch at Login** toggle, and Quit
- No Dock icon, no dependencies, minimal CPU and memory use

## Requirements

- macOS 13 or later
- Swift toolchain (Xcode or the Command Line Tools: `xcode-select --install`)

## Build and run

```sh
./build.sh
open build/NetMonitor.app
```

`build.sh` compiles a release build, assembles `build/NetMonitor.app`, and ad-hoc signs it.

To keep it around, copy the app into `/Applications` before turning on **Launch at Login**, so the login item points to a stable location:

```sh
cp -R build/NetMonitor.app /Applications/
open /Applications/NetMonitor.app
```

## What gets counted

Rates are summed across Wi-Fi/Ethernet (`en*`), cellular (`pdp_ip*`) and bridge interfaces. VPN tunnels (`utun*`) are excluded so VPN traffic isn't counted twice, and loopback is ignored. To change this, edit `includedPrefixes` in `Sources/NetMonitor/NetworkStats.swift`.

Counters are read per interface through the `net.link.generic.ifdata` sysctl, which gives full 64-bit byte counts (the `NET_RT_IFLIST2` route sysctl truncates them to 32 bits on current macOS).

## Project layout

| File | Purpose |
| --- | --- |
| `Sources/NetMonitor/AppDelegate.swift` | Status item, label drawing, menu, login item |
| `Sources/NetMonitor/NetworkStats.swift` | Reads interface byte counters |
| `Sources/NetMonitor/Format.swift` | Byte and rate formatting |
| `Resources/Info.plist` | App bundle metadata (`LSUIElement` hides the Dock icon) |
| `build.sh` | Builds and packages the `.app` |
