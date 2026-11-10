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
| [`scenes.py`](scenes.py) | Roundhouse's drawer and Switchyard's board, drawn as their own READMEs draw them, with the spots a beat can click. |
| [`svgkit.py`](svgkit.py) | The embedded font, the SVG builder and its keyframes. |

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

Some beats trigger effects that are not a module's text:

- `type`: dictated words appear in the editor.
- `board-open` / `board-close`: Switchyard's board springs out of its signal.
  Its story is `storefront-build`, `android-queue`, `android-held`,
  `storefront-done` and `android-build`.
- `drawer-open`: Roundhouse's drawer springs out of the lamp. `handoff`
  closes it and opens the board from the same lamp, as its Switchyard link
  does.
- `lights-on` / `lights-off`: the room warms up with the key lights.

A beat can click inside an open panel by name (`board:storefront`,
`drawer:switchyard`); the spots are `BOARD_SPOTS` and `DRAWER_SPOTS` in
`scenes.py`. If Roundhouse or Switchyard change their interface, update
`scenes.py` from their `docs/assets/hero.py`. A new kind of effect is a
function in `scenes.py` called from `draw_panels()` or `hero()` in
`build.py`.
