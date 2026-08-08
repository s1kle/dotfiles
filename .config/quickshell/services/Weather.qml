pragma Singleton

import Quickshell
import QtQuick
import "scripts/weather.js" as W

// Open-Meteo (no key): geocode Config.weather.city -> lat/lon (cached), then
// today's hourly forecast; expose morning/now/evening {temp,code}.
Singleton {
    id: root

    property bool ready: false
    property string error: ""
    property var morning: null
    property var now: null
    property var evening: null

    property real lat: NaN
    property real lon: NaN
    property string geocodedFor: ""

    function iconFor(code: int): string { return W.iconFor(code) }

    function get(url, onOk) {
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            if (xhr.status === 200) {
                try { onOk(JSON.parse(xhr.responseText)) }
                catch (e) { root.error = "parse: " + (e?.message ?? e) }
            } else {
                root.error = "http " + xhr.status
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function refresh(): void {
        const city = Config.weather.city
        if (root.geocodedFor === city && !isNaN(root.lat)) {
            root.fetchForecast()
            return
        }
        const q = encodeURIComponent(W.cityQuery(city))
        root.get(`https://geocoding-api.open-meteo.com/v1/search?name=${q}&count=1`, res => {
            const r = res && res.results && res.results[0]
            if (!r) { root.error = "geocode: no result for " + city; return }
            root.lat = r.latitude
            root.lon = r.longitude
            root.geocodedFor = city
            root.fetchForecast()
        })
    }

    function fetchForecast(): void {
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${root.lat}&longitude=${root.lon}`
            + `&hourly=temperature_2m,weathercode&timezone=auto&forecast_days=1`
        root.get(url, res => {
            const h = res && res.hourly
            if (!h || !h.time) { root.error = "forecast: empty"; return }
            const s = W.sampleForecast(h.time, h.temperature_2m, h.weathercode, new Date().getHours())
            root.morning = s.morning
            root.now = s.now
            root.evening = s.evening
            root.error = ""
            root.ready = true
            console.warn("WX", JSON.stringify({ error: root.error, now: root.now }))
        })
    }

    Component.onCompleted: root.refresh()
    Connections { target: Config; function onWeatherChanged() { root.refresh() } }

    Timer {
        interval: (Config.weather.refreshMinutes || 15) * 60000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
