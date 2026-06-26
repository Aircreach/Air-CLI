# Layout

Layout is Air UI infrastructure for arranging components. It is not a plugin and
not a single fixed wizard.

Use command APIs for quick composition:

```bash
ui layout stack --title "Summary" < content.txt
ui layout grid --columns 2 < items.txt
ui layout split --left current.txt --right details.txt
ui layout rail --current 3 < steps.txt
ui layout screen --title "Enable helper UI" --main current.txt --side steps.txt
ui layout wizard --current 3 --total 5 --title "Build helper" --steps-file steps.txt --body body.txt --log build.log --log-height 8
ui layout viewport --title "Build output" --height max:8 < build.log
```

Use a TOML layout spec for reusable or complex screens:

```toml
layout = "wizard"
title = "Enable helper UI"
subtitle = "Prepare the optional helper safely."
current = 3
total = 6
rail = "right"
steps_file = "steps.txt"
body_file = "body.txt"
log_file = "build.log"
log_height = 8
```

Then render it explicitly:

```bash
ui layout render ./layout.toml
```

Height rules:

- `auto`: expand to content.
- `<n>`: show exactly/recently up to `n` lines.
- `max:<n>`: expand until `n`, then show recent lines with hidden count.
- `fill`: Bash fallback treats this as `auto`; helper UI may later implement real fill/scroll.

Guidelines:

- Use wizard layout for guided flows that need current work plus a step rail.
- Use viewport for bounded logs, previews, and long detail text.
- Use progress only for measured work, not step navigation.
- Do not box every paragraph; borders should define real regions.
- Plain and narrow terminals degrade to sequential text.
