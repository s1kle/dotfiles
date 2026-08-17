// Pure weather helpers, shared by the Weather service and Node tests.
function cityQuery(city) {
    const parts = String(city || "").split(",")
    return parts[parts.length - 1].trim()
}

function iconFor(code) {
    const c = Number(code)
    if (c === 0) return "clear"
    if (c === 1 || c === 2) return "partly"
    if (c === 3) return "cloudy"
    if (c === 45 || c === 48) return "fog"
    if ([51, 53, 55, 56, 57].includes(c)) return "drizzle"
    if ([61, 63, 65, 66, 67, 80, 81, 82].includes(c)) return "rain"
    if ([71, 73, 75, 77, 85, 86].includes(c)) return "snow"
    if ([95, 96, 99].includes(c)) return "thunder"
    return "cloudy"
}

// times/temps/codes are Open-Meteo hourly arrays for one day (index === hour).
function sampleForecast(times, temps, codes, nowHour) {
    const n = times ? times.length : 0
    if (n === 0) return { morning: null, now: null, evening: null }
    const at = h => {
        const i = Math.max(0, Math.min(n - 1, h))
        return { temp: Math.round(temps[i]), code: codes[i] }
    }
    return { morning: at(9), now: at(nowHour), evening: at(21) }
}

if (typeof module !== "undefined") module.exports = { cityQuery, iconFor, sampleForecast }
