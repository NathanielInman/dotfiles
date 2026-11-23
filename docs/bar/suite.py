"""The suite behind the bar, as the apps describe themselves.

Each app keeps a `suite.toml` beside the hero.py that apps.py runs (its
name, repo, language, bar module, what it replaced, its stow package and
how to install it). build.py reads them all and writes the parts of the
README that are about the suite: the counts and the list in the opening
bullets, the suite table and each app's install steps. So a new app, or a
change to one, reaches the README through its own repo, and the README
never holds a count someone has to remember to change.

`problems()` is what `build.py --check` runs: every way the README and the
docs have drifted from the bar and the apps before, as one sentence each.
"""

import re
import subprocess
import tomllib
from dataclasses import dataclass, field
from pathlib import Path

from apps import APPS, HEROES

ROOT = Path(__file__).resolve().parents[2]
README = ROOT / "README.md"
# Where an app keeps its suite.toml: beside its hero.py.
PLACES = ("docs/assets", "artwork/hero")
# Words that make a line about a retired script fine: it says it was replaced.
REPLACED = re.compile(r"replac|retir|in place of|instead of", re.I)
# Docs whose prose is checked for retired names. Generated blocks are skipped.
PROSE = ["README.md", "docs/*.md", "docs/bar/README.md", "rebuild/README.md"]


@dataclass
class App:
    name: str
    repo: str
    language: str
    module: str
    purpose: str
    lamp: str
    retired: list[str]
    stow: str
    install: list[str]
    check: list[str]
    root: Path  # the app's checkout
    hero: Path  # its hero.py
    # Where it builds today, and where a port still has to take it. The suite
    # targets Linux, Windows and macOS.
    platforms: list[str] = field(default_factory=list)
    planned: list[str] = field(default_factory=list)

    @property
    def slug(self) -> str:
        return self.root.name


def load() -> list[App]:
    """Every suite.toml in the checkouts beside dot-files."""
    out = []
    for place in PLACES:
        for path in sorted(APPS.glob(f"*/{place}/suite.toml")):
            data = tomllib.loads(path.read_text(encoding="utf-8"))
            out.append(App(**data, root=path.parents[len(Path(place).parts)], hero=path.with_name("hero.py")))
    return out


def in_bar_order(apps: list[App], order: list[str]) -> list[App]:
    rank = {m: i for i, m in enumerate(order)}
    return sorted(apps, key=lambda a: rank.get(a.module, len(rank)))


# ------------------------------------------------------------ counting

def _files(root: Path, language: str) -> list[Path]:
    ext = {"Rust": "*.rs", "Go": "*.go"}[language]
    return [p for p in root.rglob(ext) if not {"target", "vendor", "node_modules", ".git"} & set(p.parts)]


# Crates the apps share from repos of their own, counted with the suite.
SHARED = ["bar-anchor"]


def size(apps: list[App]) -> tuple[int, int]:
    """Lines of code and tests across the suite and its shared crates."""
    lines = tests = 0
    trees = [(a.root, a.language) for a in apps] + [(APPS / s, "Rust") for s in SHARED if (APPS / s).is_dir()]
    for root, language in trees:
        for p in _files(root, language):
            text = p.read_text(encoding="utf-8", errors="replace")
            lines += text.count("\n")
            tests += len(re.findall(r"#\[(?:tokio::)?test\]" if language == "Rust" else r"^func Test", text, re.M))
    return lines, tests


WORDS = "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty".split()


def words(n: int) -> str:
    return WORDS[n] if n < len(WORDS) else str(n)


def listing(items: list[str]) -> str:
    return items[0] if len(items) == 1 else ", ".join(items[:-1]) + " and " + items[-1]


# ------------------------------------------------------------ the README

def summary(apps: list[App], widgets: int, scripts: int, others: list[str], toured: bool) -> str:
    """The two opening bullets about the suite."""
    langs = {}
    for a in apps:
        langs.setdefault(a.language, []).append(a)
    lines, tests = size(apps)
    if len(langs) == 1:
        built = f"All {words(len(apps))} are {next(iter(langs))}"
    else:
        main = max(langs, key=lambda k: len(langs[k]))
        rest = [f"{a.slug} ({a.name}) is {lang}" if a.slug != a.name.lower() else f"{a.name} is {lang}"
                for lang, xs in langs.items() if lang != main for a in xs]
        built = f"{words(len(langs[main])).capitalize()} are {main} and {listing(rest)}"
    others = ([f"{words(scripts)} shell script{'s' * (scripts != 1)}"] if scripts else []) + others
    suite = listing([f"[{a.name}]({a.repo}) for {a.purpose}" for a in apps])
    return (
        f"- **A bar of real programs.** {words(len(apps)).capitalize()} of the bar's {words(widgets)} widgets are apps "
        "with their own repos: a `bar` command that waybar runs, and a drawer or board that opens from the lamp. "
        f"{built}, over {lines // 10000 * 10000:,} lines and {tests // 50 * 50} tests between them. "
        f"The rest are {listing(others)}, small enough to drop into your own waybar, and the table says what each one needs.\n"
        f"- **[A suite behind the bar](#the-suite).** {suite}. "
        + ("The tour above opens each one." if toured else "The tour above opens most of them.")
        + " "
    )


PLATFORM_NAMES = {"linux": "Linux", "windows": "Windows", "macos": "macOS"}


def runs_on(a: App) -> str:
    """"Linux, Windows, macOS", or "Linux (Windows, macOS planned)"."""
    now = listing([PLATFORM_NAMES.get(p, p) for p in a.platforms]).replace(" and ", ", ")
    if a.planned:
        return f"{now} ({', '.join(PLATFORM_NAMES.get(p, p) for p in a.planned)} planned)"
    return now


def section(apps: list[App]) -> str:
    """The suite table and each app's install steps."""
    rows = ["| App | In the bar | Replaced | Built in | Runs on | Stow here |", "|---|---|---|---|---|---|"]
    for a in apps:
        retired = ", ".join(f"`{r}`" for r in a.retired)
        stow = f"`{a.stow}`" if a.stow else ""
        rows.append(f"| [{a.name}]({a.repo}) | {a.lamp} | {retired} | {a.language} | {runs_on(a)} | {stow} |")
    out = [
        f"{words(len(apps)).capitalize()} of the widgets are front ends for apps that live in their own repos. "
        "Each app describes itself in a `suite.toml` beside its README hero, and `docs/bar/build.py` writes this "
        "section from those files, so it changes when an app does.",
        "",
        *rows,
        "",
        "Install an app, then stow its package here if it has one. Each block runs from a clean Arch install:",
        "",
    ]
    for a in apps:
        steps = list(a.install)
        if a.stow:
            steps.append(f"cd ~/Sites/dot-files && ./install.sh {a.stow}")
        steps += a.check
        out += [f"<details><summary>{a.name}</summary>", "", "```bash", *steps, "```", "", "</details>", ""]
    return "\n".join(out).rstrip() + "\n"


def replace_block(text: str, name: str, body: str) -> str | None:
    start, end = f"<!-- {name}:start -->", f"<!-- {name}:end -->"
    if start not in text or end not in text:
        return None
    a, b = text.index(start) + len(start), text.index(end)
    return text[:a] + "\n" + body + text[b:]


def without_blocks(text: str) -> str:
    """The text with every generated block blanked out, line count kept."""
    def blank(m):
        return "\n" * m.group(0).count("\n")
    return re.sub(r"<!-- ([\w-]+):start -->.*?<!-- \1:end -->", blank, text, flags=re.S)


# ------------------------------------------------------------ checks

def app_modules(config: dict) -> dict[str, str]:
    """Bar modules run by an app's own `bar` command: module -> binary."""
    out = {}
    for name, block in config.items():
        m = re.search(r"([\w-]+) bar$", str(block.get("exec", ""))) if isinstance(block, dict) else None
        if m:
            out[name] = m.group(1)
    return out


def packages_table() -> set[str]:
    text = README.read_text(encoding="utf-8")
    m = re.search(r"^## Packages\n(.*?)^## ", text, re.S | re.M)
    return set(re.findall(r"^\|[^|\n]*\| `([\w-]+)` \|", m.group(1) if m else "", re.M))


def retired_mentions(apps: list[App]) -> list[str]:
    out = []
    files = sorted({p for pat in PROSE for p in ROOT.glob(pat)})
    for path in files:
        text = without_blocks(path.read_text(encoding="utf-8"))
        for n, line in enumerate(text.splitlines(), 1):
            if REPLACED.search(line):
                continue
            for a in apps:
                for r in a.retired:
                    if re.search(rf"(?<![\w-]){re.escape(r)}(?![\w-])", line):
                        out.append(f"{path.relative_to(ROOT)}:{n} still mentions {r}, which {a.name} replaced; "
                                   "describe what runs now, or say it was replaced")
    return out


def flatten(config: dict, names: list[str]) -> list[str]:
    """Module names with every group opened up."""
    out = []
    for n in names:
        out += flatten(config, config.get(n, {}).get("modules", [])) if n.startswith("group/") else [n]
    return out


def screenshot(modules: list[str], parse) -> str | None:
    """Pictures/desktop.png shows the bar as it was when it was committed."""
    def git(*args):
        return subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True).stdout
    sha = git("log", "-1", "--format=%H", "--", "Pictures/desktop.png").strip()
    if not sha:
        return None
    then = parse(git("show", f"{sha}:packages/waybar/.config/waybar/config.jsonc"))
    was = set(flatten(then, then.get("modules-right", [])))
    added = [m for m in modules if m not in was]
    if added:
        return (f"Pictures/desktop.png predates {listing(added)} in the bar; "
                "retake it and update its alt text in README.md")
    return None


def problems(apps, config, beats, parse, fresh: str) -> tuple[list[str], list[str]]:
    """(errors, warnings). Errors fail `build.py --check`; warnings are
    reported but need a person (a screenshot)."""
    errors, warnings = [], []
    by_module = {a.module: a for a in apps}
    for module, binary in app_modules(config).items():
        if module not in by_module:
            errors.append(f"config.jsonc: {module} runs `{binary} bar`, but no app beside dot-files has a "
                          f"suite.toml for it; add one beside its hero.py")
    for a in apps:
        if not a.platforms:
            errors.append(f"{a.root.name}/suite.toml has no platforms; list where it builds today")
        if a.module not in config:
            errors.append(f"{a.root.name}/suite.toml names {a.module}, which is not in config.jsonc")
        if a.hero.resolve() not in {(APPS / h).resolve() for h in HEROES.values()}:
            errors.append(f"apps.py does not draw {a.name}'s panel; add {a.hero.relative_to(APPS)} to HEROES")
        touched = any(a.module in b.set or b.click == a.module for b in beats)
        if not touched:
            errors.append(f"story.py: no beat clicks or changes {a.module}, so the tour skips {a.name}")
    have = {p.name for p in (ROOT / "packages").iterdir() if p.is_dir()}
    listed = packages_table()
    for p in sorted(have - listed):
        errors.append(f"README.md: packages/{p} has no row in the Packages table")
    for p in sorted(listed - have):
        errors.append(f"README.md: the Packages table lists {p}, which is not in packages/")
    for a in apps:
        if a.stow and a.stow not in have:
            errors.append(f"{a.root.name}/suite.toml stows {a.stow}, which is not in packages/")
    errors += retired_mentions(apps)
    text = README.read_text(encoding="utf-8")
    for name in ("bar-widgets", "suite-summary", "suite"):
        if f"<!-- {name}:start -->" not in text or f"<!-- {name}:end -->" not in text:
            errors.append(f"README.md has lost its <!-- {name}:start --> / <!-- {name}:end --> markers")
    if README.read_text(encoding="utf-8") != fresh:
        errors.append("README.md is out of date with the bar or the apps; run python3 docs/bar/build.py")
    shot = screenshot(flatten(config, config.get("modules-right", [])), parse)
    if shot:
        warnings.append(shot)
    return errors, warnings
