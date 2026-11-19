"""Layered naturepunk scenery: dithered sky, hazy ridges, tree line, Sprite Fusion props, trail, foreground."""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw

W, H = 640, 360
PERIODIC = False
PROPS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets', 'props')
PROPS = {'p_tower_0': 'clocktower_ruin', 'p_tree1_0': 'tree_ancient', 'p_tree2_0': 'tree_lantern', 'p_pylon_0': 'pylon_overgrown',
         'p_windmill_0': 'windmill_ruin', 'p_fern_0': 'fern_cluster', 'p_leaves_0': 'leaves_foreground', 'p_rocks_0': 'rocks_crystal',
         'p_stump_0': 'stump_mushroom', 'p_wheel_0': 'wheel_buried', 'p_bush_0': 'bush_flowering', 'p_grass_0': 'grass_wildflower'}
BAYER = (np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) + 0.5) / 16


def hx(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def prop(name):
    return Image.open(os.path.join(PROPS_DIR, PROPS.get(name, name) + '.png')).convert('RGBA')


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


def tint(sp, col, t):
    """Blend a sprite's colors toward col (atmospheric haze), keep alpha."""
    a = np.array(sp).astype(float)
    a[..., :3] = a[..., :3] * (1 - t) + np.array(col[:3]) * t
    return Image.fromarray(a.astype(np.uint8), 'RGBA')


def gradient(stops, h):
    """Banded, Bayer-dithered vertical gradient. stops: list of (y_frac, color)."""
    arr = np.zeros((h, W, 4), np.uint8)
    cols = [np.array(hx(cl)[:3], float) for _, cl in stops]
    ys = [f * h for f, _ in stops]
    for y in range(h):
        k = max(i for i in range(len(ys)) if ys[i] <= y) if y >= ys[0] else 0
        k = min(k, len(ys) - 2)
        t = (y - ys[k]) / max(1, ys[k + 1] - ys[k])
        t = min(max(t, 0), 1)
        band = t * 6  # 6 dithered bands per segment
        lo = math.floor(band)
        frac = band - lo
        c0 = cols[k] + (cols[k + 1] - cols[k]) * (lo / 6)
        c1 = cols[k] + (cols[k + 1] - cols[k]) * (min(lo + 1, 6) / 6)
        mask = BAYER[y % 4][np.arange(W) % 4] < frac
        arr[y, :, :3] = np.where(mask[:, None], c1, c0)
        arr[y, :, 3] = 255
    return Image.fromarray(arr, 'RGBA')


def sun(img, x, y, r):
    d = ImageDraw.Draw(img)
    for rad, col in ((r + 14, '#ffe2a8'), (r + 8, '#ffd78a'), (r + 3, '#ffeab8'), (r, '#fff6dc')):
        ov = Image.new('RGBA', img.size, (0, 0, 0, 0))
        ImageDraw.Draw(ov).ellipse((x - rad, y - rad, x + rad, y + rad), fill=hx(col, 70 if rad > r else 255))
        img.alpha_composite(ov)


def cloud(img, r, x, y, w, lit, mid, dark):
    """Pixel cloud: stacked puffs, lit top, shaded underside, flat base."""
    ov = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    puffs = []
    n = max(3, w // 14)
    for i in range(n):
        px = x + i * w / n + r.randint(-3, 3)
        pr = r.randint(7, 15) * (1.25 if 0 < i < n - 1 else 0.8)
        puffs.append((px, y - pr * 0.5, pr))
    for px, py, pr in puffs:
        d.ellipse((px - pr, py - pr, px + pr, py + pr), fill=hx(dark))
    for px, py, pr in puffs:
        d.ellipse((px - pr + 1, py - pr, px + pr - 1, py + pr - 4), fill=hx(mid))
    for px, py, pr in puffs:
        d.ellipse((px - pr + 3, py - pr, px + pr - 5, py + pr * 0.2 - 4), fill=hx(lit))
    # flat base
    a = np.array(ov)
    a[int(y + 4):, :, 3] = 0
    img.alpha_composite(Image.fromarray(a, 'RGBA'))


def ridge_layer(seed, base, amp, col, top_col=None, rough=1.0):
    r = random.Random(seed)
    ph = [(r.uniform(0, 6.3), r.uniform(0.004, 0.03) * rough, r.uniform(.3, 1)) for _ in range(6)]
    ov = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    tops = []
    for x in range(W):
        v = sum(a * math.sin(x * f + p) for p, f, a in ph) / sum(a for _, _, a in ph)
        v += 0.25 * math.sin(x * 0.11 + seed) * rough
        yt = int(base - amp * (0.5 + 0.5 * v))
        tops.append(yt)
        d.line((x, yt, x, H), fill=hx(col))
        if top_col:
            d.line((x, yt, x, yt + 1), fill=hx(top_col))
    return ov, tops


def treeline(seed, base, col, light, dark, density=1.0, size=(8, 16)):
    """Rounded canopy tree line with lit tops, dithered shading."""
    r = random.Random(seed)
    ov = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    d.rectangle((0, base, W, H), fill=hx(col))
    x = -10
    crowns = []
    while x < W + 10:
        s = r.randint(*size)
        cy = base - r.randint(int(s * .6), int(s * 1.6))
        crowns.append((x, cy, s))
        x += int(s * r.uniform(0.9, 1.5) / density)
    for x, cy, s in crowns:
        d.rectangle((x - 1, cy, x + 1, base), fill=hx(dark))
        d.ellipse((x - s, cy - s, x + s, cy + s), fill=hx(col))
    for x, cy, s in crowns:
        d.ellipse((x - s + 2, cy - s, x + s - 4, cy + s - 6), fill=hx(light))
        d.ellipse((x - s + 4, cy - s + 3, x + s - 3, cy + s - 3), fill=hx(col))
    # dither underside of crowns toward dark
    a = np.array(ov)
    for y in range(H):
        if y < base - 2:
            continue
    return ov


def haze_band(img, y0, y1, col, a0, a1):
    ov = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    arr = np.array(ov)
    for y in range(y0, y1):
        t = (y - y0) / max(1, y1 - y0)
        al = a0 + (a1 - a0) * t
        mask = BAYER[y % 4][np.arange(W) % 4] < al
        arr[y, mask] = hx(col)
    img.alpha_composite(Image.fromarray(arr, 'RGBA'))


def bottom_of(sp):
    a = np.array(sp)[..., 3]
    rows = np.where(a.max(axis=1) > 0)[0]
    return rows[-1] + 1


def put(img, sp, x, yb, flip=False):
    if flip:
        sp = sp.transpose(Image.FLIP_LEFT_RIGHT)
    img.alpha_composite(sp, (int(x), int(yb - bottom_of(sp))))


def shadow(img, x, yb, w, a=70):
    ov = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(ov).ellipse((x, yb - 3, x + w, yb + 3), fill=(40, 30, 30, a))
    img.alpha_composite(ov)


def trail(img, r, y0, y1, edge_grass=True):
    """Packed-earth trail with light gradient, ruts, pebbles, grass edges and dappled light."""
    d = ImageDraw.Draw(img)
    h = y1 - y0
    top, midc, bot = hx('#c79a68'), hx('#b4875a'), hx('#9a7049')
    for y in range(y0, y1):
        t = (y - y0) / max(1, h)
        col = mix(top, midc, t * 2) if t < .5 else mix(midc, bot, (t - .5) * 2)
        d.line((0, y, W, y), fill=col)
    # wheel ruts
    for ry in (y0 + int(h * .38), y0 + int(h * .62)):
        for x in range(W):
            if r.random() < .93:
                d.point((x, ry), fill=hx('#8e6542'))
                if r.random() < .5:
                    d.point((x, ry + 1), fill=hx('#d2aa78'))
    # dappled light
    ov = Image.new('RGBA', img.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(ov)
    for _ in range(int(W * h / 1800)):
        x, y = r.randint(0, W), r.randint(y0 + 4, y1 - 4)
        w = r.randint(8, 26)
        od.ellipse((x, y, x + w, y + w // 3), fill=(255, 226, 160, 34))
    for _ in range(int(W * h / 2200)):
        x, y = r.randint(0, W), r.randint(y0 + 4, y1 - 4)
        w = r.randint(10, 30)
        od.ellipse((x, y, x + w, y + w // 3), fill=(70, 40, 30, 28))
    img.alpha_composite(ov)
    # pebbles and specks
    for _ in range(int(W * h / 120)):
        x, y = r.randint(0, W - 2), r.randint(y0 + 2, y1 - 2)
        k = r.random()
        if k < .55:
            d.point((x, y), fill=hx(r.choice(['#d8b688', '#8b6443', '#a57b52'])))
        elif k < .8:
            d.rectangle((x, y, x + 1, y), fill=hx('#7c5a3c'))
            d.point((x, y - 1), fill=hx('#e2c49a'))
        else:
            d.line((x, y, x + r.randint(-1, 1), y - r.randint(1, 3)), fill=hx(r.choice(['#6f9a4c', '#86b05a'])))
    if edge_grass:
        for x in range(0, W):
            for yy, up_ in ((y0, True), (y1, False)):
                hgt = r.randint(1, 5)
                col = hx(r.choice(['#4f7f3c', '#62924a', '#3f6c34']))
                if up_:
                    d.line((x, yy + 1, x + r.randint(-1, 1), yy + 1 - hgt), fill=col)
                else:
                    d.line((x, yy - 1, x + r.randint(-1, 1), yy - 1 + hgt // 2), fill=col)


def grassland(img, r, y0, y1, base='#4e7d3a'):
    d = ImageDraw.Draw(img)
    for y in range(y0, y1):
        t = (y - y0) / max(1, y1 - y0)
        d.line((0, y, W, y), fill=mix(hx('#6a9a4a'), hx(base), t))
    for _ in range(int(W * (y1 - y0) / 6)):
        x, y = r.randint(0, W), r.randint(y0, y1)
        d.line((x, y, x + r.randint(-1, 1), y - r.randint(1, 4)), fill=hx(r.choice(['#3f6c34', '#7aaa52', '#5a8a44', '#8cbc5e'])))
    for _ in range(int(W * (y1 - y0) / 220)):
        x, y = r.randint(0, W), r.randint(y0, y1)
        d.point((x, y), fill=hx(r.choice(['#f2d36b', '#f4a3c0', '#ffffff', '#b99cf0'])))


SKY = [(0, '#2f5d78'), (.35, '#6f8fa6'), (.62, '#e8b88a'), (.85, '#f6d49a'), (1, '#fbe6b4')]
FAR = '#9fb4c4'


def sky_and_far(img, r, horizon, sunx=470):
    """Sky gradient, sun, clouds, three hazy ridges, distant landmark tower."""
    img.alpha_composite(gradient(SKY, horizon + 40), (0, 0))
    sun(img, sunx, horizon - 46, 13)
    for i in range(7):
        cx = r.randint(-30, W - 40)
        cy = r.randint(26, horizon - 70)
        cloud(img, r, cx, cy, r.randint(40, 110), '#fde8c8', '#f2b9a0', '#c98e98')
    ov, _ = ridge_layer(3, horizon - 6, 50, '#a9b9cc', '#c9d4de', 0.8)
    img.alpha_composite(ov)
    tower = tint(prop('p_tower_0'), hx('#a9b9cc'), 0.55)
    put(img, tower, 92, horizon + 4)
    ov, _ = ridge_layer(11, horizon + 8, 40, '#8aa1b4', '#a8bccb', 1.1)
    img.alpha_composite(ov)
    haze_band(img, horizon - 30, horizon + 20, '#f3d6b0', 0.0, 0.35)
    ov, _ = ridge_layer(19, horizon + 22, 30, '#6f8ea0', '#86a3b2', 1.4)
    img.alpha_composite(ov)


def far_forest(img, r, base):
    img.alpha_composite(treeline(5, base, '#4f7a78', '#6b9488', '#3e6466', 1.2, (6, 12)))
    wm = tint(prop('p_windmill_0'), hx('#7f9e9a'), 0.35)
    put(img, wm.resize((wm.width * 3 // 4, wm.height * 3 // 4), Image.NEAREST), 520, base + 4)
    py = tint(prop('p_pylon_0'), hx('#7f9e9a'), 0.35)
    put(img, py.resize((py.width * 3 // 4, py.height * 3 // 4), Image.NEAREST), 300, base + 6)
    img.alpha_composite(treeline(8, base + 14, '#3f6a4c', '#5d8a56', '#2f5240', 1.0, (8, 15)))
    haze_band(img, base - 30, base + 14, '#f0d2a4', 0.18, 0.0)


# ---------- v2 upgrades ----------
def haze_band(img, y0, y1, col, a0, a1):
    arr = np.zeros((H, W, 4), np.uint8)
    for y in range(max(0, y0), min(H, y1)):
        t = (y - y0) / max(1, y1 - y0)
        arr[y, :, :3] = hx(col)[:3]
        arr[y, :, 3] = int(255 * (a0 + (a1 - a0) * t))
    img.alpha_composite(Image.fromarray(arr, 'RGBA'))


def mountains(seed, base, amp, col, lit, shade, snow=None, rough=1.0):
    """Faceted mountain range: sun-facing slopes lit, others shaded, optional snow caps."""
    r = random.Random(seed)
    # midpoint displacement for craggy peaks
    n = 129
    pts = [0.0] * n
    pts[0], pts[-1] = r.random(), r.random()
    if PERIODIC:
        pts[-1] = pts[0]
    step, scale = n - 1, 1.0
    while step > 1:
        half = step // 2
        for i in range(half, n - 1, step):
            pts[i] = (pts[i - half] + pts[i + half]) / 2 + r.uniform(-scale, scale) * 0.5 * rough
        step, scale = half, scale * 0.55
    lo, hi = min(pts), max(pts)
    tops = []
    for x in range(W):
        f = x / (W - 1) * (n - 1)
        i = min(int(f), n - 2)
        v = pts[i] + (pts[i + 1] - pts[i]) * (f - i)
        tops.append(int(base - amp * (v - lo) / (hi - lo + 1e-6)))
    arr = np.zeros((H, W, 4), np.uint8)
    C, L, S = np.array(hx(col)), np.array(hx(lit)), np.array(hx(shade))
    sm = np.convolve(np.array(tops, float), np.ones(9) / 9, mode='same')
    for x in range(W):
        yt = tops[x]
        slope = sm[min(x + 3, W - 1)] - sm[max(x - 3, 0)]
        arr[yt:H, x] = C
        face = L if slope > 1.5 else (S if slope < -1.5 else None)
        if face is not None:
            depth = int(min(60, 10 + abs(slope) * 6))
            for y in range(yt, min(H, yt + depth)):
                fade = (y - yt) / depth
                if BAYER[y % 4][x % 4] > fade:
                    arr[y, x] = face
        arr[yt, x] = L if slope >= 0 else C
        if snow and yt < base - amp * 0.7:
            k = int((base - amp * 0.7 - yt) * 0.6)
            for y in range(yt, yt + k):
                if BAYER[y % 4][x % 4] > (y - yt) / max(1, k):
                    arr[y, x] = np.array(hx(snow)) if slope >= -1.5 else np.array(hx('#c9cfe0'))
    return Image.fromarray(arr, 'RGBA'), tops


def canopy(seed, base, dark, mid, light, rim, density=1.0, size=(7, 14), trunks=True):
    """Detailed forest band: clustered crowns shaded dark->mid->light with warm rim on sun side."""
    r = random.Random(seed)
    ov = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    d.rectangle((0, base, W, H), fill=hx(dark))
    crowns = []
    x = -12
    while x < W + 12:
        s = r.randint(*size)
        crowns.append((x, base - r.randint(int(s * .4), int(s * 1.5)), s))
        x += max(3, int(s * r.uniform(.7, 1.3) / density))
    for x, cy, s in crowns:
        if trunks:
            if cy + s // 2 < base: d.rectangle((x - 1, cy + s // 2, x, base), fill=hx(dark))
        d.ellipse((x - s, cy - s, x + s, cy + s), fill=hx(dark))
    for x, cy, s in crowns:
        for _ in range(3):
            ox, oy, rr = r.randint(-s // 2, s // 2), r.randint(-s // 2, 0), int(s * r.uniform(.45, .7))
            d.ellipse((x + ox - rr, cy + oy - rr, x + ox + rr, cy + oy + rr), fill=hx(mid))
    for x, cy, s in crowns:
        rr = int(s * .45)
        d.ellipse((x + s // 4 - rr, cy - s // 2 - rr, x + s // 4 + rr, cy - s // 2 + rr), fill=hx(light))
        d.arc((x - s + 1, cy - s + 1, x + s - 1, cy + s - 1), 285, 350, fill=hx(rim))
        for _ in range(3):
            px, py = x + r.randint(-s + 2, s - 2), cy + r.randint(-s + 2, s - 2)
            d.point((px, py), fill=hx(light))
    return ov


def rays(img, sx, sy, n=6, alpha=22, seed=1):
    r = random.Random(seed)
    ov = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    for i in range(n):
        ang = math.radians(r.uniform(105, 170))
        w = math.radians(r.uniform(2, 5))
        L = 700
        p1 = (sx + L * math.cos(ang - w), sy + L * math.sin(ang - w))
        p2 = (sx + L * math.cos(ang + w), sy + L * math.sin(ang + w))
        d.polygon([(sx, sy), p1, p2], fill=(255, 236, 190, alpha))
    img.alpha_composite(ov)


def grade(img, warm=0.10, vignette=0.28):
    a = np.array(img).astype(float)
    yy, xx = np.mgrid[0:img.height, 0:img.width]
    a[..., 0] += 255 * warm * 0.35
    a[..., 1] += 255 * warm * 0.15
    a[..., 2] -= 255 * warm * 0.2
    d = np.sqrt(((xx - img.width / 2) / (img.width / 2)) ** 2 + ((yy - img.height / 2) / (img.height / 2)) ** 2)
    v = 1 - vignette * np.clip(d - 0.55, 0, 1) ** 1.5
    a[..., :3] *= v[..., None]
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA')


def trail2(img, r, y0, y1):
    trail(img, r, y0, y1)
    ov = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    # soft shade under the far grass edge and near edge
    for i in range(6):
        d.line((0, y0 + 1 + i, W, y0 + 1 + i), fill=(60, 36, 24, 50 - i * 8))
        d.line((0, y1 - 1 - i, W, y1 - 1 - i), fill=(60, 36, 24, 40 - i * 6))
    img.alpha_composite(ov)
    d = ImageDraw.Draw(img)
    # grass tongues creeping onto the trail and small stones with highlights
    for _ in range(W // 18):
        x = r.randint(0, W)
        edge = r.choice([y0, y1])
        for k in range(r.randint(4, 10)):
            gx = x + r.randint(-8, 8)
            gy = edge + (r.randint(1, 6) if edge == y0 else -r.randint(1, 6))
            d.line((gx, gy, gx + r.randint(-1, 1), gy - r.randint(2, 4)), fill=hx(r.choice(['#4f7f3c', '#6a9a4a', '#86b05a'])))
    for _ in range(int(W * (y1 - y0) / 1400)):
        x, y = r.randint(0, W - 4), r.randint(y0 + 6, y1 - 6)
        w = r.randint(2, 4)
        d.ellipse((x, y, x + w, y + w - 1), fill=hx('#8a6a4c'))
        d.point((x + 1, y), fill=hx('#e6caa0'))
        d.line((x, y + w, x + w, y + w), fill=hx('#6f4f36'))


def sky_and_far2(img, r, horizon, sunx=470, tower_x=92):
    img.alpha_composite(gradient(SKY, horizon + 60), (0, 0))
    sun(img, sunx, horizon - 62, 12)
    rays(img, sunx, horizon - 62, 7, 14)
    for i in range(8):
        cx = r.randint(-30, W - 40)
        cy = r.randint(30, max(40, horizon - 64))
        cloud(img, r, cx, cy, r.randint(40, 120), '#fde8c8', '#f2b9a0', '#c98e98')
    m, _ = mountains(3, horizon, 70, '#a7b3cc', '#d8cfd6', '#8f9cba', '#f4ece8', 1.0)
    img.alpha_composite(m)
    haze_band(img, horizon - 50, horizon + 6, '#f6dcbc', 0.0, 0.45)
    m, _ = mountains(9, horizon + 18, 44, '#7f93ad', '#a9b6c6', '#6b7f9a', None, 1.2)
    img.alpha_composite(m)
    haze_band(img, horizon - 10, horizon + 24, '#f0d4b4', 0.0, 0.35)
    tw = tint(prop('p_tower_0'), hx('#9aa8c0'), 0.3)
    tw = tw.resize((tw.width * 3 // 4, tw.height * 3 // 4), Image.NEAREST)
    put(img, tw, tower_x, horizon + 40)
