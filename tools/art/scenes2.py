"""Battle and travel background compositions built from scenery layers."""
import os, sys, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image
import scenery as V
W, H = 640, 360


def battle_bg(seed=4, road=(162, 350)):
    r = random.Random(seed)
    img = Image.new('RGBA', (W, H), V.hx('#6f8fa6'))
    V.sky_and_far2(img, r, 100, sunx=250, tower_x=440)
    img.alpha_composite(V.canopy(21, 132, '#3d5f5e', '#55807a', '#78a090', '#e9c98f', 1.3, (5, 13)))
    V.haze_band(img, 110, 140, '#f0d2a4', 0.25, 0.0)
    img.alpha_composite(V.canopy(22, 150, '#2f5240', '#4a7a4e', '#6f9e5c', '#f2cf86', 0.9, (7, 18)))
    V.grassland(img, r, 150, road[0])
    V.trail2(img, r, road[0], road[1])
    # back-edge props along the road
    for name, x, flip, k, hz in (('p_windmill_0', 250, False, .6, .35), ('p_pylon_0', 330, True, .6, .35), ('p_tree2_0', 520, True, .75, .12), ('p_tree1_0', -20, False, .75, .12)):
        sp = V.tint(V.prop(name), V.hx('#8fa69e'), hz)
        sp = sp.resize((int(sp.width * k), int(sp.height * k)), Image.NEAREST)
        V.put(img, sp, x, road[0] + 2, flip)
    for name, x in (('p_grass_0', 590),):
        sp = V.prop(name)
        V.put(img, sp.resize((sp.width // 2, sp.height // 2), Image.NEAREST), x, road[0] + 3)
    V.grassland(img, r, road[1], H, '#3f6c34')
    for name, x in (('p_fern_0', -20), ('p_grass_0', 600)):
        V.put(img, V.prop(name), x, H + 30)
    return img


def travel_bg(seed=6, road=(276, 312)):
    r = random.Random(seed)
    img = Image.new('RGBA', (W, H), V.hx('#6f8fa6'))
    V.sky_and_far2(img, r, 170, sunx=500, tower_x=430)
    img.alpha_composite(V.canopy(31, 200, '#3d5f5e', '#55807a', '#78a090', '#e9c98f', 1.3, (6, 11)))
    V.haze_band(img, 176, 206, '#f0d2a4', 0.3, 0.0)
    img.alpha_composite(V.canopy(32, 222, '#2f5240', '#4a7a4e', '#6f9e5c', '#f2cf86', 0.9, (7, 20)))
    V.grassland(img, r, 222, road[0])
    for name, x, yb, flip in (('p_windmill_0', 320, 236, True), ('p_tree1_0', -30, 272, False), ('p_tree2_0', 540, 270, False),
                              ('p_rocks_0', 455, 276, False), ('p_bush_0', 150, 277, False), ('p_wheel_0', 360, 278, False)):
        sp = V.prop(name)
        if name in ('p_pylon_0', 'p_windmill_0'):
            sp = V.tint(sp, V.hx('#8fa69e'), 0.3)
            sp = sp.resize((sp.width * 3 // 4, sp.height * 3 // 4), Image.NEAREST)
        V.put(img, sp, x, yb, flip)
    V.trail2(img, r, road[0], road[1])
    V.grassland(img, r, road[1], H, '#355f30')
    return img


def travel_fg(img):
    """Foreground layer drawn over the characters."""
    for name, x, yb, flip in (('p_fern_0', -24, H + 8, False), ('p_grass_0', 120, H + 6, False), ('p_stump_0', 300, H + 10, False),
                              ('p_bush_0', 420, H + 14, False), ('p_fern_0', 560, H + 10, True)):
        V.put(img, V.prop(name), x, yb, flip)
    lv = V.prop('p_leaves_0')
    V.put(img, lv, -40, H + 30)
    V.put(img, lv, W - 88, H + 40, True)
    return img
