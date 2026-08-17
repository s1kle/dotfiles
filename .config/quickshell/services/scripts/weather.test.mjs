// weather.test.mjs — node .config/quickshell/services/scripts/weather.test.mjs
import { createRequire } from "module"
const require = createRequire(import.meta.url)
const assert = require("assert")
const { cityQuery, iconFor, sampleForecast } = require("./weather.js")

assert.strictEqual(cityQuery("Приморский край, Находка"), "Находка")
assert.strictEqual(cityQuery("  Berlin "), "Berlin")

assert.strictEqual(iconFor(0), "clear")
assert.strictEqual(iconFor(2), "partly")
assert.strictEqual(iconFor(3), "cloudy")
assert.strictEqual(iconFor(48), "fog")
assert.strictEqual(iconFor(65), "rain")
assert.strictEqual(iconFor(75), "snow")
assert.strictEqual(iconFor(95), "thunder")
assert.strictEqual(iconFor(999), "cloudy") // unknown -> fallback

const times = Array.from({ length: 24 }, (_, h) => `2026-08-08T${String(h).padStart(2, "0")}:00`)
const temps = times.map((_, h) => h) // temp === hour for easy assertions
const codes = times.map(() => 0)
const s = sampleForecast(times, temps, codes, 14)
assert.strictEqual(s.morning.temp, 9)
assert.strictEqual(s.now.temp, 14)
assert.strictEqual(s.evening.temp, 21)
// clamp
assert.strictEqual(sampleForecast(times, temps, codes, 99).now.temp, 23)
// empty
assert.deepStrictEqual(sampleForecast([], [], [], 12), { morning: null, now: null, evening: null })

console.log("weather.js: all assertions passed")
