# The bar, drawn

The animation at the top of the main README and the strips in its widget
table are generated, not screenshots. `build.py` draws the waybar from the
real config, so the pills, the order, the padding and the colors match the
bar on the desk. The panels the bar opens are drawn by the apps themselves:
each app's README hero keeps its panel's code where this build can run it.

```sh
python3 docs/bar/build.py                  # writes Pictures/bar/ and the README's generated parts
python3 docs/bar/build.py --check          # writes nothing; says what has drifted
python3 docs/bar/preview.py 2.5 19.8       # PNGs of the hero at those seconds
python3 docs/bar/preview.py --svg Pictures/bar/widgets/timetable.svg 0 2
```

Needs Python with fontTools, the `ttf-jetbrains-mono-nerd` package (the
bar's glyphs are a subset of JetBrains Mono Nerd Font, embedded in each
SVG), and the apps checked out beside dot-files (`~/Sites/roundhouse` and so
on; `BAR_APPS=<dir>` points somewhere else). `preview.py` also needs
Chrome or Chromium. Set `BAR_FONT` to use another font file.

## What comes from where

| Input | Gives |
|---|---|
| `packages/waybar/.config/waybar/config.jsonc` | The pills (each group, or a module on its own), the module order, the drawer group and which side it opens to, the bar's height, margins and spacing, the workspace glyphs and the window title rewrites. |
| `packages/waybar/.config/waybar/style.css` | The font size, the pill color and border, each module's padding, and every color: `#custom-timetable.soon` colors the clock in its `soon` state, the same rule waybar uses. A class with an `animation` pulses. |
| [`widgets.py`](widgets.py) | What each module prints in each state, its name and the sentence in the README table. |
| [`story.py`](story.py) | The hero's timeline: camera moves, clicks, state changes, panels opening, captions. |
| [`apps.py`](apps.py) | The panels: Roundhouse's drawer, Switchyard's board, Signal Box and broker's request window, Tannoy's player, Logbook's drawer, Timetable's drawer, Tablet's drawer, Waybill's drawer and Layover's drawer, each drawn by the app's own `hero.py`. |
| Each app's `suite.toml` ([`suite.py`](suite.py)) | The README's counts and list of the suite, the suite table (what each lamp shows, what the app replaced, its language and stow package) and each app's install steps. It sits beside the app's `hero.py`. |
| [`scenes.py`](scenes.py) | Which states of each panel the tour shows, which module each springs out of, and the swaync notification. |
| [`svgkit.py`](svgkit.py) | The embedded font, the SVG builder and its keyframes. |

The desktop is 1792x1008, so the bar is drawn at waybar's real 15px on a
screen it fits; the camera zooms in to a module or frames an open panel.

## Keeping the README honest

The README's counts, its list of the suite, the widget table and the suite
section are all written by `build.py`, so nothing in them is typed by hand.
`build.py --check` writes nothing and says, one line each, where the repo
has drifted from the bar and the apps:

- a module that runs `<app> bar` with no `suite.toml` for it, or a
  `suite.toml` whose module is not in the bar;
- an app whose panel `apps.py` doesn't draw, or that no beat in `story.py`
  clicks or changes;
- a directory in `packages/` with no row in the Packages table;
- a script or program an app replaced (its `retired` list) still named in
  the README or `docs/`, outside a line that says it was replaced;
- a README that `build.py` would write differently;
- and, as a warning only, a desktop screenshot older than the bar's modules.

It runs before each commit once a clone turns the hook on
(`git config core.hooksPath .githooks`; `rebuild/` does it), and each night
from `scripts/cron-dotfiles-drift.sh`, which files what it finds as a
Waybill task in the `dotfiles` project.

## Adding an app

Give the app a `suite.toml` beside its `hero.py` (copy one from a sibling:
name, repo, language, its module, the lamp in a sentence, what it retired,
its stow package and its install steps), add its hero to `HEROES` in
`apps.py`, then add its widget and its beats as below. `--check` names
whatever is still missing.

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
           "clear": State(" 18°", "clear"),
           "rain": State(" 11°", "rain"),
       },
       default="clear",
   ),
   ```

   A state's text is exactly what the script prints (an empty string hides
   the module, as in waybar), and its class is the one the script sets, so
   the color comes from `style.css`. `tail` is text drawn after it in the
   module's own color (Timetable's date and time), and `art` names a cover
   for the media pill. Write glyphs as `\u` escapes so the file stays
   readable in any editor. `ticking()` makes a counting timer. An entry
   with an empty sentence gets no strip or table row (the drawer's arrow,
   Tannoy's cover).
3. Optionally give it a moment in the hero: add beats to `BEATS` in
   `story.py` (and widen `LOOP` if the story gets longer). A beat can zoom
   the camera to the module, click it, change states and show a caption.
   Keep the camera to one move per app: frame the panel
   (`camera="panel:weather"`) before its lamp changes and stay there.
   Every module must be back in its default state by the end of the loop;
   `build.py` says which one is not. It also stops if a state's text is
   long enough to push the bar's right side into its left.
4. Run `build.py`, look at a few moments with `preview.py`, and commit the
   changed files under `Pictures/bar/` with the README.

## Panels

A beat opens a panel with `open=("tannoy", "song")`, switches it with
`look=("tannoy", "podcast")`, and closes it with `close="tannoy"`. A click
on `"tannoy:chip:Chrome"` lands on a spot the app's own hero names; the
build says which spots a look has when one is wrong. `camera="panel:tannoy"`
frames the panel (open, or opening at that beat) with room for a caption.

Each app's `hero.py` keeps its panel above a line that reads
`# ---- end of the panel ----`, and `apps.py` runs only that part. So a
change to an app's interface goes into its own hero first, and this tour
picks it up on the next build. To show a new state, add a function to
`apps.py` if the app's panel needs one, then a key in `scenes.LOOKS`.

## Scenes

Some beats trigger effects that are not a module or a panel:

- `type`: dictated words appear in the editor.
- `toast` / `toast-dismiss`: a swaync notification slides in at the top
  right, styled from `packages/swaync/.config/swaync/style.css`, and out.
- `lights-on` / `lights-off`: the room warms up with the key lights.

A drawer group opens and closes like a module changes state:
`set={"group/desk-drawer": "open"}`, usually with a `hover` on its arrow.
