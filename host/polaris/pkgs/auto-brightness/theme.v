import os

fn set_theme(config Config, light bool) {
	theme := if light { config.theme.light } else { config.theme.dark }
	eprintln('Setting theme to ${theme.color_scheme}')

	os.execute_opt('plasma-apply-colorscheme "${theme.color_scheme}"') or {
		eprintln('Failed to apply color scheme: ${err}')
		return
	}

	os.execute_opt('plasma-apply-colorscheme --accent-color "${theme.accent_color}"') or {
		eprintln('Failed to apply accent color: ${err}')
		return
	}
}
