pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // pause polling when no UI consumes this service (e.g. hidden dashboard)
    property bool active: true

    property real cpuPerc: 0
    property real memUsed: 0
    property real memTotal: 0
    readonly property real memPerc: memTotal > 0 ? memUsed / memTotal * 100 : 0
    property real diskUsed: 0
    property real diskTotal: 0
    readonly property real diskPerc: diskTotal > 0 ? diskUsed / diskTotal * 100 : 0

    property real downloadSpeed: 0 // bytes/s
    property real uploadSpeed: 0   // bytes/s
    property var networkHistory: [] // [{download, upload}] for graphing

    property string gpuType: "none" // "nvidia" | "amd" | "none"
    readonly property bool hasGpu: gpuType !== "none"
    property real gpuUsage: 0
    property real gpuTemp: 0
    property real gpuMemUsed: 0
    property real gpuMemTotal: 0
    readonly property real gpuMemPerc: gpuMemTotal > 0 ? gpuMemUsed / gpuMemTotal * 100 : 0

    property var topProcesses: [] // [{name, cpu, pid}]

    property real lastCpuIdle: 0
    property real lastCpuTotal: 0
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real lastNetTime: 0

    // ponytail: one process per tick covers all sources; split into per-vendor procs if any stalls
    // ponytail: networkHistory capped at 30 samples; ring buffer if graphs need more
    function update(): void {
        statsProc.exec(["/bin/sh", "-c",
            "echo ===CPU===; grep '^cpu ' /proc/stat; echo ===MEM===; grep -E 'MemTotal|MemAvailable' /proc/meminfo; echo ===DISK===; df -B1 / | tail -1; echo ===NET===; awk '{rx+=$2; tx+=$10} END {print rx\" \"tx}' /proc/net/dev; echo ===GPU===; if command -v nvidia-smi >/dev/null 2>&1; then echo NVIDIA; nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits; elif command -v radeontop >/dev/null 2>&1; then echo AMD; radeontop -d - -l 1 2>/dev/null | grep -oiP 'gpu \\K[0-9.]+' | head -1; echo TEMP; cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -1; else echo NONE; fi; echo ===PROCS===; ps -eo comm,%cpu,pid --sort=-%cpu | head -6 | tail -5 | awk '{print $1\"|\"$2\"|\"$3}'"
        ])
    }

    Process {
        id: statsProc
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    function section(text: string, marker: string): string {
        const i = text.indexOf(marker)
        if (i < 0) return ""
        const rest = text.slice(i + marker.length)
        const j = rest.indexOf("===")
        return (j < 0 ? rest : rest.slice(0, j)).trim()
    }

    function parse(text: string): void {
        const cpu = root.section(text, "===CPU===").split(/\s+/)
        if (cpu.length >= 5) {
            const n = cpu.slice(1).map(Number)
            const total = n.slice(0, 8).reduce((a, b) => a + b, 0)
            const idle = n[3] + n[4]
            if (root.lastCpuTotal > 0) {
                const dTotal = total - root.lastCpuTotal
                const dIdle = idle - root.lastCpuIdle
                if (dTotal > 0) {
                    root.cpuPerc = Math.max(0, Math.min(100, (1 - dIdle / dTotal) * 100))
                }
            }
            root.lastCpuIdle = idle
            root.lastCpuTotal = total
        }

        const mem = root.section(text, "===MEM===")
        const memTotal = mem.match(/MemTotal:\s*(\d+)/)
        const memAvail = mem.match(/MemAvailable:\s*(\d+)/)
        if (memTotal && memAvail) {
            root.memTotal = Number(memTotal[1]) * 1024
            root.memUsed = root.memTotal - Number(memAvail[1]) * 1024
        }

        const disk = root.section(text, "===DISK===").split(/\s+/)
        if (disk.length >= 3) {
            root.diskTotal = Number(disk[1])
            root.diskUsed = Number(disk[2])
        }

        const net = root.section(text, "===NET===").split(/\s+/)
        if (net.length >= 2) {
            const rx = Number(net[0])
            const tx = Number(net[1])
            const now = Date.now() / 1000
            if (root.lastNetTime > 0 && rx >= root.lastRxBytes && tx >= root.lastTxBytes) {
                const dt = now - root.lastNetTime
                if (dt > 0) {
                    root.downloadSpeed = (rx - root.lastRxBytes) / dt
                    root.uploadSpeed = (tx - root.lastTxBytes) / dt
                    root.networkHistory.push({ download: root.downloadSpeed, upload: root.uploadSpeed })
                    if (root.networkHistory.length > 30) root.networkHistory.shift()
                    root.networkHistoryChanged()
                }
            }
            root.lastRxBytes = rx
            root.lastTxBytes = tx
            root.lastNetTime = now
        }

        const gpu = root.section(text, "===GPU===").split("\n")
        root.gpuType = "none"
        if (gpu[0] === "NVIDIA" && gpu[1]) {
            const p = gpu[1].split(",").map(x => Number(x.trim()))
            if (p.length >= 4 && p.every(Number.isFinite)) {
                root.gpuType = "NVIDIA"
                root.gpuUsage = p[0]
                root.gpuMemUsed = p[1] * 1024 * 1024
                root.gpuMemTotal = p[2] * 1024 * 1024
                root.gpuTemp = p[3]
            }
        } else if (gpu[0] === "AMD" && gpu[1]) {
            const usage = Number(gpu[1])
            if (Number.isFinite(usage)) root.gpuUsage = usage
            if (gpu[2] === "TEMP" && gpu[3]) {
                const t = Number(gpu[3])
                if (Number.isFinite(t)) root.gpuTemp = t / 1000
            }
        }

        root.topProcesses = root.section(text, "===PROCS===").split("\n")
            .filter(line => line.trim() !== "")
            .map(line => {
                const p = line.split("|")
                return { name: p[0] || "Unknown", cpu: Number(p[1]) || 0, pid: Number(p[2]) || 0 }
            })
    }

    function formatBytes(bytes: real): var {
        const gb = bytes / (1024 ** 3)
        if (gb >= 1) return { value: gb, unit: "GB" }
        const mb = bytes / (1024 ** 2)
        if (mb >= 1) return { value: mb, unit: "MB" }
        return { value: bytes / 1024, unit: "KB" }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.update()
    }
}
