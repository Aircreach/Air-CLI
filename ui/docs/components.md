# Components

Public component API:

```bash
ui text "Use **bold**, //italic//, __underline__, ~~strike~~, [[muted]], ^^inverse^^, `code`, ==hint==, !!accent!!, {{pill}}, [done], [warn], [error]"
ui text --status-style text "Status: [done] [warn] [error]"
ui markdown < text.md
ui code --title "bash" --language bash < script.sh
ui panel --title "Result" --severity done "Done"
ui marker done|warn|error|current|pending [--style bracket|bare|text]
ui badge "helper UI" hint
ui block warning "env" "bash-env will use a partial capability"
ui check-item error "plugin" "Missing handler"
ui log success "Generated runtime"
ui input --prompt "Project name" --default my-app --required
ui password --prompt "token" --required
ui select --style menu --prompt "renderer" --default starship --option 'starship	Starship	Fast prompt renderer'
ui multiselect --prompt "targets" --default bashrc --option bashrc --option bash-env
ui confirm --title "Enable plugin" --message "Warnings were found" --risk medium
ui table < rows.tsv
ui kv "renderer" "starship"
ui spinner --title "Refreshing" -- air env refresh
ui task --title "Check env" -- air plugin check env
ui progress --label "Download" --current 65 --total 100
ui progress --label "Segments" --bar block --spinner none --current 65 --total 100
ui progress example --label "Transfer" --bar block --spinner braille --width 20
ui flow ./flow.toml
```

Rules:

- UI/interactions go to stderr; returned values go to stdout.
- Prefer component parameters for local styling, such as `--bar`, `--width`, `--spinner`, `--style`.
- Durable user choices belong in Air UI state; shared color/symbol/density belongs in theme tokens.
- Use `ui marker` instead of hand-writing status glyphs.
- Use `[done]`, `[warn]`, and `[error]` in inline text.
