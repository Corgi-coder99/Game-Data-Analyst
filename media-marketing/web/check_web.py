"""Validate the English landing page (T-032) using only the standard library.

Run: python -X utf8 -I media-marketing/web/check_web.py
All files are read as UTF-8 explicitly; output is forced to UTF-8 so it never
fails on a Windows console code page (the T-008 encoding issue).
"""

from html.parser import HTMLParser
from pathlib import Path
import re
import struct
import sys
import unicodedata
from urllib.parse import unquote, urlsplit

WEB = Path(__file__).resolve().parent
MAX_PAGE_BYTES = 40_000      # index.html + style.css
MAX_ASSET_BYTES = 80_000     # per image
MAX_TOTAL_BYTES = 450_000    # everything the page loads

REQUIRED_IDS = ["top", "hero", "how", "day", "features", "gallery", "faq"]
FORBIDDEN_CLAIMS = [
    "award-winning", "award winning", "millions", "#1", "number one", "best-selling", "bestselling",
    "top-rated", "five-star", "5-star", "players say", "testimonial", "download now", "play now",
    "free to play", "wishlist", "pre-order", "coming to steam", "app store", "google play", "multiplayer mode",
    "all rights reserved",
]
REQUIRED_PHRASES = ["working title", "early demo", "fictional", "online leaderboard", "AI assistance"]


class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.elements = []
        self.text = []
        self.skip = 0

    def handle_starttag(self, tag, attrs):
        self.elements.append((tag, dict(attrs)))
        if tag in {"script", "style"}:
            self.skip += 1

    def handle_endtag(self, tag):
        if tag in {"script", "style"}:
            self.skip -= 1

    def handle_data(self, data):
        if not self.skip:
            self.text.append(data)


def non_english_chars(text):
    """Characters outside Latin basic/punctuation, i.e. Vietnamese diacritics and other scripts."""
    bad = set()
    for ch in text:
        if ord(ch) < 128:
            continue
        name = unicodedata.name(ch, "")
        if ch in "–—‘’“”…×":
            continue
        bad.add(ch)
    return "".join(sorted(bad))


def main():
    results = []

    def check(name, action):
        try:
            passed, detail = action()
        except (OSError, ValueError, KeyError, TypeError, AttributeError, struct.error) as error:
            passed, detail = False, f"{type(error).__name__}: {error}"
        results.append(passed)
        print(f"{'PASS' if passed else 'FAIL'} {name}: {detail}")

    try:
        html = (WEB / "index.html").read_text(encoding="utf-8")
        css = (WEB / "style.css").read_text(encoding="utf-8")
    except (OSError, ValueError) as error:
        print(f"FAIL Read page: {error}")
        return 1
    page = Page()
    page.feed(html)
    visible = " ".join(" ".join(page.text).split())
    attr_text = " ".join(str(v) for _, a in page.elements for v in a.values() if v)

    def local_path(ref):
        return (WEB / unquote(urlsplit(ref).path)).resolve()

    def resources():
        refs = [a[k] for _, a in page.elements for k in ("src", "href", "action", "data") if k in a]
        refs += re.findall(r"url\(\s*['\"]?([^)'\"\s]+)", css, re.I)
        external = [r for r in refs if urlsplit(r).scheme or r.startswith("//")]
        imports = bool(re.search(r"@import\b", css, re.I))
        scripts = [t for t, _ in page.elements if t in {"script", "iframe", "embed", "object"}]
        forms = [t for t, _ in page.elements if t in {"form", "input", "textarea", "select"}]
        ok = not external and not imports and not scripts and not forms
        return ok, f"external={external}, @import={imports}, scripts/frames={scripts}, forms={forms}"

    def anchors():
        ids = [a.get("id") for _, a in page.elements if a.get("id")]
        order = [i for i in ids if i in REQUIRED_IDS]
        hrefs = [a["href"][1:] for _, a in page.elements if a.get("href", "").startswith("#") and len(a["href"]) > 1]
        missing = [h for h in hrefs if h not in ids]
        return order == REQUIRED_IDS and not missing and len(ids) == len(set(ids)), \
            f"sections in order={order == REQUIRED_IDS}, broken anchors={missing}"

    def images():
        imgs = [a for t, a in page.elements if t == "img"]
        problems, names = [], set()
        for a in imgs:
            path = local_path(a.get("src", ""))
            if not (path.is_relative_to(WEB) and path.is_file()):
                problems.append(f"missing {a.get('src')}")
                continue
            names.add(path.name)
            if not a.get("alt", "").strip():
                problems.append(f"no alt {path.name}")
            if path.read_bytes()[:8] != b"\x89PNG\r\n\x1a\n":
                problems.append(f"not PNG {path.name}")
        links = [a["href"] for t, a in page.elements if t == "a" and a.get("href", "").startswith("assets/")]
        problems += [f"missing link {h}" for h in links if not local_path(h).is_file()]
        return bool(imgs) and not problems, f"{len(imgs)} img tags, {len(names)} files, problems={problems}"

    def unused_assets():
        used = set(re.findall(r"assets/([\w.\-]+)", html))
        on_disk = {p.name for p in (WEB / "assets").iterdir() if p.is_file()}
        extra = sorted(on_disk - used)
        return not extra, f"unreferenced assets={extra}"

    def sizes():
        page_bytes = len((WEB / "index.html").read_bytes()) + len((WEB / "style.css").read_bytes())
        assets = {p.name: p.stat().st_size for p in (WEB / "assets").iterdir() if p.is_file()}
        big = [n for n, s in assets.items() if s > MAX_ASSET_BYTES]
        total = page_bytes + sum(assets.values())
        ok = page_bytes <= MAX_PAGE_BYTES and not big and total <= MAX_TOTAL_BYTES
        return ok, f"html+css={page_bytes}B (max {MAX_PAGE_BYTES}), total={total}B (max {MAX_TOTAL_BYTES}), oversize={big}"

    def forbidden():
        text = (visible + " " + attr_text).casefold()
        found = [t for t in FORBIDDEN_CLAIMS if t in text]
        return not found, f"forbidden terms found={found}"

    def required():
        text = visible.casefold()
        missing = [p for p in REQUIRED_PHRASES if p.casefold() not in text]
        footer = re.search(r"<footer.*?</footer>", html, re.S | re.I)
        foot = footer.group(0).casefold() if footer else ""
        foot_ok = all(w in foot for w in ("fictional", "early demo", "working title"))
        return not missing and foot_ok, f"missing phrases={missing}, footer has fictional/early demo/working title={foot_ok}"

    def demo_button():
        text = visible.casefold()
        has = "demo coming soon" in text
        fake = [a["href"] for t, a in page.elements if t == "a" and re.search(r"\.(exe|zip|msi|dmg|apk)$", a.get("href", ""), re.I)]
        return has and not fake, f"'Demo coming soon' present={has}, download links={fake}"

    def english():
        bad_text = non_english_chars(html + css)
        vietnamese = re.search(r"[À-ỹ]", html + css)
        return not bad_text and not vietnamese, f"non-ASCII characters={bad_text!r}"

    def metadata():
        lang = any(t == "html" and a.get("lang") == "en" for t, a in page.elements)
        title = bool(re.search(r"<title>\s*[^<]+</title>", html))
        meta = lambda k, v: any(t == "meta" and a.get(k) == v and a.get("content", "").strip() for t, a in page.elements)
        viewport = meta("name", "viewport")
        desc = meta("name", "description")
        og = meta("property", "og:title") and meta("property", "og:description")
        return lang and title and viewport and desc and og, f"lang=en {lang}, title={title}, viewport={viewport}, description={desc}, OG={og}"

    def a11y():
        h1 = sum(1 for t, _ in page.elements if t == "h1")
        main = any(t == "main" for t, _ in page.elements)
        skip = any(t == "a" and a.get("href") == "#main" for t, a in page.elements)
        focus = "focus-visible" in css
        motion = "prefers-reduced-motion" in css
        pixel = "image-rendering: pixelated" in css
        return h1 == 1 and main and skip and focus and motion and pixel, \
            f"h1={h1}, main={main}, skip link={skip}, focus style={focus}, reduced-motion={motion}, pixelated={pixel}"

    for name, action in [
        ("1 Self-contained", resources), ("2 Sections and anchors", anchors), ("3 Images and alt text", images),
        ("4 No unused assets", unused_assets), ("5 Size budget", sizes), ("6 Forbidden claims", forbidden),
        ("7 Required honesty notes", required), ("8 Demo button honest", demo_button), ("9 English only", english),
        ("10 Metadata", metadata), ("11 Accessibility", a11y),
    ]:
        check(name, action)
    print(f"{sum(results)}/{len(results)} checks passed")
    return 0 if all(results) else 1


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
