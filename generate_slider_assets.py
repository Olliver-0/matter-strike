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

# -------------------------------------------------------------
# 1. SLIDER PLATE (Background container for both sliders)
# -------------------------------------------------------------
def create_slider_plate(width=280, height=170):
    buf = bytearray(width * height * 4)
    
    bronze_hi = (150, 115, 82)
    bronze_mid = (110, 80, 55)
    bronze_base = (88, 62, 42)
    bronze_dark = (58, 40, 26)
    bronze_deep = (32, 22, 14)
    rivet_hi = (200, 165, 120)
    rivet_dark = (40, 28, 18)

    for y in range(height):
        for x in range(width):
            sub_samples = [
                (x + 0.25, y + 0.25), (x + 0.75, y + 0.25),
                (x + 0.25, y + 0.75), (x + 0.75, y + 0.75)
            ]
            ar, ag, ab, aa = 0, 0, 0, 0
            for sx, sy in sub_samples:
                # Plate border
                margin = 3.0
                r = 6.0
                in_plate = (margin <= sx <= width - margin and margin <= sy <= height - margin)
                if in_plate:
                    # check corners
                    if sx < margin + r and sy < margin + r:
                        if (sx - (margin + r))**2 + (sy - (margin + r))**2 > r**2:
                            in_plate = False
                    elif sx > width - margin - r and sy < margin + r:
                        if (sx - (width - margin - r))**2 + (sy - (margin + r))**2 > r**2:
                            in_plate = False
                    elif sx < margin + r and sy > height - margin - r:
                        if (sx - (margin + r))**2 + (sy - (height - margin - r))**2 > r**2:
                            in_plate = False
                    elif sx > width - margin - r and sy > height - margin - r:
                        if (sx - (width - margin - r))**2 + (sy - (height - margin - r))**2 > r**2:
                            in_plate = False
                            
                if not in_plate:
                    # Outer shadow
                    if sy > height - margin and margin < sx < width - margin:
                        d = sy - (height - margin)
                        if d < 3.0:
                            ar += 20; ag += 14; ab += 8; aa += int(80 * (1 - d/3.0))
                    continue
                    
                # Distance to edge
                d_edge = min(sx - margin, width - margin - sx, sy - margin, height - margin - sy)
                
                # Check for rivets in 4 corners
                rivet_radius = 3.5
                rivet_pos = [
                    (margin + 9, margin + 9),
                    (width - margin - 9, margin + 9),
                    (margin + 9, height - margin - 9),
                    (width - margin - 9, height - margin - 9),
                    (margin + 9, height / 2.0),
                    (width - margin - 9, height / 2.0),
                ]
                in_rivet = False
                for rx, ry in rivet_pos:
                    dr = math.sqrt((sx - rx)**2 + (sy - ry)**2)
                    if dr < rivet_radius:
                        in_rivet = True
                        # Rivet 3D shading
                        if dr < rivet_radius - 1.2:
                            if sy < ry or sx < rx:
                                pix = rivet_hi
                            else:
                                pix = bronze_mid
                        else:
                            pix = rivet_dark
                        break
                if in_rivet:
                    ar += pix[0]; ag += pix[1]; ab += pix[2]; aa += 255
                    continue
                
                # Outer bevel rim (2px)
                if d_edge <= 2.2:
                    if sy - margin <= 2.2 or sx - margin <= 2.2:
                        pix = bronze_hi
                    else:
                        pix = bronze_dark
                elif d_edge <= 3.8:
                    pix = bronze_deep
                else:
                    # Plate body with subtle horizontal seam dividing line
                    mid_y = height / 2.0
                    dist_to_mid = abs(sy - mid_y)
                    if dist_to_mid <= 1.2:
                        pix = bronze_deep  # Groove line
                    elif dist_to_mid <= 2.4 and sy > mid_y:
                        pix = bronze_hi  # Groove highlight underneath
                    else:
                        # Warm rustic copper gradient
                        t_y = (sy - margin) / (height - 2*margin)
                        t_x = (sx - margin) / (width - 2*margin)
                        # Vignette / edge darkening
                        vignette = 1.0 - 0.22 * (((t_x - 0.5)*2)**2 + ((t_y - 0.5)*2)**2)
                        
                        r = int((bronze_base[0] * (1 - 0.15*t_y) + 10) * vignette)
                        g = int((bronze_base[1] * (1 - 0.15*t_y) + 5) * vignette)
                        b = int((bronze_base[2] * (1 - 0.15*t_y)) * vignette)
                        pix = (r, g, b)
                        
                ar += pix[0]; ag += pix[1]; ab += pix[2]; aa += 255
                
            idx = (y * width + x) * 4
            buf[idx] = ar // 4
            buf[idx+1] = ag // 4
            buf[idx+2] = ab // 4
            buf[idx+3] = aa // 4
            
    return bytes(buf)

# -------------------------------------------------------------
# 2. SLIDER TRACK (Capsule groove with cogwheel ends)
# -------------------------------------------------------------
def create_slider_track(width=220, height=32):
    buf = bytearray(width * height * 4)
    
    bronze_hi = (130, 102, 72)
    bronze_mid = (90, 70, 48)
    bronze_dark = (55, 40, 28)
    bronze_deep = (28, 20, 14)
    slot_bg = (24, 18, 12)
    slot_shadow = (14, 10, 6)

    cy = height / 2.0
    slot_h = 13.0
    slot_r = slot_h / 2.0
    
    # Cogwheel centers at left and right
    gear_r = 11.5
    left_gear_cx = 16.0
    right_gear_cx = width - 16.0
    
    num_teeth = 10
    tooth_depth = 3.2

    for y in range(height):
        for x in range(width):
            sub_samples = [
                (x + 0.25, y + 0.25), (x + 0.75, y + 0.25),
                (x + 0.25, y + 0.75), (x + 0.75, y + 0.75)
            ]
            ar, ag, ab, aa = 0, 0, 0, 0
            for sx, sy in sub_samples:
                # 1. Cogwheels on ends
                in_left_gear = False
                in_right_gear = False
                
                # Left gear
                dl = math.sqrt((sx - left_gear_cx)**2 + (sy - cy)**2)
                angle_l = math.atan2(sy - cy, sx - left_gear_cx)
                tooth_mod_l = 0.5 + 0.5 * math.cos(num_teeth * angle_l)
                gear_boundary_l = gear_r - tooth_depth * (1.0 - tooth_mod_l)
                if dl <= gear_boundary_l:
                    in_left_gear = True
                    
                # Right gear
                dr = math.sqrt((sx - right_gear_cx)**2 + (sy - cy)**2)
                angle_r = math.atan2(sy - cy, sx - right_gear_cx)
                tooth_mod_r = 0.5 + 0.5 * math.cos(num_teeth * angle_r)
                gear_boundary_r = gear_r - tooth_depth * (1.0 - tooth_mod_r)
                if dr <= gear_boundary_r:
                    in_right_gear = True
                    
                # 2. Main horizontal slot frame (raised bronze border around groove)
                frame_pad = 2.5
                frame_h = slot_h + 2 * frame_pad
                frame_r = frame_h / 2.0
                
                in_frame = False
                # Capsule shape for frame from left_gear_cx to right_gear_cx
                if abs(sy - cy) <= frame_r:
                    if left_gear_cx <= sx <= right_gear_cx:
                        in_frame = True
                    elif sx < left_gear_cx and dl <= frame_r:
                        in_frame = True
                    elif sx > right_gear_cx and dr <= frame_r:
                        in_frame = True

                # 3. Inner recessed slot groove
                in_slot = False
                if abs(sy - cy) <= slot_r:
                    if left_gear_cx <= sx <= right_gear_cx:
                        in_slot = True
                    elif sx < left_gear_cx and dl <= slot_r:
                        in_slot = True
                    elif sx > right_gear_cx and dr <= slot_r:
                        in_slot = True

                is_outer = in_left_gear or in_right_gear or in_frame
                if not is_outer:
                    # subtle shadow below
                    if sy > cy + frame_r and abs(sx - width/2) < width/2 - 4:
                        ds = sy - (cy + frame_r)
                        if ds < 3.0:
                            ar += 20; ag += 14; ab += 8; aa += int(80 * (1 - ds/3.0))
                    continue

                if in_slot:
                    # Inside the slot groove
                    d_top = sy - (cy - slot_r)
                    if d_top <= 2.5:
                        pix = slot_shadow
                    else:
                        pix = slot_bg
                elif in_frame:
                    # Frame rim around groove
                    if sy < cy - slot_r or (sx < left_gear_cx and dl > slot_r and sy < cy):
                        pix = bronze_hi
                    elif sy > cy + slot_r:
                        pix = bronze_dark
                    else:
                        pix = bronze_mid
                else:
                    # Gears background / teeth
                    if sy < cy:
                        pix = bronze_mid
                    else:
                        pix = bronze_dark

                ar += pix[0]; ag += pix[1]; ab += pix[2]; aa += 255

            idx = (y * width + x) * 4
            buf[idx] = ar // 4
            buf[idx+1] = ag // 4
            buf[idx+2] = ab // 4
            buf[idx+3] = aa // 4

    return bytes(buf)

# -------------------------------------------------------------
# 3. SLIDER FILL BAR (Glowing amber/copper capsule)
# -------------------------------------------------------------
def create_slider_fill(width=100, height=14):
    buf = bytearray(width * height * 4)
    cy = height / 2.0
    r = height / 2.0
    
    amber_hi = (220, 160, 95)
    amber_mid = (185, 125, 65)
    amber_bot = (140, 85, 40)
    amber_bevel = (245, 195, 135)
    amber_shadow = (95, 55, 25)

    for y in range(height):
        for x in range(width):
            sub_samples = [
                (x + 0.25, y + 0.25), (x + 0.75, y + 0.25),
                (x + 0.25, y + 0.75), (x + 0.75, y + 0.75)
            ]
            ar, ag, ab, aa = 0, 0, 0, 0
            for sx, sy in sub_samples:
                # Capsule shape
                in_capsule = False
                if sx < r:
                    if (sx - r)**2 + (sy - cy)**2 <= r**2:
                        in_capsule = True
                elif sx > width - r:
                    if (sx - (width - r))**2 + (sy - cy)**2 <= r**2:
                        in_capsule = True
                else:
                    if abs(sy - cy) <= r:
                        in_capsule = True
                        
                if not in_capsule:
                    continue
                    
                # Gradient & bevel
                t = sy / height
                if sy <= 1.8:
                    pix = amber_bevel
                elif sy >= height - 2.0:
                    pix = amber_shadow
                else:
                    pix = (
                        int(amber_hi[0] * (1 - t) + amber_bot[0] * t),
                        int(amber_hi[1] * (1 - t) + amber_bot[1] * t),
                        int(amber_hi[2] * (1 - t) + amber_bot[2] * t),
                    )
                ar += pix[0]; ag += pix[1]; ab += pix[2]; aa += 255

            idx = (y * width + x) * 4
            buf[idx] = ar // 4
            buf[idx+1] = ag // 4
            buf[idx+2] = ab // 4
            buf[idx+3] = aa // 4

    return bytes(buf)

# -------------------------------------------------------------
# 4. SLIDER GRABBER (Brass vertical grip handle)
# -------------------------------------------------------------
def create_slider_grabber(width=16, height=28, highlighted=False):
    buf = bytearray(width * height * 4)
    bright = 1.2 if highlighted else 1.0
    
    brass_hi = (min(255, int(215 * bright)), min(255, int(180 * bright)), min(255, int(130 * bright)))
    brass_mid = (min(255, int(165 * bright)), min(255, int(130 * bright)), min(255, int(85 * bright)))
    brass_dark = (min(255, int(105 * bright)), min(255, int(78 * bright)), min(255, int(50 * bright)))
    groove_color = (min(255, int(50 * bright)), min(255, int(35 * bright)), min(255, int(20 * bright)))

    for y in range(height):
        for x in range(width):
            sub_samples = [
                (x + 0.25, y + 0.25), (x + 0.75, y + 0.25),
                (x + 0.25, y + 0.75), (x + 0.75, y + 0.75)
            ]
            ar, ag, ab, aa = 0, 0, 0, 0
            for sx, sy in sub_samples:
                # Rounded rect
                pad = 1.0
                r = 3.0
                in_handle = (pad <= sx <= width - pad and pad <= sy <= height - pad)
                if in_handle:
                    if sx < pad + r and sy < pad + r:
                        if (sx - (pad + r))**2 + (sy - (pad + r))**2 > r**2:
                            in_handle = False
                    elif sx > width - pad - r and sy < pad + r:
                        if (sx - (width - pad - r))**2 + (sy - (pad + r))**2 > r**2:
                            in_handle = False
                    elif sx < pad + r and sy > height - pad - r:
                        if (sx - (pad + r))**2 + (sy - (height - pad - r))**2 > r**2:
                            in_handle = False
                    elif sx > width - pad - r and sy > height - pad - r:
                        if (sx - (width - pad - r))**2 + (sy - (height - pad - r))**2 > r**2:
                            in_handle = False
                            
                if not in_handle:
                    continue
                    
                # Bevel
                d_edge = min(sx - pad, width - pad - sx, sy - pad, height - pad - sy)
                if d_edge <= 1.6:
                    if sy <= pad + 1.6 or sx <= pad + 1.6:
                        pix = brass_hi
                    else:
                        pix = brass_dark
                else:
                    # Vertical ridges in center
                    mid_x = width / 2.0
                    # 2 vertical grooves at x = mid_x - 2.5 and x = mid_x + 2.5
                    if abs(sx - (mid_x - 2.5)) <= 0.8 or abs(sx - (mid_x + 2.5)) <= 0.8:
                        if 4.0 <= sy <= height - 4.0:
                            pix = groove_color
                        else:
                            pix = brass_mid
                    else:
                        # Smooth cylinder gradient
                        t_x = (sx - pad) / (width - 2*pad)
                        cyl = math.sin(t_x * math.pi)
                        pix = (
                            int(brass_mid[0] * 0.7 + brass_hi[0] * 0.3 * cyl),
                            int(brass_mid[1] * 0.7 + brass_hi[1] * 0.3 * cyl),
                            int(brass_mid[2] * 0.7 + brass_hi[2] * 0.3 * cyl)
                        )
                ar += pix[0]; ag += pix[1]; ab += pix[2]; aa += 255

            idx = (y * width + x) * 4
            buf[idx] = min(255, ar // 4)
            buf[idx+1] = min(255, ag // 4)
            buf[idx+2] = min(255, ab // 4)
            buf[idx+3] = min(255, aa // 4)

    return bytes(buf)

# Generate all
plate_data = create_slider_plate(width=280, height=170)
write_png("assets/slider_plate.png", 280, 170, plate_data)
print("Generated assets/slider_plate.png")

track_data = create_slider_track(width=220, height=32)
write_png("assets/slider_track.png", 220, 32, track_data)
print("Generated assets/slider_track.png")

fill_data = create_slider_fill(width=100, height=14)
write_png("assets/slider_fill.png", 100, 14, fill_data)
print("Generated assets/slider_fill.png")

grab_data = create_slider_grabber(width=16, height=28, highlighted=False)
write_png("assets/slider_grabber.png", 16, 28, grab_data)
print("Generated assets/slider_grabber.png")

grab_hi_data = create_slider_grabber(width=16, height=28, highlighted=True)
write_png("assets/slider_grabber_highlight.png", 16, 28, grab_hi_data)
print("Generated assets/slider_grabber_highlight.png")
