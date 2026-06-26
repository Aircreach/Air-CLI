package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"
)

type theme struct {
	title  string
	muted  string
	ok     string
	warn   string
	err    string
	hint   string
	accent string
	code   string
	bold   string
	italic string
	under  string
	strike string
	inv    string
	pillFG string
	pillBG string
	reset  string
	plain  bool
}

func main() {
	t := loadTheme()
	args := os.Args[1:]
	if len(args) == 0 {
		usage()
		os.Exit(1)
	}

	var err error
	switch args[0] {
	case "markdown", "md":
		err = cmdMarkdown(t)
	case "panel":
		err = cmdPanel(t, args[1:])
	case "progress":
		err = cmdProgress(t, args[1:])
	case "spinner", "loading":
		err = cmdSpinner(t, args[1:])
	case "input":
		err = cmdInput(t, args[1:])
	case "confirm":
		err = cmdConfirm(args[1:])
	case "select":
		err = cmdSelect(args[1:])
	case "multiselect":
		err = cmdMultiSelect(args[1:])
	default:
		err = fmt.Errorf("unknown command: %s", args[0])
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "air-ui:", err)
		os.Exit(1)
	}
}

func usage() {
	fmt.Fprintln(os.Stderr, "usage: air-ui <markdown|panel|progress|spinner|input|confirm|select|multiselect>")
}

func loadTheme() theme {
	t := theme{
		title:  env("AIR_UI_COLOR_TITLE", "1"),
		muted:  env("AIR_UI_COLOR_MUTED", "2;37"),
		ok:     env("AIR_UI_COLOR_OK", "1;32"),
		warn:   env("AIR_UI_COLOR_WARNING", "1;33"),
		err:    env("AIR_UI_COLOR_ERROR", "1;31"),
		hint:   env("AIR_UI_COLOR_HINT", "1;36"),
		accent: env("AIR_UI_COLOR_ACCENT", "1;35"),
		code:   env("AIR_UI_COLOR_CODE", "2;36"),
		bold:   env("AIR_UI_COLOR_BOLD", "1"),
		italic: env("AIR_UI_COLOR_ITALIC", "3"),
		under:  env("AIR_UI_COLOR_UNDERLINE", "4"),
		strike: env("AIR_UI_COLOR_STRIKE", "9"),
		inv:    env("AIR_UI_COLOR_INVERSE", "7"),
		pillFG: env("AIR_UI_COLOR_PILL_FG", "1;30"),
		pillBG: env("AIR_UI_COLOR_PILL_BG", "46"),
		reset:  "\033[0m",
		plain:  os.Getenv("AIR_PLAIN") == "1" || os.Getenv("NO_COLOR") != "",
	}
	return t
}

func env(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

func (t theme) paint(code, value string) string {
	if t.plain || value == "" {
		return value
	}
	return "\033[" + code + "m" + value + t.reset
}

func (t theme) badge(text, severity string) string {
	if t.plain {
		return "[" + text + "]"
	}
	bg := t.pillBG
	switch severity {
	case "ok", "success", "done":
		bg = "42"
	case "warning", "warn":
		bg = "43"
	case "error", "failed", "blocked":
		bg = "41"
	}
	return "\033[" + bg + ";" + t.pillFG + "m " + text + " " + t.reset
}

func formatInline(t theme, line string) string {
	replacements := []struct {
		re   *regexp.Regexp
		code string
	}{
		{regexp.MustCompile(`\*\*([^*]+)\*\*`), t.bold},
		{regexp.MustCompile(`//([^/]+)//`), t.italic},
		{regexp.MustCompile(`__([^_]+)__`), t.under},
		{regexp.MustCompile("`([^`]+)`"), t.code},
		{regexp.MustCompile(`==([^=]+)==`), t.hint},
		{regexp.MustCompile(`!!([^!]+)!!`), t.accent},
		{regexp.MustCompile(`\[\[([^]]+)\]\]`), t.muted},
		{regexp.MustCompile(`~~([^~]+)~~`), t.strike},
		{regexp.MustCompile(`\^\^([^^]+)\^\^`), t.inv},
	}
	for _, item := range replacements {
		line = item.re.ReplaceAllStringFunc(line, func(match string) string {
			sub := item.re.FindStringSubmatch(match)
			if len(sub) != 2 {
				return match
			}
			return t.paint(item.code, sub[1])
		})
	}
	pillRe := regexp.MustCompile(`\{\{([^}]+)\}\}`)
	line = pillRe.ReplaceAllStringFunc(line, func(match string) string {
		sub := pillRe.FindStringSubmatch(match)
		if len(sub) != 2 {
			return match
		}
		return t.badge(sub[1], "hint")
	})
	line = strings.ReplaceAll(line, "[done]", statusToken(t, "done"))
	line = strings.ReplaceAll(line, "[warn]", statusToken(t, "warn"))
	line = strings.ReplaceAll(line, "[error]", statusToken(t, "error"))
	return line
}

func statusToken(t theme, state string) string {
	switch state {
	case "done", "ok":
		return t.paint(t.ok, "[✔ ]")
	case "warn", "warning":
		return t.paint(t.warn, "[! ]")
	case "error":
		return t.paint(t.err, "[× ]")
	default:
		return t.paint(t.muted, "[  ]")
	}
}

func cmdMarkdown(t theme) error {
	scanner := bufio.NewScanner(os.Stdin)
	inCode := false
	codeLanguage := ""
	codeLines := []string{}
	for scanner.Scan() {
		line := scanner.Text()
		switch {
		case strings.HasPrefix(line, "```"):
			if inCode {
				renderCodeBlock(t, codeLanguage, strings.Join(codeLines, "\n"))
				inCode = false
				codeLanguage = ""
				codeLines = nil
			} else {
				inCode = true
				codeLanguage = strings.TrimPrefix(line, "```")
				codeLines = nil
			}
		case inCode:
			codeLines = append(codeLines, line)
		case strings.HasPrefix(line, "# "):
			fmt.Println(t.paint(t.title, strings.TrimPrefix(line, "# ")))
		case strings.HasPrefix(line, "## "):
			fmt.Println("  " + t.paint(t.hint, strings.TrimPrefix(line, "## ")))
		case strings.HasPrefix(line, "- "):
			fmt.Println("  - " + formatInline(t, strings.TrimPrefix(line, "- ")))
		case strings.HasPrefix(line, "> "):
			fmt.Println("  " + t.paint(t.muted, strings.TrimPrefix(line, "> ")))
		case line == "":
			fmt.Println()
		default:
			fmt.Println("  " + formatInline(t, line))
		}
	}
	if inCode {
		renderCodeBlock(t, codeLanguage, strings.Join(codeLines, "\n"))
	}
	return scanner.Err()
}

func renderCodeBlock(t theme, language, content string) {
	top := "╭─"
	side := "│"
	bottom := "╰─"
	if t.plain {
		top = "+--"
		side = "|"
		bottom = "+--"
	}
	fmt.Print("  " + t.paint(t.muted, top))
	if language != "" {
		fmt.Print(" " + t.paint(t.title, "code") + " " + t.badge(language, "hint"))
	}
	fmt.Println()
	for _, line := range strings.Split(strings.TrimRight(content, "\n"), "\n") {
		fmt.Println("  " + t.paint(t.muted, side) + "  " + t.paint(t.code, line))
	}
	fmt.Println("  " + t.paint(t.muted, bottom))
}

func cmdPanel(t theme, args []string) error {
	title := ""
	severity := "hint"
	for len(args) > 0 {
		switch args[0] {
		case "--title":
			title, args = nextArg(args)
		case "--severity", "--style":
			severity, args = nextArg(args)
		default:
			args = args[1:]
		}
	}
	color := severityColor(t, severity)
	data, _ := io.ReadAll(os.Stdin)
	lines := strings.Split(strings.TrimRight(string(data), "\n"), "\n")
	top := "╭─"
	side := "│"
	bottom := "╰─"
	if t.plain {
		top = "+--"
		side = "|"
		bottom = "+--"
	}
	if title != "" {
		fmt.Printf("  %s %s\n", t.paint(color, top), t.paint(t.title, title))
	} else {
		fmt.Printf("  %s\n", t.paint(color, top))
	}
	for _, line := range lines {
		rendered := formatInline(t, line)
		fmt.Printf("  %s  %s\n", t.paint(color, side), rendered)
	}
	fmt.Printf("  %s\n", t.paint(color, bottom))
	return nil
}

func cmdProgress(t theme, args []string) error {
	if len(args) > 0 {
		switch args[0] {
		case "example":
			return cmdProgressExample(t, args[1:])
		}
	}

	current := 0
	total := 100
	width := progressDefaultWidth()
	label := ""
	style := progressDefaultStyle()
	spinner := progressDefaultSpinner()
	fill := ""
	empty := ""
	fillSet := false
	emptySet := false
	transient := false
	for len(args) > 0 {
		switch args[0] {
		case "-h", "--help":
			fmt.Println("usage: air-ui progress --label <text> --current <n> --total <n> [--bar block|ascii|compact] [--spinner braille|line|none]")
			fmt.Println("       air-ui progress example [--bar block|ascii|compact] [--spinner braille|line|none]")
			return nil
		case "--current":
			current, args = nextInt(args, 0)
		case "--total":
			total, args = nextInt(args, 100)
		case "--width":
			width, args = nextInt(args, width)
		case "--label":
			label, args = nextArg(args)
		case "--style", "--bar":
			style, args = nextArg(args)
		case "--spinner":
			spinner, args = nextArg(args)
		case "--fill", "--filled":
			fill, args = nextArg(args)
			fillSet = true
		case "--empty":
			empty, args = nextArg(args)
			emptySet = true
		case "--transient":
			transient = true
			args = args[1:]
		default:
			if strings.HasPrefix(args[0], "--") {
				return fmt.Errorf("unknown option: %s", args[0])
			}
			if label == "" {
				label = args[0]
			}
			args = args[1:]
		}
	}

	renderProgress(t, current, total, width, label, style, spinner, fill, empty, transient, fillSet, emptySet)
	return nil
}

func cmdProgressExample(t theme, args []string) error {
	width := progressDefaultWidth()
	label := "transfer"
	style := progressDefaultStyle()
	spinner := progressDefaultSpinner()
	fill := ""
	empty := ""
	fillSet := false
	emptySet := false
	delay := progressDefaultDelay()
	step := progressDefaultStep()

	for len(args) > 0 {
		switch args[0] {
		case "-h", "--help":
			fmt.Println("usage: air-ui progress example [--label <text>] [--bar block|ascii|compact] [--spinner braille|line|none] [--width <cells>] [--delay <seconds>] [--step <percent>]")
			return nil
		case "--width":
			width, args = nextInt(args, width)
		case "--label":
			label, args = nextArg(args)
		case "--style", "--bar":
			style, args = nextArg(args)
		case "--spinner":
			spinner, args = nextArg(args)
		case "--delay":
			delay, args = nextDuration(args, delay)
		case "--step":
			step, args = nextInt(args, step)
		case "--fill", "--filled":
			fill, args = nextArg(args)
			fillSet = true
		case "--empty":
			empty, args = nextArg(args)
			emptySet = true
		default:
			if strings.HasPrefix(args[0], "--") {
				return fmt.Errorf("unknown option: %s", args[0])
			}
			if label == "" || label == "transfer" {
				label = args[0]
			}
			args = args[1:]
		}
	}

	return progressExample(t, label, style, spinner, fill, empty, width, delay, step, fillSet, emptySet)
}

func progressDefaultStyle() string {
	return "bar"
}

func progressDefaultSpinner() string {
	return "braille"
}

func progressDefaultWidth() int {
	return 20
}

func progressDefaultStep() int {
	return 5
}

func progressDefaultDelay() time.Duration {
	return 40 * time.Millisecond
}

func progressExample(t theme, label, style, spinner, fill, empty string, width int, delay time.Duration, step int, fillSet, emptySet bool) error {
	if label == "" {
		label = "transfer"
	}
	if step <= 0 {
		step = progressDefaultStep()
	}
	for current := 0; current < 100; current += step {
		renderProgress(t, current, 100, width, label, style, spinner, fill, empty, true, fillSet, emptySet)
		time.Sleep(delay)
	}
	renderProgress(t, 100, 100, width, label, style, spinner, fill, empty, true, fillSet, emptySet)
	return nil
}

func renderProgress(t theme, current, total, width int, label, style, spinner, fill, empty string, transient bool, fillSet, emptySet bool) {
	if total <= 0 {
		total = 1
	}
	if width <= 0 {
		width = progressDefaultWidth()
	}
	if current < 0 {
		current = 0
	}
	if current > total {
		current = total
	}
	percent := current * 100 / total
	done := percent >= 100
	filled := width * current / total
	switch style {
	case "block", "blocks", "squares":
		style = "blocks"
		if fill == "" {
			fill = "▰"
		}
		if empty == "" {
			empty = "▱"
		}
	case "compact", "dots", "dot":
		style = "dots"
		if fill == "" {
			fill = "●"
		}
		if empty == "" {
			empty = "·"
		}
	default:
		style = "bar"
		if fill == "" {
			fill = "█"
		}
		if empty == "" {
			empty = "-"
		}
	}
	if t.plain {
		if !fillSet {
			fill = "#"
		}
		if !emptySet {
			empty = "-"
		}
		if style == "dots" {
			if !fillSet {
				fill = "o"
			}
			if !emptySet {
				empty = "."
			}
		}
	}
	bar := strings.Repeat(fill, filled) + strings.Repeat(empty, width-filled)
	if style == "bar" {
		bar = "[" + bar + "]"
	}
	prefix := "  "
	if spinner != "none" && spinner != "off" && spinner != "false" && spinner != "0" {
		frame := progressSpinnerFrame(t, spinner, percent, done)
		prefix += t.paint(progressMarkerColor(t, done), frame) + " "
	}
	if label != "" {
		if done {
			prefix += t.paint(t.muted, label) + " "
		} else {
			prefix += t.badge(label, "hint") + " "
		}
	}
	line := fmt.Sprintf("%s%s %s", prefix, t.paint(progressColor(t, done), bar), t.paint(progressPercentColor(t, done), fmt.Sprintf("%d%%", percent)))
	if transient && t.canAnimate() {
		if done {
			fmt.Print("\r" + line + "\n")
			return
		}
		fmt.Print("\r" + line)
		return
	}
	fmt.Println(line)
}

func (t theme) canAnimate() bool {
	if t.plain || os.Getenv("TERM") == "dumb" {
		return false
	}
	info, err := os.Stdout.Stat()
	if err != nil {
		return false
	}
	return (info.Mode() & os.ModeCharDevice) != 0
}

func progressColor(t theme, done bool) string {
	if done {
		return t.muted
	}
	return t.hint
}

func progressPercentColor(t theme, done bool) string {
	if done {
		return t.muted
	}
	return t.muted
}

func progressMarkerColor(t theme, done bool) string {
	if done {
		return t.ok
	}
	return t.hint
}

func progressSpinnerFrame(t theme, spinner string, percent int, done bool) string {
	if done {
		return "[✔ ]"
	}
	if spinner == "line" || spinner == "ascii" {
		frames := []string{"-", "\\", "|", "/"}
		return frames[percent%len(frames)]
	}
	if t.plain {
		return "."
	}
	frames := strings.Fields("⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏")
	if len(frames) == 0 {
		return "⠋"
	}
	return frames[percent%len(frames)]
}

func cmdSpinner(t theme, args []string) error {
	title := "Working"
	for len(args) > 0 {
		if args[0] == "--title" || args[0] == "--label" {
			title, args = nextArg(args)
			continue
		}
		if args[0] == "--" {
			args = args[1:]
			break
		}
		break
	}
	if len(args) == 0 {
		fmt.Println("  " + t.paint(t.hint, "◌") + " " + t.badge("loading", "hint") + " " + t.paint(t.title, title))
		return nil
	}

	cmd := exec.Command(args[0], args[1:]...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Start(); err != nil {
		return err
	}
	done := make(chan error, 1)
	go func() { done <- cmd.Wait() }()
	frames := []string{"◜", "◠", "◝", "◞", "◡", "◟"}
	if t.plain {
		frames = []string{"-", "\\", "|", "/"}
	}
	i := 0
	for {
		select {
		case err := <-done:
			fmt.Fprint(os.Stderr, "\r"+strings.Repeat(" ", len(title)+8)+"\r")
			return err
		case <-time.After(120 * time.Millisecond):
			fmt.Fprintf(os.Stderr, "\r  %s %s %s", t.paint(t.hint, frames[i%len(frames)]), t.badge("loading", "hint"), t.paint(t.title, title))
			i++
		}
	}
}

func cmdInput(t theme, args []string) error {
	prompt := "Input"
	def := ""
	required := false
	for len(args) > 0 {
		switch args[0] {
		case "--prompt":
			prompt, args = nextArg(args)
		case "--default":
			def, args = nextArg(args)
		case "--required":
			required = true
			args = args[1:]
		default:
			prompt = args[0]
			args = args[1:]
		}
	}
	if os.Getenv("AIR_NON_INTERACTIVE") == "1" {
		if def != "" || !required {
			fmt.Println(def)
			return nil
		}
		return fmt.Errorf("%s requires a value", prompt)
	}
	fmt.Fprintf(os.Stderr, "  %s %s", t.paint(t.hint, "?"), t.paint(t.title, prompt))
	if def != "" {
		fmt.Fprintf(os.Stderr, " %s", t.badge(def, "hint"))
	}
	fmt.Fprintf(os.Stderr, "\n  %s ", t.paint(t.muted, "›"))
	value, _ := bufio.NewReader(os.Stdin).ReadString('\n')
	value = strings.TrimSpace(value)
	if value == "" {
		value = def
	}
	if value == "" && required {
		return fmt.Errorf("value required")
	}
	fmt.Println(value)
	return nil
}

func cmdConfirm(args []string) error {
	title := "Continue?"
	def := "no"
	for len(args) > 0 {
		switch args[0] {
		case "--title", "--message":
			title, args = nextArg(args)
		case "--default":
			def, args = nextArg(args)
		default:
			args = args[1:]
		}
	}
	if os.Getenv("AIR_YES") == "1" {
		return nil
	}
	suffix := "y/N"
	if def == "yes" {
		suffix = "Y/n"
	}
	fmt.Fprintf(os.Stderr, "  %s [%s] ", title, suffix)
	value, _ := bufio.NewReader(os.Stdin).ReadString('\n')
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		value = def
	}
	if value == "y" || value == "yes" {
		return nil
	}
	return fmt.Errorf("cancelled")
}

func cmdSelect(args []string) error {
	prompt := "Select"
	def := ""
	options := []string{}
	for len(args) > 0 {
		switch args[0] {
		case "--prompt":
			prompt, args = nextArg(args)
		case "--default":
			def, args = nextArg(args)
		case "--option":
			var value string
			value, args = nextArg(args)
			options = append(options, value)
		default:
			options = append(options, args[0])
			args = args[1:]
		}
	}
	if os.Getenv("AIR_NON_INTERACTIVE") == "1" {
		fmt.Println(def)
		if def == "" {
			return fmt.Errorf("default required in non-interactive mode")
		}
		return nil
	}
	fmt.Fprintln(os.Stderr, "  "+prompt)
	for i, option := range options {
		fmt.Fprintf(os.Stderr, "    %d) %s\n", i+1, option)
	}
	fmt.Fprintf(os.Stderr, "  Select [%s]: ", fallback(def, "1"))
	value, _ := bufio.NewReader(os.Stdin).ReadString('\n')
	value = strings.TrimSpace(value)
	if value == "" {
		value = fallback(def, "1")
	}
	if idx, err := strconv.Atoi(value); err == nil && idx > 0 && idx <= len(options) {
		fmt.Println(options[idx-1])
		return nil
	}
	fmt.Println(value)
	return nil
}

func cmdMultiSelect(args []string) error {
	if os.Getenv("AIR_NON_INTERACTIVE") == "1" {
		for len(args) > 0 {
			if args[0] == "--default" || args[0] == "--defaults" {
				value, _ := nextArg(args)
				fmt.Println(value)
				return nil
			}
			args = args[1:]
		}
		return fmt.Errorf("default required in non-interactive mode")
	}
	return cmdSelect(args)
}

func nextArg(args []string) (string, []string) {
	if len(args) < 2 {
		return "", nil
	}
	return args[1], args[2:]
}

func nextInt(args []string, fallback int) (int, []string) {
	value, rest := nextArg(args)
	parsed, err := strconv.Atoi(value)
	if err != nil {
		return fallback, rest
	}
	return parsed, rest
}

func nextDuration(args []string, fallback time.Duration) (time.Duration, []string) {
	value, rest := nextArg(args)
	parsed, err := strconv.ParseFloat(value, 64)
	if err != nil || parsed < 0 {
		return fallback, rest
	}
	return time.Duration(parsed * float64(time.Second)), rest
}

func severityColor(t theme, severity string) string {
	switch severity {
	case "ok", "success":
		return t.ok
	case "warning", "warn":
		return t.warn
	case "error", "blocked":
		return t.err
	default:
		return t.hint
	}
}

func fallback(value, def string) string {
	if value == "" {
		return def
	}
	return value
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
