import math
import os

fn get_brightness_calculator(config Config) !fn (u32) f64 {
	min_brightness := config.brightness.min_brightness
	eprintln('Min brightness: ${min_brightness}')
	max_illuminance := config.brightness.max_illuminance
	eprintln('Max illuminance: ${max_illuminance}')
	max_brightness := os.read_file(config.hw.backlight_device + '/max_brightness')!.u32()
	eprintln('Max brightness: ${max_brightness}')
	steps := max_brightness - min_brightness
	eprintln('Steps: ${steps}')

	// 1 / max_illuminance: Makes the formula below reach 1 at max_illuminance (the steps part is ignored)
	// Steps needs to be squared because the factor is applied inside the square root
	factor := (1 / f64(max_illuminance)) * math.pow(steps, 2)
	eprintln('Factor: ${factor}')

	return fn [factor, max_brightness, min_brightness] (illuminance u32) f64 {
		result := math.sqrt(illuminance * factor) + min_brightness
		if result > max_brightness {
			return max_brightness
		} else if result < min_brightness {
			return min_brightness
		}
		return result
	}
}
