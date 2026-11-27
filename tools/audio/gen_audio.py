"""Generate Trailomon audio with ElevenLabs (key from the ELEVENLABS_API_KEY env var, never the repo).

    python3 tools/audio/gen_audio.py cries [family ids...]   # one cry per family (first form)
    python3 tools/audio/gen_audio.py music [track names...]  # the music loops
    python3 tools/audio/gen_audio.py sfx [names...]          # a few UI and battle sounds

Cries go to assets/audio/cries/<family>.mp3. Evolved forms reuse their family's cry, played
lower (see src/audio/sound.gd). Files that already exist are skipped, so re-running only fills
gaps. The family list comes from tools/audio/families.gd (run through Godot).
"""
import json
import os
import subprocess
import sys
import urllib.request

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "audio")
API = "https://api.elevenlabs.io/v1"
GODOT = os.environ.get("GODOT", os.path.expanduser("~/godot/godot"))

sys.path.insert(0, os.path.join(ROOT, "tools", "art"))
from creatures import CREATURES  # noqa: E402

VOICE = {"small": "a small, high, quick", "medium": "a mid-pitched", "large": "a deep, big, slow"}

MUSIC = {
    "title": (60000, "Instrumental only. Warm, wistful frontier overture for a cozy creature-collecting "
              "trail adventure game: solo fiddle melody over plucked banjo and soft strings, a hint of music box, "
              "hopeful and a little lonely, gentle swell, ends softly so it can loop."),
    "trail": (90000, "Instrumental only. Cozy frontier travel theme for a wagon on a long trail: plucked banjo, "
              "warm acoustic guitar, soft fiddle, light hand percussion like wagon wheels, steady walking tempo, "
              "hopeful and a little wistful, loops cleanly, no big ending."),
    "town": (75000, "Instrumental only. Cozy small frontier town theme: accordion, upright bass, gentle "
             "mandolin, clinking warmth, relaxed and friendly, a place to rest and trade, loops cleanly."),
    "battle": (75000, "Instrumental only. Upbeat creature battle theme for an auto-battler: driving fiddle and "
               "banjo bluegrass energy with punchy drums and brass stabs, tense but fun, 150 bpm, loops cleanly."),
    "guardian": (90000, "Instrumental only. Epic boss battle against a huge ancient forest guardian beast: "
                 "pounding taiko and frame drums, low brass, urgent fiddle ostinato, choir pads, folk-epic, loops cleanly."),
    "wild": (75000, "Instrumental only. Mysterious deep wilderness theme: low drones, sparse kalimba, distant "
             "wooden flute, rustling textures, sense of something huge sleeping nearby, loops cleanly."),
}

SFX = {
    "catch": (1.5, "Bright magical chime and a soft pop, a creature being caught in a charm, cute video game success sound."),
    "miss": (1.2, "A short whoosh and a sad little two-note descending pluck, a creature escaping, video game."),
    "evolve": (3.5, "Rising shimmering magical sparkle swell ending in a bright burst, creature evolution, video game."),
    "level_up": (1.5, "Short cheerful ascending three-note plucked fanfare, level up, video game."),
    "victory": (3.0, "Short triumphant folk fanfare on fiddle and banjo, battle won, video game jingle."),
    "defeat": (2.5, "Short sad descending fiddle phrase, battle lost, video game jingle."),
    "flare": (1.5, "A signal flare fired: a sharp crack, a fizzing hiss and crackle."),
    "click": (0.5, "A soft wooden UI click."),
}


def _key():
    k = os.environ.get("ELEVENLABS_API_KEY", "")
    if not k:
        sys.exit("ELEVENLABS_API_KEY is not set")
    return k


def _post(path, body, out_path):
    req = urllib.request.Request(API + path, data=json.dumps(body).encode(), method="POST",
                                 headers={"xi-api-key": _key(), "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=600) as r:
        data = r.read()
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "wb") as f:
        f.write(data)


def families():
    out = subprocess.run([GODOT, "--headless", "--path", ROOT, "--script", "res://tools/audio/families.gd"],
                         capture_output=True, text=True).stdout
    for line in out.splitlines():
        if line.startswith("FAMILIES "):
            return json.loads(line[len("FAMILIES "):])
    sys.exit("could not read the family list")


def cry_prompt(fid, fam):
    desc = CREATURES.get(fid, (0, fam["name"].lower()))[1]
    voice = VOICE.get(fam["size"], "a")
    mood = "grand, echoing and majestic" if fam["rarity"] in ("legendary", "guardian") else "cute and characterful"
    return (f"A single short video game creature cry, {voice} animal call from {desc}. "
            f"{mood}, one clear vocalization, no music, no speech, no words.")


def cries(ids):
    fams = families()
    for fid in (ids or sorted(fams)):
        path = os.path.join(OUT, "cries", fid + ".mp3")
        if os.path.exists(path):
            continue
        fam = fams[fid]
        dur = 2.0 if fam["rarity"] in ("legendary", "guardian") else 1.2
        try:
            _post("/sound-generation", {"text": cry_prompt(fid, fam), "duration_seconds": dur, "prompt_influence": 0.55}, path)
            print("cry", fid)
        except Exception as e:  # keep going; a re-run fills the gap
            print("cry FAILED", fid, e)


def music(names):
    for n in (names or list(MUSIC)):
        path = os.path.join(OUT, "music", n + ".mp3")
        if os.path.exists(path):
            continue
        ms, prompt = MUSIC[n]
        _post("/music", {"prompt": prompt, "music_length_ms": ms}, path)
        print("music", n)


def sfx(names):
    for n in (names or list(SFX)):
        path = os.path.join(OUT, "sfx", n + ".mp3")
        if os.path.exists(path):
            continue
        dur, prompt = SFX[n]
        _post("/sound-generation", {"text": prompt, "duration_seconds": dur, "prompt_influence": 0.5}, path)
        print("sfx", n)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    rest = sys.argv[2:]
    if cmd == "cries":
        cries(rest)
    elif cmd == "music":
        music(rest)
    elif cmd == "sfx":
        sfx(rest)
    else:
        print(__doc__)
