"""Scenery for every overworld terrain: parallax travel layers and battle backdrops.

Usage (from the repo root): python3 tools/art/regions.py assets/backgrounds
Needs Python 3 with Pillow and numpy. Props come from assets/props (Sprite Fusion, see props.py).

Writes, per terrain (forest, hills, river, swamp, mountain):
  travel/<terrain>/sky.png mountains.png far.png ground.png foreground.png   (1280 wide, seamless)
  battle/<terrain>_back.png  (opaque sky and mountains)
  battle/<terrain>_front.png (canopy, ground and road, transparent above)
Region landmarks (props lm_*) are placed by the game between the back and front layers.
"""
import sys, os, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from PIL import Image, ImageDraw
import scenery as V

OUT = sys.argv[1] if len(sys.argv) > 1 else 'assets/backgrounds'
TW, OV, H = 1280, 64, 360

# Palettes and props per terrain. "far": canopy colours (dark, mid, light, rim) of the far band;
# "near": the near band. "grass": (top, base, blade colours, flower colours).
T = {
    'forest': dict(
        sky=[(0, '#2f5d78'), (.35, '#6f8fa6'), (.62, '#e8b88a'), (.85, '#f6d49a'), (1, '#fbe6b4')],
        cloud=('#fde8c8', '#f2b9a0', '#c98e98'), sun=True,
        mtn1=('#a7b3cc', '#d8cfd6', '#8f9cba', '#f4ece8', 70), mtn2=('#7f93ad', '#a9b6c6', '#6b7f9a', None, 44),
        haze='#f6dcbc',
        far=('#3d5f5e', '#55807a', '#78a090', '#e9c98f', 1.3, (6, 11)),
        near=('#2f5240', '#4a7a4e', '#6f9e5c', '#f2cf86', 0.9, (7, 20)),
        grass=('#6a9a4a', '#4e7d3a', ['#3f6c34', '#7aaa52', '#5a8a44', '#8cbc5e'], ['#f2d36b', '#f4a3c0', '#ffffff', '#b99cf0']),
        grass_near='#355f30', far_props=['windmill_ruin', 'pylon_overgrown'], far_tint='#8fa69e',
        road=['tree_ancient', 'bush_flowering', 'wheel_buried', 'rocks_crystal', 'tree_lantern', 'stump_mushroom', 'tree_ancient', 'grass_wildflower'],
        fg=['fern_cluster', 'grass_wildflower', 'stump_mushroom', 'bush_flowering', 'leaves_foreground'],
    ),
    'hills': dict(
        road_tint=('#d8b878', 0.25),
        sky=[(0, '#3a6b8c'), (.4, '#86a8c0'), (.66, '#f0c896'), (.86, '#f8dca4'), (1, '#fcecc0')],
        cloud=('#fff0d4', '#f4c8a8', '#d4a0a0'), sun=True,
        mtn1=('#b4bfd2', '#e0d8dc', '#9aa6c0', '#f8f0ec', 46), mtn2=('#8fa59a', '#b4c6a8', '#7a9282', None, 30),
        haze='#f8e2c0', rolling=True,
        far=('#5e7f45', '#79a052', '#9cc06a', '#f2d890', 0.6, (5, 9)),
        near=('#4a7038', '#6a9446', '#8eb85c', '#f6dc90', 0.35, (6, 12)),
        grass=('#8ab25a', '#5e8c3e', ['#4f7f3c', '#9cc46a', '#6e9e4a', '#b4d47a'], ['#f2d36b', '#c08ae0', '#ffffff', '#f4c04a']),
        grass_near='#47733a', far_props=['windmill_ruin', 'hills_oak'], far_tint='#a9b89a',
        road=['hills_oak', 'hills_rocks', 'hills_fence', 'well', 'hills_heather', 'hills_oak', 'rocks_crystal', 'hills_fence'],
        fg=['hills_heather', 'grass_wildflower', 'hills_rocks', 'hills_heather', 'grass_wildflower'],
    ),
    'river': dict(
        road_tint=('#a89878', 0.25),
        sky=[(0, '#2c6488'), (.38, '#7aa6c4'), (.64, '#e6c4a0'), (.86, '#f2dcb4'), (1, '#f8ecd0')],
        cloud=('#fbf0e0', '#e8c8b8', '#b8a0b0'), sun=True,
        mtn1=('#a2b6cc', '#d4d6e0', '#8aa0bc', '#f2f0f0', 60), mtn2=('#7896ac', '#a2b8c8', '#62809a', None, 38),
        haze='#eadcc8', water=True,
        far=('#2f5f62', '#457f78', '#68a08c', '#e2cc98', 1.1, (6, 12)),
        near=('#2c5444', '#3f7454', '#5e9862', '#ead08c', 0.7, (7, 16)),
        grass=('#6aa05a', '#457a44', ['#3c6c40', '#78aa5a', '#56905a', '#8cbc6a'], ['#9cc8f0', '#ffffff', '#f2d36b']),
        grass_near='#2f5c38', far_props=['river_willow', 'pylon_overgrown'], far_tint='#8aa8a8',
        road=['river_willow', 'river_rocks', 'river_reeds', 'river_jetty', 'river_willow', 'fern_cluster', 'river_rocks', 'river_reeds'],
        fg=['river_reeds', 'fern_cluster', 'river_reeds', 'bush_flowering', 'leaves_foreground'],
    ),
    'swamp': dict(
        road_tint=('#5a5038', 0.45),
        sky=[(0, '#2a3e3e'), (.35, '#4f6a5c'), (.62, '#a8a878'), (.85, '#cfc690'), (1, '#e0d8a8')],
        cloud=('#d8d4b0', '#a8a888', '#7a8070'), sun=False, moon=True,
        mtn1=('#6f8478', '#94a090', '#5c7068', None, 40), mtn2=('#4f6658', '#6a8070', '#40564a', None, 26),
        haze='#c8c8a0', water=True, murk=True,
        far=('#263e34', '#3a5a44', '#557a52', '#c8c080', 1.4, (6, 12)),
        near=('#1f342a', '#2f4c38', '#486a48', '#b8c070', 1.0, (8, 18)),
        grass=('#5a7a44', '#3a5a34', ['#2f4c2c', '#647e44', '#4a6a38', '#7a9650'], ['#c08ae0', '#7fe0c8', '#f4a3c0']),
        grass_near='#26402a', far_props=['swamp_mangrove', 'stilt_house'], far_tint='#6a7e68',
        road=['swamp_mangrove', 'swamp_shrooms', 'swamp_boiler', 'swamp_cattails', 'swamp_mangrove', 'stump_mushroom', 'swamp_shrooms', 'shrine_stone'],
        fg=['swamp_cattails', 'swamp_shrooms', 'fern_cluster', 'swamp_cattails', 'leaves_foreground'],
    ),
    'mountain': dict(
        road_tint=('#9a9aa0', 0.5),
        sky=[(0, '#1f4a78'), (.4, '#6a94c0'), (.68, '#c8d8e8'), (.88, '#ece8e8'), (1, '#f6f2ee')],
        cloud=('#ffffff', '#dfe4ee', '#a8b0c8'), sun=True,
        mtn1=('#8f9cbc', '#e4e6f0', '#7482a4', '#ffffff', 100), mtn2=('#6a7896', '#9aa6c0', '#56627e', '#eef2f8', 74),
        haze='#e4e8f0', snowy=True,
        far=('#2a4048', '#3c5a5e', '#5a7a74', '#dcdcc8', 1.5, (4, 8)),
        near=('#22363c', '#34504e', '#4e6e62', '#e4e0cc', 1.1, (5, 11)),
        grass=('#8a9a78', '#5c6e58', ['#4e6050', '#8a9a78', '#6a7c62', '#a4b090'], ['#ffffff', '#c8d8f0', '#e0b0e8']),
        grass_near='#44584a', far_props=['mtn_pine', 'clocktower_ruin'], far_tint='#8a98b0',
        road=['mtn_pine', 'mtn_boulder', 'mtn_minecart', 'mtn_shrub', 'mtn_pine', 'rocks_crystal', 'mtn_boulder', 'mtn_pine'],
        fg=['mtn_shrub', 'mtn_boulder', 'mtn_shrub', 'grass_wildflower', 'mtn_shrub'],
    ),
    'blight': dict(
        road_tint=('#3a3040', 0.5),
        sky=[(0, '#1c1424'), (.35, '#3a2c48'), (.62, '#7a5a7a'), (.85, '#a88a96'), (1, '#c4aab0')],
        cloud=('#8a7a90', '#5e4e68', '#3a2e44'), sun=False,
        mtn1=('#4a3e58', '#6e5e7e', '#382e46', None, 64), mtn2=('#352a40', '#54446a', '#261e30', None, 40),
        haze='#7a6080', murk=True,
        far=('#1e1824', '#2e2436', '#463650', '#a070c0', 1.2, (5, 10)),
        near=('#1a1420', '#2a2030', '#40304a', '#b080d0', 0.8, (6, 14)),
        grass=('#5e5862', '#3a343e', ['#2c2630', '#6a6070', '#4a4250', '#7a7080'], ['#a070e0', '#c090f0', '#604070']),
        grass_near='#2a2430', far_props=['blight_tree', 'pylon_overgrown'], far_tint='#5a4a68',
        road=['blight_tree', 'blight_crystal', 'blight_wreck', 'blight_brambles', 'blight_tree', 'abandoned_cart', 'blight_crystal', 'grave_marker'],
        fg=['blight_brambles', 'blight_crystal', 'blight_brambles', 'blight_wreck', 'blight_brambles'],
    ),
    'glow': dict(
        road_tint=('#f0e0b8', 0.35),
        sky=[(0, '#4a7aa8'), (.35, '#9cc0d8'), (.62, '#f4e4b8'), (.85, '#fff0c8'), (1, '#fff8e4')],
        cloud=('#ffffff', '#fbe8c8', '#e8c8a8'), sun=True,
        mtn1=('#c8c4e0', '#f4f0f8', '#aeaacc', '#ffffff', 60), mtn2=('#a8c0c8', '#d4e4e4', '#8aa8b0', None, 36),
        haze='#fff2d4',
        far=('#4a8a6a', '#6ab08a', '#a8e0b0', '#fff0a0', 1.1, (6, 11)),
        near=('#3e7a58', '#5ea47a', '#9cdca0', '#fff4b0', 0.8, (7, 16)),
        grass=('#a4d47a', '#70a85a', ['#5a9a50', '#b4e48a', '#80c070', '#d4f4a0'], ['#fff4a0', '#ffffff', '#f0d060', '#a0e8ff']),
        grass_near='#5a9050', far_props=['glow_tree', 'glow_pylon'], far_tint='#c8d8c0',
        road=['glow_tree', 'glow_crystal', 'glow_flowers', 'glow_pylon', 'glow_tree', 'shrine_stone', 'glow_crystal', 'glow_flowers'],
        fg=['glow_flowers', 'glow_crystal', 'glow_flowers', 'fern_cluster', 'glow_flowers'],
    ),
}


def wrap(img):
    """Make a (TW+OV)-wide layer seamless at TW by cross-fading the overlap into the start."""
    a = np.array(img).astype(float)
    base, tail = a[:, :OV].copy(), a[:, TW:TW + OV]
    t = np.linspace(1, 0, OV)[None, :, None]
    a[:, :OV] = tail * t + base * (1 - t)
    return Image.fromarray(a[:, :TW].clip(0, 255).astype(np.uint8), 'RGBA')


def putw(img, sp, x, yb, flip=False, wide=TW):
    for dx in (0, -wide, wide):
        V.put(img, sp, x + dx, yb, flip)


def prop(name, k=1.0, haze=None, t=0.0):
    sp = V.prop(name)
    if haze:
        sp = V.tint(sp, V.hx(haze), t)
    if k != 1.0:
        sp = sp.resize((max(1, int(sp.width * k)), max(1, int(sp.height * k))), Image.NEAREST)
    return sp


def tint_road(img, c, y0, y1):
    """Recolour the trail band for the terrain (grey scree, dark mud...)."""
    if 'road_tint' not in c:
        return
    col, t = c['road_tint']
    band = img.crop((0, y0, img.width, y1))
    img.paste(V.tint(band, V.hx(col), t), (0, y0))


def grass(img, r, y0, y1, c, base=None):
    top, b, blades, flowers = c['grass']
    base = base or b
    d = ImageDraw.Draw(img)
    for y in range(y0, y1):
        t = (y - y0) / max(1, y1 - y0)
        d.line((0, y, V.W, y), fill=V.mix(V.hx(top), V.hx(base), t))
    for _ in range(int(V.W * (y1 - y0) / 6)):
        x, y = r.randint(0, V.W), r.randint(y0, y1)
        d.line((x, y, x + r.randint(-1, 1), y - r.randint(1, 4)), fill=V.hx(r.choice(blades)))
    for _ in range(int(V.W * (y1 - y0) / 220)):
        x, y = r.randint(0, V.W), r.randint(y0, y1)
        d.point((x, y), fill=V.hx(r.choice(flowers)))
    if c.get('snowy'):
        ov = Image.new('RGBA', img.size, (0, 0, 0, 0))
        od = ImageDraw.Draw(ov)
        for _ in range(int(V.W * (y1 - y0) / 900)):
            x, y = r.randint(0, V.W), r.randint(y0, y1)
            w = r.randint(8, 30)
            od.ellipse((x, y, x + w, y + w // 4 + 1), fill=(240, 244, 252, 200))
        img.alpha_composite(ov)


def water(img, r, y0, y1, murk=False):
    """A band of still water with reflections and shimmer, behind the road."""
    d = ImageDraw.Draw(img)
    top, bot = (V.hx('#5f8f86'), V.hx('#3c6460')) if murk else (V.hx('#8cc0d0'), V.hx('#4f86a0'))
    for y in range(y0, y1):
        t = (y - y0) / max(1, y1 - y0)
        d.line((0, y, V.W, y), fill=V.mix(top, bot, t))
    for _ in range(int(V.W * (y1 - y0) / 60)):
        x, y = r.randint(0, V.W), r.randint(y0 + 1, y1 - 1)
        w = r.randint(3, 14)
        d.line((x, y, x + w, y), fill=V.hx('#a8d0c0' if murk else '#e4f4f8', 255))
    if murk:
        for _ in range(int(V.W * (y1 - y0) / 500)):
            x, y = r.randint(0, V.W), r.randint(y0 + 2, y1 - 2)
            d.ellipse((x, y, x + 6, y + 2), fill=V.hx('#5c8a44'))
    # bank lines
    d.line((0, y0, V.W, y0), fill=V.hx('#2f4c3c'))
    d.line((0, y1 - 1, V.W, y1 - 1), fill=V.hx('#6a5a3c'))


def rolling(seed, base, cols):
    """Soft rolling hills band (Hills far layer)."""
    ov, _ = V.ridge_layer(seed, base, 34, cols[1], cols[2], 0.6)
    ov2, _ = V.ridge_layer(seed + 5, base + 16, 22, cols[0], cols[1], 0.8)
    ov.alpha_composite(ov2)
    return ov


def sky_layers(c, r, hz, width):
    V.W = width
    sky = V.gradient(c['sky'], H)
    d_clouds = 14 if width > 700 else 8
    for i in range(d_clouds):
        cx, cy, cw = r.randint(0, width), r.randint(26, max(30, hz - 64)), r.randint(40, 120)
        for dx in ((0, -width) if width > 700 else (0,)):
            V.cloud(sky, random.Random(i), cx + dx, cy, cw, *c['cloud'])
    return sky


def mountain_layer(c, hz, width, periodic):
    V.W = width
    V.PERIODIC = periodic
    out = Image.new('RGBA', (width, H), (0, 0, 0, 0))
    a = c['mtn1']
    m, _ = V.mountains(3, hz, a[4], a[0], a[1], a[2], a[3], 1.0)
    out.alpha_composite(m)
    V.haze_band(out, hz - 50, hz + 6, c['haze'], 0.0, 0.45)
    a = c['mtn2']
    m, _ = V.mountains(9, hz + 18, a[4], a[0], a[1], a[2], a[3], 1.2)
    out.alpha_composite(m)
    V.haze_band(out, hz - 10, hz + 24, c['haze'], 0.0, 0.35)
    V.PERIODIC = False
    return out


def far_band(c, r, base, width, far_props, scale):
    """Far canopy (or rolling hills) with a couple of hazy far props."""
    V.W = width
    out = Image.new('RGBA', (width, H), (0, 0, 0, 0))
    if c.get('rolling'):
        out.alpha_composite(rolling(31, base + 4, c['near']))
    for i, name in enumerate(far_props):
        sp = prop(name, 0.75 * scale, c['far_tint'], 0.35)
        x = int(width * (0.3 + 0.45 * i)) + r.randint(-40, 40)
        V.put(out, sp, x, base + 14)
    out.alpha_composite(V.canopy(31, base, *c['far']))
    if c.get('murk'):
        V.haze_band(out, base - 40, base + 10, '#c8c8a0', 0.0, 0.35)
    return out


def travel(name, c):
    r = random.Random(6)
    hz = 170
    d = os.path.join(OUT, 'travel', name)
    os.makedirs(d, exist_ok=True)
    sky = sky_layers(c, r, hz, TW + OV)
    sky.crop((0, 0, TW, H)).save(d + '/sky.png')
    mountain_layer(c, hz, TW, True).save(d + '/mountains.png')
    far = far_band(c, r, 200, TW + OV, c['far_props'], 1.0)
    wrap(far).save(d + '/far.png')
    V.W = TW + OV
    nb = Image.new('RGBA', (TW + OV, H), (0, 0, 0, 0))
    nb.alpha_composite(V.canopy(32, 222, *c['near']))
    if c.get('water'):
        grass(nb, r, 222, 232, c)
        water(nb, r, 232, 262, c.get('murk', False))
        grass(nb, r, 262, 276, c)
    else:
        grass(nb, r, 222, 276, c)
    V.trail2(nb, r, 276, 312)
    tint_road(nb, c, 276, 312)
    grass(nb, r, 312, H, c, c['grass_near'])
    near = wrap(nb)
    V.W = TW
    xs = [10, 160, 330, 470, 600, 760, 900, 1060]
    for i, pn in enumerate(c['road']):
        sp = prop(pn)
        yb = 262 if (c.get('water') and pn in ('river_jetty', 'river_rocks', 'swamp_cattails', 'swamp_boiler', 'swamp_mangrove')) else 274 + (i % 3)
        putw(near, sp, xs[i] + r.randint(-20, 20), yb, i % 2 == 1)
    near.save(d + '/ground.png')
    fg = Image.new('RGBA', (TW, H), (0, 0, 0, 0))
    for i, pn in enumerate(c['fg'] + c['fg'][:3]):
        x = -24 + i * 160 + r.randint(-20, 20)
        putw(fg, prop(pn), x, H + 8 + (30 if pn == 'leaves_foreground' else r.randint(0, 10)), i % 2 == 1)
    fg.save(d + '/foreground.png')


def battle(name, c):
    r = random.Random(4)
    hz, road = 100, (162, 350)
    W = 640
    back = sky_layers(c, r, hz, W)
    V.W = W
    if c.get('sun'):
        V.sun(back, 250, hz - 62, 12)
        V.rays(back, 250, hz - 62, 7, 14)
    back.alpha_composite(mountain_layer(c, hz, W, False))
    back.save(os.path.join(OUT, 'battle', name + '_back.png'))
    front = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    V.W = W
    front.alpha_composite(V.canopy(21, 132, *c['far']))
    V.haze_band(front, 110, 140, c['haze'], 0.25, 0.0)
    if c.get('rolling'):
        front.alpha_composite(rolling(33, 150, c['near']))
    front.alpha_composite(V.canopy(22, 150, *c['near']))
    if c.get('water'):
        grass(front, r, 150, 156, c)
        V.W = W
        water(front, r, 152, road[0] - 2, c.get('murk', False))
    else:
        grass(front, r, 150, road[0], c)
    V.trail2(front, r, road[0], road[1])
    tint_road(front, c, road[0], road[1])
    for i, (x, k) in enumerate(((-20, .75), (250, .6), (330, .6), (520, .75))):
        pn = c['road'][[0, 1, 5, 4][i]]
        V.put(front, prop(pn, k, c['far_tint'], 0.12 if k > .7 else 0.35), x, road[0] + 2, i % 2 == 1)
    grass(front, r, road[1], H, c, c['grass_near'])
    for pn, x in ((c['fg'][0], -20), (c['fg'][1], 600)):
        V.put(front, prop(pn), x, H + 30)
    front.save(os.path.join(OUT, 'battle', name + '_front.png'))


if __name__ == '__main__':
    os.makedirs(os.path.join(OUT, 'battle'), exist_ok=True)
    only = sys.argv[2:] or list(T)
    for name in only:
        travel(name, T[name])
        battle(name, T[name])
        print('ok', name, flush=True)
    sun = Image.new('RGBA', (640, H), (0, 0, 0, 0))
    V.W = 640
    V.sun(sun, 500, 170 - 62, 12)
    V.rays(sun, 500, 170 - 62, 7, 14)
    sun.save(os.path.join(OUT, 'travel', 'sun.png'))
