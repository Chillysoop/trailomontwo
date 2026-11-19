"""Export parallax layers for the Godot travel scene and the battle background.

Usage (from the repo root): python3 tools/art/layers.py assets/backgrounds
Needs Python 3 with Pillow and numpy. Props come from assets/props (generated with Sprite Fusion).
"""
import sys, os, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from PIL import Image
import scenery as V

OUT = sys.argv[1]
TW, OV, H = 1280, 64, 360


def wrap(img):
    """Make a (TW+OV)-wide layer seamless at TW by cross-fading the overlap into the start."""
    a = np.array(img).astype(float)
    base, tail = a[:, :OV].copy(), a[:, TW:TW + OV]
    t = np.linspace(1, 0, OV)[None, :, None]
    a[:, :OV] = tail * t + base * (1 - t)
    return Image.fromarray(a[:, :TW].clip(0, 255).astype(np.uint8), 'RGBA')


def putw(img, sp, x, yb, flip=False):
    for dx in (0, -TW, TW):
        V.put(img, sp, x + dx, yb, flip)


def blank():
    return Image.new('RGBA', (TW, H), (0, 0, 0, 0))


def new():
    return Image.new('RGBA', (TW + OV, H), (0, 0, 0, 0))


def travel():
    V.W = TW + OV
    r = random.Random(6)
    hz = 170
    sky = V.gradient(V.SKY, H)
    for i in range(14):
        cx, cy, cw = r.randint(0, TW), r.randint(30, hz - 64), r.randint(40, 120)
        for dx in (0, -TW):
            V.cloud(sky, random.Random(i), cx + dx, cy, cw, '#fde8c8', '#f2b9a0', '#c98e98')
    sun = Image.new('RGBA', (640, H), (0, 0, 0, 0))
    V.W = 640
    V.sun(sun, 500, hz - 62, 12)
    V.rays(sun, 500, hz - 62, 7, 14)
    V.W = TW
    V.PERIODIC = True
    mtn = blank()
    m, _ = V.mountains(3, hz, 70, '#a7b3cc', '#d8cfd6', '#8f9cba', '#f4ece8', 1.0)
    mtn.alpha_composite(m)
    V.haze_band(mtn, hz - 50, hz + 6, '#f6dcbc', 0.0, 0.45)
    m, _ = V.mountains(9, hz + 18, 44, '#7f93ad', '#a9b6c6', '#6b7f9a', None, 1.2)
    mtn.alpha_composite(m)
    V.haze_band(mtn, hz - 10, hz + 24, '#f0d4b4', 0.0, 0.35)
    V.PERIODIC = False
    V.W = TW + OV
    forest = blank()
    tw = V.tint(V.prop('p_tower_0'), V.hx('#9aa8c0'), 0.3)
    putw(forest, tw.resize((tw.width * 3 // 4, tw.height * 3 // 4), Image.NEAREST), 430, hz + 40)
    forest.alpha_composite(wrap(V.canopy(31, 200, '#3d5f5e', '#55807a', '#78a090', '#e9c98f', 1.3, (6, 11))))
    for name, x in (('p_windmill_0', 900), ('p_pylon_0', 1150)):
        sp = V.tint(V.prop(name), V.hx('#8fa69e'), 0.3)
        putw(forest, sp.resize((sp.width * 3 // 4, sp.height * 3 // 4), Image.NEAREST), x, 236)
    nb = new()
    nb.alpha_composite(V.canopy(32, 222, '#2f5240', '#4a7a4e', '#6f9e5c', '#f2cf86', 0.9, (7, 20)))
    V.grassland(nb, r, 222, 276)
    V.trail2(nb, r, 276, 312)
    V.grassland(nb, r, 312, H, '#355f30')
    near = wrap(nb)
    for name, x, yb in (('p_tree1_0', 10, 272), ('p_bush_0', 150, 277), ('p_windmill_0', 320, 236), ('p_wheel_0', 360, 278), ('p_rocks_0', 455, 276),
                        ('p_tree2_0', 540, 270), ('p_stump_0', 700, 276), ('p_tree1_0', 820, 272), ('p_grass_0', 980, 277), ('p_rocks_0', 1060, 276), ('p_tree2_0', 1160, 270)):
        sp = V.prop(name)
        if name == 'p_windmill_0':
            sp = V.tint(sp, V.hx('#8fa69e'), 0.3).resize((sp.width * 3 // 4, sp.height * 3 // 4), Image.NEAREST)
        putw(near, sp, x, yb)
    fg = blank()
    for name, x, yb, flip in (('p_fern_0', -24, H + 8, False), ('p_grass_0', 120, H + 6, False), ('p_stump_0', 300, H + 10, False), ('p_bush_0', 420, H + 14, False),
                              ('p_leaves_0', 560, H + 34, False), ('p_fern_0', 760, H + 10, True), ('p_grass_0', 930, H + 6, False), ('p_leaves_0', 1080, H + 40, True)):
        putw(fg, V.prop(name), x, yb, flip)
    os.makedirs(OUT + '/travel', exist_ok=True)
    sky.crop((0, 0, TW, H)).save(OUT + '/travel/sky.png')
    sun.save(OUT + '/travel/sun.png')
    mtn.save(OUT + '/travel/mountains.png')
    for n, im in (('forest_far', forest), ('ground', near), ('foreground', fg)):
        im.save(OUT + '/travel/' + n + '.png')


def battle():
    V.W = 640
    import scenes2
    scenes2.W = 640
    os.makedirs(OUT + '/battle', exist_ok=True)
    scenes2.battle_bg().save(OUT + '/battle/trail_forest.png')


travel()
battle()
print('ok')
