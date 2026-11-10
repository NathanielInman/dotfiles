# The bar, drawn

The animation at the top of the main README and the strips in its widget
table are generated, not screenshots. `build.py` draws the waybar from the
real config, so the order, spacing and colors match the bar on the desk.

```sh
python3 docs/bar/build.py                  # writes Pictures/bar/ and the README table
python3 docs/bar/preview.py 2.5 19.8       # PNGs of the hero at those seconds
python3 docs/bar/preview.py --svg Pictures/bar/widgets/pomodoro.svg 0 2
```

Needs Python with fontTools and the `ttf-jetbrains-mono-nerd` package (the
glyphs are a subset of JetBrains Mono Nerd Font, embedded in each SVG).
`preview.py` also needs Chrome or Chromium. Set `BAR_FONT` to use another
font file.

## What comes from where

| Input | Gives |
|---|---|
| `packages/waybar/.config/waybar/config.jsonc` | Which modules exist and their order, the workspace icons. |
| `packages/waybar/.config/waybar/style.css` | Every color: `#custom-pomodoro.work` colors the pomodoro in its `work` state, the same rule waybar uses. |
| [`widgets.py`](widgets.py) | What each module prints in each state, its name and the sentence in the README table. |
| [`story.py`](story.py) | The hero's timeline: camera moves, clicks, state changes, captions. |

## Adding a widget

1. Add the module to the bar as usual (`config.jsonc`, `style.css`, its
   script). `build.py` now stops and names the module it does not know.
2. Add an entry to `WIDGETS` in `widgets.py`, keyed by the module's name in
   `config.jsonc`:

   ```python
   "custom/weather": Widget(
       "Weather",
       "Today's forecast from wttr.in. Click for the week.",
       f"{WAYBAR}/scripts/weather.sh",
       states={
           "clear": State("\ue30d 18\u00b0", "clear"),
           "rain": State("\ue318 11\u00b0", "rain"),
       },
       default="clear",
   ),
   ```

   A state's text is exactly what the script prints (an empty string hides
   the module, as in waybar), and its class is the one the script sets, so
   the color comes from `style.css`. Write glyphs as `\u` escapes so the
   file stays readable in any editor. `ticking()` makes a counting timer.
3. Optionally give it a moment in the hero: add beats to `BEATS` in
   `story.py` (and widen `LOOP` if the story gets longer). A beat can zoom
   the camera to the module, click it, change states and show a caption.
   Every module must be back in its default state by the end of the loop;
   `build.py` says which one is not.
4. Run `build.py`, look at a few moments with `preview.py`, and commit the
   changed files under `Pictures/bar/` with the README.

## Scenes

Some beats trigger effects that are drawn by hand in `build.py` rather than
from a module: `type` (dictated words appear in the editor), `drawer-open` /
`drawer-close` (Roundhouse's drawer over the lamp) and `lights-on` /
`lights-off` (the room warms up with the key lights). A new kind of effect
is a function in `build.py` called from `hero()`.
