import struct
import zlib
import math

def write_png(filename, width, height, rgba_data):
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        raw.extend(rgba_data[y * width * 4 : (y + 1) * width * 4])
    compressed = zlib.compress(bytes(raw), 9)
    
    png = bytearray(b'\x89PNG\r\n\x1a\n')
    def chunk(tag, data):
        c = bytearray(tag) + data
        crc = zlib.crc32(c)
        png.extend(struct.pack('>I', len(data)))
        png.extend(c)
        png.extend(struct.pack('>I', crc))
        
    chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    chunk(b'IDAT', compressed)
    chunk(b'IEND', b'')
    with open(filename, 'wb') as f:
        f.write(png)

def point_in_poly(x, y, poly):
    n = len(poly)
    inside = False
    p1x, p1y = poly[0]
    for i in range(n + 1):
        p2x, p2y = poly[i % n]
        if y > min(p1y, p2y):
            if y <= max(p1y, p2y):
                if x <= max(p1x, p2x):
                    if p1y != p2y:
                        xinters = (y - p1y) * (p2x - p1x) / (p2y - p1y) + p1x
                    if p1x == p2x or x <= xinters:
                        inside = not inside
        p1x, p1y = p2x, p2y
    return inside

# -------------------------------------------------------------
# 1. BOTTLE CORK STOPPER (Rolha de Garrafa)
# -------------------------------------------------------------
def create_bottle_cork(size=24):
    buf = bytearray(size * size * 4)
    
    # Wine bottle cork:
    # Classic stopper: has a slightly wider top rim / rounded lip, and tapered cylinder body.
    # Top ellipse: center (12, 5.5), rx=6.5, ry=2.4
    # Rim bevel: y from 5.5 to 8.5, rx=6.5, ry=2.4
    # Body: y from 8.5 to 19.5, tapering from rx=5.5 down to rx=4.5
    # Bottom ellipse: center (12, 19.5), rx=4.5, ry=1.8
    
    for y in range(size):
        for x in range(size):
            sub_samples = [
                (x + 0.25, y + 0.25), (x + 0.75, y + 0.25),
                (x + 0.25, y + 0.75), (x + 0.75, y + 0.75)
            ]
            ar, ag, ab, aa = 0, 0, 0, 0
            
            for sx, sy in sub_samples:
                # Top ellipse check
                in_top_cap = False
                dt = ((sx - 12.0) / 6.4)**2 + ((sy - 5.5) / 2.3)**2
                if dt <= 1.0:
                    in_top_cap = True
                    
                # Upper rim (lip)
                in_lip = False
                if 5.5 <= sy <= 9.0 and abs(sx - 12.0) <= 6.4:
                    in_lip = True
                dlip_bot = ((sx - 12.0) / 6.4)**2 + ((sy - 9.0) / 2.3)**2
                if dlip_bot <= 1.0:
                    in_lip = True
                    
                # Main tapered cork body
                in_body = False
                if 9.0 <= sy <= 19.0:
                    t_body = (sy - 9.0) / 10.0
                    rx_body = 5.6 * (1.0 - t_body) + 4.6 * t_body
                    if abs(sx - 12.0) <= rx_body:
                        in_body = True
                dbot = ((sx - 12.0) / 4.6)**2 + ((sy - 19.0) / 1.8)**2
                if dbot <= 1.0:
                    in_body = True
                    
                in_cork = in_top_cap or in_lip or in_body
                if not in_cork:
                    continue
                    
                # Shading
                # Cylinder lighting: light from top-left (around sx=9.5)
                norm_x = (sx - 9.5) / 6.0
                cyl_shade = max(0.0, min(1.0, 0.5 - 0.45 * norm_x))
                
                # Base cork colors
                # warm tan / cork wood
                cork_hi = (225, 185, 130)
                cork_mid = (190, 150, 100)
                cork_dark = (135, 95, 55)
                cork_deep = (75, 48, 26)
                
                # Porous cork speckles using noise
                speckle = 1.0
                p_noise = math.sin(sx * 4.2 + sy * 2.1) * math.cos(sx * 1.7 - sy * 3.4)
                if p_noise > 0.45:
                    speckle = 0.72  # dark pore/speckle
                elif p_noise < -0.6:
                    speckle = 1.15  # light speckle
                    
                if in_top_cap and sy <= 6.0:
                    # Top surface
                    r = int(cork_hi[0] * speckle)
                    g = int(cork_hi[1] * speckle)
                    b = int(cork_hi[2] * speckle)
                    # rim edge
                    if dt > 0.8:
                        r = int(r * 0.85); g = int(g * 0.85); b = int(b * 0.85)
                elif in_lip:
                    # Upper lip rim
                    t_l = (sy - 5.5) / 3.5
                    factor = (0.7 + 0.3 * cyl_shade) * speckle
                    r = int((cork_hi[0] * (1 - t_l*0.3) * factor))
                    g = int((cork_hi[1] * (1 - t_l*0.3) * factor))
                    b = int((cork_hi[2] * (1 - t_l*0.3) * factor))
                else:
                    # Body
                    t_b = (sy - 9.0) / 10.0
                    factor = (0.55 + 0.45 * cyl_shade) * speckle
                    r = int((cork_mid[0] * (1 - t_b*0.25) * factor))
                    g = int((cork_mid[1] * (1 - t_b*0.25) * factor))
                    b = int((cork_mid[2] * (1 - t_b*0.25) * factor))
                    
                # 1px Dark contour on outer perimeter
                # Check distance to outer boundary
                d_out = False
                if abs(sx - 12.0) > 5.8 and (in_lip or in_top_cap):
                    d_out = True
                elif 9.0 <= sy <= 19.0:
                    t_body = (sy - 9.0) / 10.0
                    rx_b = 5.6 * (1.0 - t_body) + 4.6 * t_body
                    if abs(sx - 12.0) > rx_b - 0.7:
                        d_out = True
                if sy > 19.5 or (sy < 4.0 and in_top_cap):
                    d_out = True
                    
                if d_out:
                    r = int(r * 0.45 + cork_deep[0] * 0.55)
                    g = int(g * 0.45 + cork_deep[1] * 0.55)
                    b = int(b * 0.45 + cork_deep[2] * 0.55)

                ar += min(255, max(0, r))
                ag += min(255, max(0, g))
                ab += min(255, max(0, b))
                aa += 255
                
            idx = (y * size + x) * 4
            buf[idx] = min(255, ar // 4)
            buf[idx+1] = min(255, ag // 4)
            buf[idx+2] = min(255, ab // 4)
            buf[idx+3] = min(255, aa // 4)
            
    return bytes(buf)

# -------------------------------------------------------------
# 2. METALLIC INGOT BAR GENERATOR (Iron and Lead)
# -------------------------------------------------------------
def create_ingot(size=24, metal_type="iron"):
    buf = bytearray(size * size * 4)
    
    # 3D Ingot trapezoidal prism polygons
    # Top face: narrower top surface
    top_poly = [
        (6.0, 7.0),
        (16.5, 6.0),
        (18.5, 9.5),
        (8.0, 10.5)
    ]
    # Front face: wide sloped face
    front_poly = [
        (8.0, 10.5),
        (18.5, 9.5),
        (16.5, 17.0),
        (5.0, 18.0)
    ]
    # Side face (left side facet):
    left_poly = [
        (6.0, 7.0),
        (8.0, 10.5),
        (5.0, 18.0),
        (3.5, 14.0)
    ]
    # Right side face (corner bevel):
    right_poly = [
        (16.5, 6.0),
        (20.0, 8.5),
        (18.0, 15.5),
        (16.5, 17.0),
        (18.5, 9.5)
    ]

    if metal_type == "iron":
        # Shiny silver/steel with bright reflection
        top_color_hi = (240, 245, 252)
        top_color_lo = (190, 202, 218)
        front_color_hi = (165, 178, 195)
        front_color_lo = (115, 128, 145)
        side_color = (75, 88, 105)
        highlight_edge = (255, 255, 255)
        dark_contour = (35, 42, 52)
    else: # lead
        # Dark heavy slate-blue/charcoal industrial ingot
        top_color_hi = (130, 145, 168)
        top_color_lo = (95, 108, 128)
        front_color_hi = (75, 88, 106)
        front_color_lo = (48, 58, 72)
        side_color = (30, 38, 50)
        highlight_edge = (165, 182, 205)
        dark_contour = (16, 22, 30)

    for y in range(size):
        for x in range(size):
            sub_samples = [
                (x + 0.25, y + 0.25), (x + 0.75, y + 0.25),
                (x + 0.25, y + 0.75), (x + 0.75, y + 0.75)
            ]
            ar, ag, ab, aa = 0, 0, 0, 0
            
            for sx, sy in sub_samples:
                in_top = point_in_poly(sx, sy, top_poly)
                in_front = point_in_poly(sx, sy, front_poly)
                in_left = point_in_poly(sx, sy, left_poly)
                in_right = point_in_poly(sx, sy, right_poly)
                
                if not (in_top or in_front or in_left or in_right):
                    # Drop shadow underneath ingot
                    if 17.0 <= sy <= 20.0 and 4.0 <= sx <= 19.0:
                        d_sh = sy - 17.0
                        ar += 12; ag += 15; ab += 20; aa += int(90 * (1.0 - d_sh/3.0))
                    continue
                    
                if in_top:
                    # Top face gradient + diagonal shine
                    t_diag = ((sx - 6.0) + (sy - 7.0)) / 14.0
                    shine = 0.0
                    # Diagonal specular glint across top
                    if abs((sx - 7.0) - (sy - 6.0) * 1.5) <= 1.8:
                        shine = 0.35
                    r = int(top_color_lo[0] * (1 - t_diag) + top_color_hi[0] * t_diag + 255 * shine)
                    g = int(top_color_lo[1] * (1 - t_diag) + top_color_hi[1] * t_diag + 255 * shine)
                    b = int(top_color_lo[2] * (1 - t_diag) + top_color_hi[2] * t_diag + 255 * shine)
                elif in_front:
                    # Front face vertical gradient
                    t_y = (sy - 10.0) / 7.5
                    r = int(front_color_hi[0] * (1 - t_y) + front_color_lo[0] * t_y)
                    g = int(front_color_hi[1] * (1 - t_y) + front_color_lo[1] * t_y)
                    b = int(front_color_hi[2] * (1 - t_y) + front_color_lo[2] * t_y)
                    # Beveled top highlight line along front edge (between top & front)
                    if abs(sy - (10.5 - 0.1*(sx - 8.0))) <= 1.0:
                        r = int(r * 0.4 + highlight_edge[0] * 0.6)
                        g = int(g * 0.4 + highlight_edge[1] * 0.6)
                        b = int(b * 0.4 + highlight_edge[2] * 0.6)
                elif in_right or in_left:
                    # Dark side facets
                    t_y = (sy - 7.0) / 10.0
                    r = int(side_color[0] * (1 - 0.2*t_y))
                    g = int(side_color[1] * (1 - 0.2*t_y))
                    b = int(side_color[2] * (1 - 0.2*t_y))
                else:
                    r, g, b = dark_contour

                ar += min(255, max(0, r))
                ag += min(255, max(0, g))
                ab += min(255, max(0, b))
                aa += 255
                
            idx = (y * size + x) * 4
            buf[idx] = min(255, ar // 4)
            buf[idx+1] = min(255, ag // 4)
            buf[idx+2] = min(255, ab // 4)
            buf[idx+3] = min(255, aa // 4)
            
    return bytes(buf)

write_png("assets/mat_cork.png", 24, 24, create_bottle_cork(24))
write_png("assets/mat_iron.png", 24, 24, create_ingot(24, "iron"))
write_png("assets/mat_lead.png", 24, 24, create_ingot(24, "lead"))
print("Generated bottle cork and metallic ingots!")
