#!/usr/bin/env python3
"""Checks for a /presentation explainer. Standard library only.

    python3 -I check.py <explainer.html> [--audience private|internal|external]
                                         [--render <dir>] [--chrome <path>]

Static checks: HTML tag balance, every inline <svg> parses as XML, no external
assets, scene count and words per scene, one diagram per scene, a closing
slide, reduced-motion and dark-mode rules present, no .token moving along an
.edge.unknown, and a secrets/PII pattern scan.

--render <dir> also drives headless Chrome over every scene in light, dark,
narrow and reduced-motion, writes one PNG per scene and mode into <dir>, and
reports any JS error the page recorded. Look at the PNGs: overlap is a human
judgement, not something this script can make.

Exit status: 0 clean, 1 problems found, 2 could not run.
Hits from the scan are printed redacted, so the report is safe to paste.
"""
import argparse
import html.parser
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.parse
import xml.etree.ElementTree as ET

VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link",
        "meta", "source", "track", "wbr"}
# Elements HTML lets you leave unclosed. Treated as balanced either way.
OPTIONAL_END = {"li", "p", "dt", "dd", "tr", "td", "th", "option", "thead",
                "tbody", "tfoot", "colgroup", "rt", "rp", "optgroup"}

SCAN = [
    ("GitHub token", r"\bgh[pousr]_[A-Za-z0-9]{20,}"),
    ("GitHub fine-grained token", r"\bgithub_pat_[A-Za-z0-9_]{20,}"),
    ("AWS access key id", r"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b"),
    ("PEM block", r"-----BEGIN [A-Z ]+-----"),
    ("Slack token", r"\bxox[abposr]-[A-Za-z0-9-]{8,}"),
    ("Slack webhook", r"hooks\.slack\.com/[A-Za-z0-9/_-]+"),
    ("Stripe live key", r"\b[sr]k_live_[A-Za-z0-9]{8,}"),
    ("Webhook secret", r"\bwhsec_[A-Za-z0-9]{8,}"),
    ("JWT", r"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}(?:\.[A-Za-z0-9_-]+)?"),
    ("32+ char hex", r"\b[0-9a-fA-F]{32,}\b"),
    ("32+ char base64", r"(?<![A-Za-z0-9+/_-])(?=[A-Za-z0-9+/_-]*[0-9])(?=[A-Za-z0-9+/_-]*[a-z])"
                        r"(?=[A-Za-z0-9+/_-]*[A-Z])[A-Za-z0-9+/_-]{32,}={0,2}"),
    ("Email address", r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"),
    ("Local path", r"(?:/Users/|/home/|/private/tmp/|/private/var/|(?<![\w.])/tmp/|/var/folders/|[A-Za-z]:\\Users\\)"),
    ("Private/DM marker", r"(?i)private\s*[—–-]+\s*DM|\bDM excerpt"),
]

CHROME_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    "google-chrome", "google-chrome-stable", "chromium", "chromium-browser",
]

# name, viewport width, viewport height, query. Screenshots use motion=reduce so
# each one shows the scene's end state, which is what overlap is judged on; a
# mid-animation frame would hide half the diagram. 1280x680 is a laptop window
# once the browser's own chrome is taken off.
MODES = [
    ("light", 1280, 680, "theme=light&motion=reduce"),
    ("dark", 1280, 680, "theme=dark&motion=reduce"),
    ("narrow", 390, 760, "theme=light&motion=reduce"),
]

# Headless Chrome will not make a window narrower than 500px and takes the
# window's own chrome off --window-size, so the page is framed at an exact
# viewport instead; an iframe gets its own viewport and media queries.
FRAME = """<!doctype html><meta charset="utf-8">
<style>html,body{{margin:0;background:#888}}iframe{{border:0;display:block;width:{w}px;height:{h}px}}</style>
<iframe src="{src}"></iframe>"""


class Problems:
    def __init__(self):
        self.errors, self.warnings, self.info = [], [], []

    def err(self, m): self.errors.append(m)
    def warn(self, m): self.warnings.append(m)
    def note(self, m): self.info.append(m)


class Balance(html.parser.HTMLParser):
    def __init__(self, p):
        super().__init__(convert_charrefs=True)
        self.p, self.stack = p, []
        self.scenes = []          # [{title, closing, svgs, words}]
        self._in_scene = 0        # depth of the stack where the scene opened
        self._in_svg = 0
        self._in_say = False

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag in VOID:
            return
        if tag == "section" and "scene" in (a.get("class") or "").split():
            self.scenes.append({"title": a.get("data-title") or "(untitled)",
                                "closing": "data-closing" in a, "svgs": 0, "words": 0,
                                "line": self.getpos()[0]})
            self._in_scene = len(self.stack) + 1
        if tag == "svg":
            if self._in_svg == 0 and self.scenes and self._in_scene:
                self.scenes[-1]["svgs"] += 1
            self._in_svg += 1
        if tag == "p" and "say" in (a.get("class") or "").split() and self._in_scene:
            self._in_say = True
        self.stack.append((tag, self.getpos()[0]))

    def handle_startendtag(self, tag, attrs):
        pass  # <path/> and friends are self-contained

    def handle_endtag(self, tag):
        if tag in VOID:
            return
        if tag == "svg":
            self._in_svg = max(0, self._in_svg - 1)
        if tag == "p":
            self._in_say = False
        while self.stack and self.stack[-1][0] != tag and self.stack[-1][0] in OPTIONAL_END:
            self.stack.pop()
        if not self.stack or self.stack[-1][0] != tag:
            self.p.err(f"line {self.getpos()[0]}: </{tag}> does not close "
                       f"<{self.stack[-1][0]}> from line {self.stack[-1][1]}" if self.stack
                       else f"line {self.getpos()[0]}: stray </{tag}>")
            # Recover: pop to the matching open tag if there is one.
            for k in range(len(self.stack) - 1, -1, -1):
                if self.stack[k][0] == tag:
                    del self.stack[k:]
                    break
            return
        self.stack.pop()
        if self._in_scene and len(self.stack) < self._in_scene:
            self._in_scene = 0

    def handle_data(self, data):
        if self._in_say and not self._in_svg:
            self.scenes[-1]["words"] += len(data.split())

    def finish(self):
        self.close()
        for tag, line in self.stack:
            if tag not in OPTIONAL_END:
                self.p.err(f"line {line}: <{tag}> is never closed")


def line_of(text, pos):
    return text.count("\n", 0, pos) + 1


def redact(s):
    s = s.strip()
    return s if len(s) <= 8 else s[:4] + "…" + f"({len(s)} chars)"


def static_checks(path, text, audience, p):
    b = Balance(p)
    b.feed(text)
    b.finish()

    # SVGs must be XML: no HTML entities, every element closed, attributes quoted.
    for n, m in enumerate(re.finditer(r"<svg\b.*?</svg>", text, re.S), 1):
        try:
            ET.fromstring(m.group(0))
        except ET.ParseError as e:
            p.err(f"svg #{n} (line {line_of(text, m.start())}) is not valid XML: {e}")

    # Nothing may load from outside the file. Plain <a href> links are fine.
    ext = [
        (r"<script\b[^>]*\bsrc\s*=", "external <script src>"),
        (r"<link\b[^>]*\bhref\s*=", "<link href> (stylesheet, font or icon)"),
        (r"<(?:img|image|iframe|video|audio|source|object|embed|use)\b[^>]*\b(?:src|href|xlink:href)\s*=\s*[\"']?(?:https?:)?//", "external media"),
        (r"@import\b", "CSS @import"),
        (r"url\(\s*[\"']?(?:https?:)?//", "CSS url() to a remote host"),
        (r"\bfetch\s*\(|XMLHttpRequest|new\s+WebSocket|EventSource", "network call in JS"),
    ]
    for pat, what in ext:
        for m in re.finditer(pat, text, re.I):
            p.err(f"line {line_of(text, m.start())}: {what}; the file must be self-contained")

    if "prefers-reduced-motion" not in text:
        p.err("no prefers-reduced-motion rule")
    if "prefers-color-scheme" not in text:
        p.err("no prefers-color-scheme (dark mode) rule")

    # A token never travels along an unestablished link. Scoped per scene, since
    # the same coordinates can be a known edge in one scene and unknown in another.
    norm = lambda d: re.sub(r"\s+", " ", d).strip()
    for sm in re.finditer(r"<section\b[^>]*class=\"[^\"]*\bscene\b.*?</section>", text, re.S):
        chunk = sm.group(0)
        unknown_ds = set()
        for pm in re.finditer(r"<path\b[^>]*>", chunk):
            tag = pm.group(0)
            if re.search(r"class=\"[^\"]*\bunknown\b", tag):
                d = re.search(r"\bd=\"([^\"]+)\"", tag)
                if d:
                    unknown_ds.add(norm(d.group(1)))
        for m in re.finditer(r"offset-path:\s*path\(\s*'([^']+)'\s*\)", chunk):
            if norm(m.group(1)) in unknown_ds:
                p.err(f"line {line_of(text, sm.start() + m.start())}: a .token travels along an .edge.unknown")

    scenes = b.scenes
    if not scenes:
        p.err("no <section class=\"scene\"> found")
    else:
        body = [s for s in scenes if not s["closing"]]
        if not any(s["closing"] for s in scenes):
            p.warn("no closing slide (section with data-closing)")
        elif not scenes[-1]["closing"]:
            p.warn("the closing slide is not last")
        if not 8 <= len(body) <= 12:
            p.warn(f"{len(body)} scenes before the closing slide; aim for 8-12")
        for n, s in enumerate(scenes, 1):
            if s["svgs"] != 1:
                p.warn(f"scene {n} '{s['title']}' has {s['svgs']} diagrams; aim for exactly one")
            if s["words"] > 45:
                p.warn(f"scene {n} '{s['title']}' says {s['words']} words; aim for ~40")
            p.note(f"scene {n}: {s['title']} ({s['words']} words)")
        closing = scenes[-1]
        if closing["closing"]:
            tail = text[text.rfind("data-closing"):]
            tail = tail[:tail.find("</section>")]
            if not re.search(r"<a\b[^>]*href=", tail):
                p.warn("the closing slide has no link to the full source")

    if not re.search(r"\bas of\b", text, re.I):
        p.warn("no 'as of' date in the page")

    # Secrets and PII. Always run; for a private audience the hits are advisory.
    hits = []
    for name, pat in SCAN:
        for m in re.finditer(pat, text):
            hits.append(f"line {line_of(text, m.start())}: {name}: {redact(m.group(0))}")
    return hits


def find_chrome(explicit):
    for c in ([explicit] if explicit else []) + CHROME_CANDIDATES:
        if c and (os.path.isfile(c) or shutil.which(c)):
            return c if os.path.isfile(c) else shutil.which(c)
    return None


def render(path, n_scenes, outdir, chrome, p):
    os.makedirs(outdir, exist_ok=True)
    url = "file://" + urllib.parse.quote(os.path.abspath(path))
    made = []
    with tempfile.TemporaryDirectory(prefix="presentation-chrome-") as prof:
        base = [chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                "--no-first-run", "--no-default-browser-check", "--disable-extensions",
                f"--user-data-dir={prof}", "--virtual-time-budget=2500"]
        for mode, w, h, q in MODES:
            for n in range(1, n_scenes + 1):
                frame = os.path.join(prof, f"frame-{mode}-{n}.html")
                with open(frame, "w", encoding="utf-8") as f:
                    f.write(FRAME.format(w=w, h=h, src=f"{url}?{q}#{n}"))
                png = os.path.join(outdir, f"scene-{n:02d}-{mode}.png")
                try:
                    subprocess.run(base + [f"--window-size={max(w, 500)},{h + 120}",
                                           f"--screenshot={png}", "file://" + frame],
                                   capture_output=True, timeout=60, check=False)
                except subprocess.TimeoutExpired:
                    p.err(f"chrome timed out rendering scene {n} ({mode})")
                    continue
                if os.path.isfile(png):
                    made.append(png)
                else:
                    p.err(f"chrome wrote no screenshot for scene {n} ({mode})")
            # One DOM dump per mode is enough to catch script errors.
            r = subprocess.run(base + [f"--window-size={w},{h}", "--dump-dom", f"{url}?{q}#1"],
                               capture_output=True, text=True, timeout=60, check=False)
            m = re.search(r'data-js-error="([^"]*)"', r.stdout or "")
            if m:
                p.err(f"JS error ({mode}): {m.group(1)}")
            elif not r.stdout:
                p.warn(f"chrome returned no DOM in {mode}; JS errors not checked")
            # Every scene must be reachable: walking the hash must show it.
            if mode == "light":
                for n in (1, n_scenes):
                    r = subprocess.run(base + ["--window-size=1280,760", "--dump-dom", f"{url}?{q}#{n}"],
                                       capture_output=True, text=True, timeout=60, check=False)
                    shown = [s for s in re.findall(r"<section\b[^>]*class=\"scene\"[^>]*>", r.stdout or "")
                             if " hidden" not in s]
                    if len(shown) != 1:
                        p.err(f"#{n} shows {len(shown)} scenes; expected exactly one")
    return made


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("html")
    ap.add_argument("--audience", default="private", choices=["private", "internal", "external"])
    ap.add_argument("--render", metavar="DIR")
    ap.add_argument("--chrome", metavar="PATH")
    a = ap.parse_args()

    try:
        with open(a.html, encoding="utf-8") as f:
            text = f.read()
    except OSError as e:
        print(f"cannot read {a.html}: {e}", file=sys.stderr)
        return 2

    p = Problems()
    hits = static_checks(a.html, text, a.audience, p)
    n_scenes = len(re.findall(r"<section\b[^>]*class=\"[^\"]*\bscene\b", text))

    made = []
    if a.render:
        chrome = find_chrome(a.chrome)
        if not chrome:
            p.warn("no Chrome/Chromium found; render and JS checks skipped")
        else:
            made = render(a.html, n_scenes, a.render, chrome, p)

    print(f"file: {os.path.abspath(a.html)}  ({len(text.encode())} bytes, {n_scenes} scenes)")
    for m in p.info:
        print(f"  {m}")
    print(f"errors: {len(p.errors)}")
    for m in p.errors:
        print(f"  ERROR {m}")
    print(f"warnings: {len(p.warnings)}")
    for m in p.warnings:
        print(f"  WARN  {m}")
    label = "advisory, private audience" if a.audience == "private" else "must be cleared before handing back"
    print(f"scan hits: {len(hits)} ({label})")
    for h in hits:
        print(f"  HIT   {h}")
    if a.render:
        print(f"renders: {len(made)} PNGs in {os.path.abspath(a.render)}")

    blocking = p.errors or (hits and a.audience != "private")
    return 1 if blocking else 0


if __name__ == "__main__":
    sys.exit(main())
