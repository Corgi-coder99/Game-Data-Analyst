"""Validate the local landing page using only the Python standard library."""

import json
from pathlib import Path
import re
import struct
import sys
from html.parser import HTMLParser
from urllib.parse import unquote, urlsplit

WEB = Path(__file__).resolve().parent
ROOT = WEB.parents[1]


class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.elements = []
        self.stack = []
        self.text = []
        self.stats = {}
        self.forbidden_contexts = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self.elements.append((tag, attrs))
        if tag not in {"meta", "link", "img", "br", "hr", "input", "source"}:
            self.stack.append((tag, attrs))

    def handle_endtag(self, tag):
        for index in range(len(self.stack) - 1, -1, -1):
            if self.stack[index][0] == tag:
                del self.stack[index:]
                break

    def handle_data(self, data):
        self.text.append(data)
        if self.stack and "data-stat" in self.stack[-1][1]:
            key = self.stack[-1][1]["data-stat"]
            self.stats[key] = self.stats.get(key, "") + data
        # The spec explicitly requires this unavailable feature in "Chưa có".
        if "bảng xếp hạng" in data.casefold():
            self.forbidden_contexts.append(
                data.strip() == "bảng xếp hạng"
                and any(a.get("id") == "not-yet" for _, a in self.stack)
                and self.stack[-1][0] == "li"
            )


def main():
    results = []

    def check(name, action):
        try:
            passed, detail = action()
        except (OSError, ValueError, KeyError, TypeError, AttributeError, struct.error) as error:
            passed, detail = False, str(error)
        results.append(passed)
        print(f"{'PASS' if passed else 'FAIL'} {name}: {detail}")

    page = Page()
    try:
        html = (WEB / "index.html").read_text(encoding="utf-8")
        css = (WEB / "style.css").read_text(encoding="utf-8")
        page.feed(html)
    except (OSError, ValueError) as error:
        print(f"FAIL Read page: {error}")
        return 1

    def resources():
        refs = [a[key] for _, a in page.elements for key in ("src", "href") if key in a]
        refs += re.findall(r"url\(\s*['\"]?([^)'\"\s]+)", css, re.I)
        bad = [ref for ref in refs if urlsplit(ref).scheme or ref.startswith("//")]
        imports = bool(re.search(r"@import\b", css, re.I))
        scripts = any(tag == "script" for tag, _ in page.elements)
        return not bad and not imports and not scripts, f"local resources; external={bad}, imports={imports}, scripts={scripts}"

    def sections():
        required = {"top", "hero", "loop", "gameplay", "difference", "numbers", "status", "follow", "footer"}
        ids = [a.get("id") for _, a in page.elements]
        order = [item for item in ids if item in required]
        expected = ["top", "hero", "loop", "gameplay", "difference", "numbers", "status", "follow", "footer"]
        anchors = [a["href"][1:] for _, a in page.elements if a.get("href", "").startswith("#")]
        return order == expected and all(a in ids for a in anchors), "9 sections in order and valid anchors"

    def images():
        images = [a for tag, a in page.elements if tag == "img"]
        valid = bool(images)
        details = []
        for attrs in images:
            path = (WEB / unquote(urlsplit(attrs.get("src", "")).path)).resolve()
            valid &= path.is_relative_to(WEB) and path.is_file() and bool(attrs.get("alt", "").strip())
            if path.is_file():
                signature = path.read_bytes()[:24]
                valid &= signature[:8] == b"\x89PNG\r\n\x1a\n"
                width, height = struct.unpack(">II", signature[16:24])
                details.append(f"{path.name} {width}x{height}")
                # CSS caps the image at 1280px, never above twice its native width.
                valid &= width * 2 >= 1280
        return valid, "; ".join(details) + "; nonempty alt, scale <= 2x"

    def numbers():
        data = ROOT / "game-studio" / "godot" / "data"
        load = lambda name: json.loads((data / name).read_text(encoding="utf-8-sig"))
        controller = (data.parent / "scripts/ui/game_controller.gd").read_text(encoding="utf-8")
        match = re.search(r"const\s+METRICS\s*:=\s*(\[[^\]]*\])", controller)
        actual = {"weeks": load("config.json")["weeks"]["demo"],
                  "cards": len(load("cards.json")["cards"]),
                  "events": len(load("events.json")["events"]),
                  "metrics": len(json.loads(match.group(1)))}
        displayed = {key: int(value) for key, value in page.stats.items()}
        expected = dict(zip(("weeks", "cards", "events", "metrics"), (10, 12, 8, 7)))
        return displayed == actual == expected, f"page={displayed}; source={actual}"

    def banned():
        text = " ".join(" ".join(page.text).split()).casefold()
        terms = ["số người đăng ký", "người chơi", "lượt tải", "đánh giá sao", "lời chứng thực", "tên người chơi",
                 "bảng xếp hạng", "đồng hồ đếm ngược", "đầu tiên", "hàng đầu", "số 1", "miễn phí",
                 "chơi ngay", "tải ngay", "30+ case study", "5 công ty", "sql thật", "all rights reserved", "©"]
        allowed = bool(page.forbidden_contexts) and all(page.forbidden_contexts)
        if allowed:
            text = text.replace("bảng xếp hạng", "")
        found = [term for term in terms if term in text]
        tags = [tag for tag, _ in page.elements if tag in {"form", "input", "textarea", "select"}]
        attrs = " ".join(str(value) for _, a in page.elements for value in a.values()).casefold()
        found += [term for term in terms if term in attrs]
        return not found and not tags and allowed, f"banned={found}, forms={tags}; only required 'Chưa có' exception"

    def metadata():
        lang = any(tag == "html" and a.get("lang") == "vi" for tag, a in page.elements)
        title = bool(re.search(r"<title>\s*[^<]+</title>", html))
        description = any(tag == "meta" and a.get("name") == "description" and a.get("content", "").strip() for tag, a in page.elements)
        og = all(any(tag == "meta" and a.get("property") == key and a.get("content") for tag, a in page.elements) for key in ("og:title", "og:description"))
        return lang and title and description and og, f"lang={lang}, title={title}, description={description}, OG={og}"

    for name, action in [("1 Resources", resources), ("2 Structure", sections), ("3 Images", images),
                         ("4 Demo numbers", numbers), ("5 Forbidden content", banned), ("6 Metadata", metadata)]:
        check(name, action)
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
