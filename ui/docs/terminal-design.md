# Terminal Design

Air treats terminal UI as three layers:

- glyph: ASCII/Unicode characters
- style: ANSI SGR such as bold, italic, underline, strikethrough, color, background, and inverse
- layout: spacing, alignment, panels, rails, tables, and viewports

Terminals do not support per-line font size. Use spacing, block characters,
ASCII hierarchy, and layout primitives for scale.

Motion is frame rendering: `state -> renderer -> frame -> terminal`.
Use it explicitly for running work or transitions: shimmer, typewriter, wave,
cursor, reveal, gradient, heatmap, highlight, morph, particle, and ghost
loading. Disable motion in plain, non-TTY, startup, or `TERM=dumb` contexts.

Marker rules:

- Route status markers through `ui marker`.
- Reserve a stable visual slot, for example `[✔ ]`, `[→ ]`, `[  ]`.
- Keep icons paired with text labels nearby.
- Default to Unicode only when terminal capability allows it; provide plain fallbacks.

Reference projects: Gum, Clack, Enquirer/Prompts, Bubble Tea/Bubbles, Lip Gloss,
Ink, Rich/Textual, and Spectre.Console.
