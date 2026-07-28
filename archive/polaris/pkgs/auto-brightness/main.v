import os
import time
import math

fn main() {
	config := Config.load() or {
		eprintln('Failed to load configuration: ${err}')
		exit(1)
	}

	calculator := get_brightness_calculator(config) or {
		eprintln('Failed to set up brightness calculator: ${err}')
		exit(1)
	}

	max_brightness := calculator(config.brightness.max_illuminance)
	mut samples := []f64{len: int(config.app.average_samples), cap: int(config.app.average_samples), init: max_brightness / f64(config.app.average_samples)}
	mut average := f64(max_brightness)
	mut pos := 0
	mut last_written := math.nan() // Always force a write on the first tick

	mut exceeding_samples := config.theme.required_exceeding_samples
	mut is_light_theme := ?bool(none)

	for {
		illuminance := os.read_file(config.hw.illuminance_sensor) or {
			eprintln('Failed to read illuminance sensor: ${err}')
			continue
		}.u32()

		if illuminance > config.theme.light_threshold || illuminance < config.theme.dark_threshold {
			exceeding_samples++
		} else {
			exceeding_samples = 0
		}

		if exceeding_samples >= config.theme.required_exceeding_samples {
			exceeding_samples = 0
			target_is_light := illuminance > config.theme.light_threshold
			if (target_is_light && !(is_light_theme or { false })) || (!target_is_light && (is_light_theme or { true })) {
				is_light_theme = target_is_light
				go set_theme(config, target_is_light)
			}
		}

		calc_brightness := calculator(illuminance)

		average -= samples[pos]
		samples[pos] = calc_brightness / samples.len
		average += samples[pos]
		pos = (pos + 1) % samples.len

		brightness := u32(math.round(average))
		if brightness != last_written {
			last_written = brightness
			eprintln(brightness)
			os.write_file(config.hw.backlight_device + '/brightness', '${u32(math.round(average))}') or {
				eprintln('Failed to write brightness: ${err}')
			}
		}

		time.sleep(config.app.interval * time.millisecond)
	}
}
