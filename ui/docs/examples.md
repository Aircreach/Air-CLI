# Examples

Examples are component demos. They show meaningful component states and are
the preferred way to inspect Air UI behavior during development.

```bash
air ui example
air ui example --static
air ui example progress
air ui example progress --static
air ui example layout
ui example select
ui progress example --label "Transfer" --bar block --spinner braille
```

Behavior:

- `air ui example [component]` runs the component story.
- `--static` or `-s` renders a stable sample.
- With no component and a TTY, Air opens a component picker.
- With no component and no TTY, Air prints the static component suite.
- Running examples must be interruptible with `Ctrl-C` and restore terminal state.

Development rule: do not keep old story aliases or flags during active
development. Update examples and docs to the current API.
