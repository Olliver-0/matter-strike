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

# -----------------------------------------------------------------
# 1. MATERIALS PANEL PLATE (160 x 176) with 4 carved slots
# -----------------------------------------------------------------
def create_materials_plate(width=160, height=176):
    buf = bytearray(width * height * 4)
    
    bronze_hi = (155, 120, 85)
    bronze_mid = (112, 82, 56)
    bronze_base = (88, 62, 42)
    bronze_dark = (58, 40, 26)
    bronze_deep = (30, 20, 13)
    rivet_hi = (205, 170, 125)
    rivet_dark = (42, 28, 18)
    
    slot_bg = (48, 33, 23)
    slot_shadow = (24, 16, 10)
    slot_highlight = (78, 56, 38)

    slots_y = [34, 68, 102, 136]
    slot_h = 28
    slot_w = 126
    slot_x0 = 11
    slot_x1 = slot_x0 + slot_w
    slot_r = 4.5

    for y in range(height):
        for x in range(width):
            sub_samples = [
                (x + 0.25, y + 0.25), (x + 0.75, y + 0.25),
                (x + 0.25, y + 0.75), (x + 0.75, y + 0.75)
            ]
            ar, ag, ab, aa = 0, 0, 0, 0
            for sx, sy in sub_samples:
                margin = 3.0
                r = 6.0
                in_plate = (margin <= sx <= width - margin and margin <= sy <= height - margin)
                if in_plate:
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
                    if sy > height - margin and margin < sx < width - margin:
                        d = sy - (height - margin)
                        if d < 3.0:
                            ar += 20; ag += 14; ab += 8; aa += int(80 * (1 - d/3.0))
                    continue
                    
                d_edge = min(sx - margin, width - margin - sx, sy - margin, height - margin - sy)
                
                # Rivets in 4 corners
                rivet_radius = 3.0
                rivet_pos = [
                    (margin + 7.5, margin + 7.5),
                    (width - margin - 7.5, margin + 7.5),
                    (margin + 7.5, height - margin - 7.5),
                    (width - margin - 7.5, height - margin - 7.5),
                ]
                in_rivet = False
                for rx, ry in rivet_pos:
                    dr = math.sqrt((sx - rx)**2 + (sy - ry)**2)
                    if dr < rivet_radius:
                        in_rivet = True
                        pix = rivet_hi if (sy < ry or sx < rx) else rivet_dark
                        break
                if in_rivet:
                    ar += pix[0]; ag += pix[1]; ab += pix[2]; aa += 255
                    continue
                
                # Outer bevel
                if d_edge <= 2.2:
                    pix = bronze_hi if (sy - margin <= 2.2 or sx - margin <= 2.2) else bronze_dark
                elif d_edge <= 3.4:
                    pix = bronze_deep
                else:
                    # Check if inside one of the 4 carved item slots
                    in_slot = False
                    for sy0 in slots_y:
                        sy1 = sy0 + slot_h
                        if slot_x0 <= sx <= slot_x1 and sy0 <= sy <= sy1:
                            # rounded corners
                            in_rect = True
                            if sx < slot_x0 + slot_r and sy < sy0 + slot_r:
                                if (sx - (slot_x0 + slot_r))**2 + (sy - (sy0 + slot_r))**2 > slot_r**2:
                                    in_rect = False
                            elif sx > slot_x1 - slot_r and sy < sy0 + slot_r:
                                if (sx - (slot_x1 - slot_r))**2 + (sy - (sy0 + slot_r))**2 > slot_r**2:
                                    in_rect = False
                            elif sx < slot_x0 + slot_r and sy > sy1 - slot_r:
                                if (sx - (slot_x0 + slot_r))**2 + (sy - (sy1 - slot_r))**2 > slot_r**2:
                                    in_rect = False
                            elif sx > slot_x1 - slot_r and sy > sy1 - slot_r:
                                if (sx - (slot_x1 - slot_r))**2 + (sy - (sy1 - slot_r))**2 > slot_r**2:
                                    in_rect = False
                                    
                            if in_rect:
                                in_slot = True
                                # Slot bevel (shadow top-left, highlight bottom-right)
                                d_in = min(sx - slot_x0, slot_x1 - sx, sy - sy0, sy1 - sy)
                                if d_in <= 1.5:
                                    pix = slot_shadow if (sy - sy0 <= 1.5 or sx - slot_x0 <= 1.5) else slot_highlight
                                else:
                                    t_s = (sy - sy0) / slot_h
                                    pix = (
                                        int(slot_bg[0] * (1 - 0.2*t_s)),
                                        int(slot_bg[1] * (1 - 0.2*t_s)),
                                        int(slot_bg[2] * (1 - 0.2*t_s))
                                    )
                                break
                                
                    if not in_slot:
                        # Check decorative scrollbar groove on the right (x in [141, 149], y in [34, 164])
                        if 141 <= sx <= 149 and 34 <= sy <= 164:
                            d_sb = min(sx - 141, 149 - sx, sy - 34, 164 - sy)
                            if d_sb <= 1.2:
                                pix = bronze_deep
                            else:
                                # Scroll thumb in upper half
                                if 48 <= sy <= 82 and 142 <= sx <= 148:
                                    pix = bronze_hi if (sy <= 50 or sx <= 143) else bronze_mid
                                else:
                                    pix = slot_shadow
                        else:
                            # General plate texture
                            vignette = 1.0 - 0.16 * (((sx/width - 0.5)*2)**2 + ((sy/height - 0.5)*2)**2)
                            pix = (
                                int((bronze_base[0] + 6) * vignette),
                                int((bronze_base[1] + 4) * vignette),
                                int((bronze_base[2] + 2) * vignette)
                            )
                ar += pix[0]; ag += pix[1]; ab += pix[2]; aa += 255
                
            idx = (y * width + x) * 4
            buf[idx] = min(255, ar // 4)
            buf[idx+1] = min(255, ag // 4)
            buf[idx+2] = min(255, ab // 4)
            buf[idx+3] = min(255, aa // 4)
    return bytes(buf)

# -----------------------------------------------------------------
# 2. ITEM SLOT SELECTION OVERLAY (126 x 28)
# -----------------------------------------------------------------
def create_item_slot(width=126, height=28, state="selected"):
    buf = bytearray(width * height * 4)
    r = 4.5
    
    if state == "selected":
        bg_top = (118, 84, 52)
        bg_bot = (88, 60, 36)
        border_hi = (225, 185, 115)
        border_lo = (150, 105, 52)
    elif state == "hover":
        bg_top = (78, 56, 36)
        bg_bot = (58, 42, 26)
        border_hi = (140, 105, 68)
        border_lo = (55, 38, 24)
    else: # normal (transparent with subtle bevel)
        bg_top = (52, 37, 25)
        bg_bot = (38, 26, 17)
        border_hi = (85, 62, 42)
        border_lo = (30, 20, 13)
        
    for y in range(height):
        for x in range(width):
            sub_samples = [
                (x + 0.25, y + 0.25), (x + 0.75, y + 0.25),
                (x + 0.25, y + 0.75), (x + 0.75, y + 0.75)
            ]
            ar, ag, ab, aa = 0, 0, 0, 0
            for sx, sy in sub_samples:
                in_rect = (0 <= sx <= width and 0 <= sy <= height)
                if in_rect:
                    if sx < r and sy < r:
                        if (sx - r)**2 + (sy - r)**2 > r**2:
                            in_rect = False
                    elif sx > width - r and sy < r:
                        if (sx - (width - r))**2 + (sy - r)**2 > r**2:
                            in_rect = False
                    elif sx < r and sy > height - r:
                        if (sx - r)**2 + (sy - (height - r))**2 > r**2:
                            in_rect = False
                    elif sx > width - r and sy > height - r:
                        if (sx - (width - r))**2 + (sy - (height - r))**2 > r**2:
                            in_rect = False
                            
                if not in_rect:
                    continue
                    
                d_edge = min(sx, width - sx, sy, height - sy)
                if d_edge <= 1.5:
                    pix = border_hi if (sy <= 1.5 or sx <= 1.5) else border_lo
                else:
                    t = sy / height
                    pix = (
                        int(bg_top[0] * (1 - t) + bg_bot[0] * t),
                        int(bg_top[1] * (1 - t) + bg_bot[1] * t),
                        int(bg_top[2] * (1 - t) + bg_bot[2] * t),
                    )
                ar += pix[0]; ag += pix[1]; ab += pix[2]; aa += 255
                
            idx = (y * width + x) * 4
            buf[idx] = min(255, ar // 4)
            buf[idx+1] = min(255, ag // 4)
            buf[idx+2] = min(255, ab // 4)
            buf[idx+3] = min(255, aa // 4)
    return bytes(buf)

plate_data = create_materials_plate(160, 176)
write_png("assets/materials_plate.png", 160, 176, plate_data)
print("Updated assets/materials_plate.png")

for state in ["selected", "hover"]:
    slot_data = create_item_slot(126, 28, state=state)
    write_png(f"assets/mat_item_{state}.png", 126, 28, slot_data)
    print(f"Generated assets/mat_item_{state}.png")
