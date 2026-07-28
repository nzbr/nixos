import json
import os
import os.cmdline
import time

struct Config {
	app        AppConfig
	brightness BrightnessConfig
	hw         HardwareConfig
	theme      ThemeConfig
}

struct AppConfig {
	interval        time.Duration
	average_samples u32
}

struct BrightnessConfig {
	min_brightness  u32
	max_illuminance u32
}

struct HardwareConfig {
	illuminance_sensor string
	backlight_device   string
}

struct ThemeConfig {
	dark                       Theme
	dark_threshold             u32
	light                      Theme
	light_threshold            u32
	required_exceeding_samples u32
}

struct Theme {
	color_scheme string
	accent_color string
}

fn Config.load() !Config {
	path := cmdline.option(os.args, '-c', '/etc/auto-brightness.json')
	content := os.read_file(path)!

	result := json.decode(Config, content)!

	eprintln(json.encode_pretty(result))

	return result
}
