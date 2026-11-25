"""Trail-life props: one Sprite Fusion sprite per id, saved to assets/props/<id>.png.

  python3 tools/art/props.py generate [id ...]   # 5 credits each at 96px+, 3 at 80px or less (skips existing files)

Reads SPRITE_FUSION_API_KEY from the environment. Never write the key anywhere.
"""
import json
import os
import sys
import urllib.request

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "props")
STYLE = "naturepunk style, side view, pixel art game sprite, transparent background, nature reclaiming brass machinery"

# id -> (size, subject)
PROPS = {
    "trader_cart": (96, "a small two-wheeled covered trader cart piled with sacks and lanterns, facing left"),
    "traveler": (64, "a hooded traveller walking with a big backpack and a walking staff, facing left, full body"),
    "signpost": (64, "a weathered wooden trail signpost with two arrow boards and moss"),
    "grave_marker": (64, "a small wooden grave cross with a hanging lantern and wildflowers on a dirt mound"),
    "campfire": (64, "a small campfire with crossed logs, a cooking pot on a tripod, flames"),
    "abandoned_cart": (96, "a broken abandoned wagon with a missing wheel, overgrown with vines and flowers"),
    "hut": (128, "a cozy village cottage with a mossy thatched roof, round window and brass chimney pipe"),
    "trading_post": (128, "a wooden trading post market stall with a striped awning, crates and hanging lanterns"),
    "stilt_house": (128, "a swamp house on tall wooden stilts with a rope ladder and glowing lantern"),
    "tent_camp": (96, "a canvas camping tent with a lantern and a bedroll beside it"),
    "shrine_stone": (80, "an ancient standing stone with a glowing teal rune and moss"),
    "well": (80, "a stone village water well with a wooden roof and a bucket"),
}


def _download(url, path):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=60) as resp, open(path, "wb") as f:
        f.write(resp.read())


def generate(ids):
    key = os.environ.get("SPRITE_FUSION_API_KEY")
    if not key:
        sys.exit("SPRITE_FUSION_API_KEY is not set")
    os.makedirs(OUT, exist_ok=True)
    for pid in ids:
        path = os.path.join(OUT, pid + ".png")
        if os.path.exists(path):
            print("skip", pid)
            continue
        size, subject = PROPS[pid]
        body = json.dumps({"operation": "generate", "prompt": "%s, %s" % (subject, STYLE),
                           "size": size, "count": 1, "tags": ["trailomon-props"]}).encode()
        req = urllib.request.Request("https://www.spritefusion.com/api/v1/generate", data=body, method="POST",
                                     headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
        url = None
        with urllib.request.urlopen(req, timeout=300) as resp:
            for raw in resp:
                line = raw.decode().strip()
                if not line.startswith("data:"):
                    continue
                ev = json.loads(line[5:])
                if ev.get("type") == "output":
                    url = ev["asset"]["assetUrl"]
                elif ev.get("type") == "completed":
                    print(pid, ev.get("status"), "credits left", ev.get("credits", {}).get("remaining"))
        if url is None:
            print("FAILED", pid)
            continue
        _download(url, path)
        print("saved", pid, flush=True)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "generate":
        generate(sys.argv[2:] or list(PROPS))
    else:
        print(__doc__)
