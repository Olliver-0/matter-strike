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

def create_button(width=140, height=64, state="normal"):
    buf = bytearray(width * height * 4)
    
    if state == "hover":
        bright = 1.15
        green_shift = 6
    elif state == "pressed":
        bright = 0.88
        green_shift = -4
    else:
        bright = 1.0
        green_shift = 0

    bronze_hi = (int(116 * bright), int(92 * bright), int(68 * bright))
    bronze_mid = (int(84 * bright), int(66 * bright), int(48 * bright))
    bronze_base = (int(66 * bright), int(51 * bright), int(36 * bright))
    bronze_dark = (int(44 * bright), int(33 * bright), int(23 * bright))
    bronze_deep = (int(28 * bright), int(20 * bright), int(14 * bright))
    
    green_top = (int((96 + green_shift) * bright), int((116 + green_shift) * bright), int((76 + green_shift) * bright))
    green_mid = (int((74 + green_shift) * bright), int((90 + green_shift) * bright), int((58 + green_shift) * bright))
    green_bot = (int((56 + green_shift) * bright), int((68 + green_shift) * bright), int((44 + green_shift) * bright))
    
    green_bevel_hi = (int(155 * bright), int(180 * bright), int(122 * bright))
    green_bevel_sub = (int(115 * bright), int(136 * bright), int(90 * bright))
    green_bevel_lo = (int(32 * bright), int(40 * bright), int(24 * bright))
    
    if state == "pressed":
        green_bevel_hi, green_bevel_lo = green_bevel_lo, green_bevel_hi

    pad_x = 6.0
    pad_y = 5.0
    frame_w = width - 2 * pad_x
    frame_h = height - 2 * pad_y
    
    num_scallops_x = 7
    num_scallops_y = 3
    spacing_x = frame_w / num_scallops_x
    spacing_y = frame_h / num_scallops_y
    notch_radius = 3.6

    for y in range(height):
        for x in range(width):
            sub_samples = [
                (x + 0.25, y + 0.25),
                (x + 0.75, y + 0.25),
                (x + 0.25, y + 0.75),
                (x + 0.75, y + 0.75)
            ]
            accum_r, accum_g, accum_b, accum_a = 0, 0, 0, 0
            
            for sx, sy in sub_samples:
                corner_r = 5.0
                rx0 = pad_x
                ry0 = pad_y
                rx1 = width - pad_x
                ry1 = height - pad_y
                
                in_base = (rx0 <= sx <= rx1 and ry0 <= sy <= ry1)
                if in_base:
                    if sx < rx0 + corner_r and sy < ry0 + corner_r:
                        if (sx - (rx0 + corner_r))**2 + (sy - (ry0 + corner_r))**2 > corner_r**2:
                            in_base = False
                    elif sx > rx1 - corner_r and sy < ry0 + corner_r:
                        if (sx - (rx1 - corner_r))**2 + (sy - (ry0 + corner_r))**2 > corner_r**2:
                            in_base = False
                    elif sx < rx0 + corner_r and sy > ry1 - corner_r:
                        if (sx - (rx0 + corner_r))**2 + (sy - (ry1 - corner_r))**2 > corner_r**2:
                            in_base = False
                    elif sx > rx1 - corner_r and sy > ry1 - corner_r:
                        if (sx - (rx1 - corner_r))**2 + (sy - (height - pad_y - corner_r))**2 > corner_r**2:
                            in_base = False
                
                in_notch = False
                if in_base and sy < ry0 + notch_radius + 0.8:
                    for i in range(num_scallops_x + 1):
                        nx = rx0 + i * spacing_x
                        if (sx - nx)**2 + (sy - ry0)**2 < notch_radius**2:
                            in_notch = True
                            break
                            
                if in_base and sy > ry1 - notch_radius - 0.8:
                    for i in range(num_scallops_x + 1):
                        nx = rx0 + i * spacing_x
                        if (sx - nx)**2 + (sy - ry1)**2 < notch_radius**2:
                            in_notch = True
                            break
                            
                if in_base and sx < rx0 + notch_radius + 0.8:
                    for i in range(num_scallops_y + 1):
                        ny = ry0 + i * spacing_y
                        if (sx - rx0)**2 + (sy - ny)**2 < notch_radius**2:
                            in_notch = True
                            break
                            
                if in_base and sx > rx1 - notch_radius - 0.8:
                    for i in range(num_scallops_y + 1):
                        ny = ry0 + i * spacing_y
                        if (sx - rx1)**2 + (sy - ny)**2 < notch_radius**2:
                            in_notch = True
                            break

                outer_shape = in_base and not in_notch
                if not outer_shape:
                    if in_base and in_notch:
                        accum_r += bronze_deep[0]
                        accum_g += bronze_deep[1]
                        accum_b += bronze_deep[2]
                        accum_a += 50
                    elif sy > ry1 and abs(sx - width/2) < width/2 - 4:
                        d_sh = sy - ry1
                        if d_sh < 3.5:
                            accum_r += 15
                            accum_g += 10
                            accum_b += 6
                            accum_a += int(90 * (1.0 - d_sh / 3.5))
                    continue
                
                gx0 = pad_x + 7.5
                gy0 = pad_y + 6.0
                gx1 = width - pad_x - 7.5
                gy1 = height - pad_y - 6.0
                gr = 5.5
                
                in_green = (gx0 <= sx <= gx1 and gy0 <= sy <= gy1)
                if in_green:
                    if sx < gx0 + gr and sy < gy0 + gr:
                        if (sx - (gx0 + gr))**2 + (sy - (gy0 + gr))**2 > gr**2:
                            in_green = False
                    elif sx > gx1 - gr and sy < gy0 + gr:
                        if (sx - (gx1 - gr))**2 + (sy - (gy0 + gr))**2 > gr**2:
                            in_green = False
                    elif sx < gx0 + gr and sy > gy1 - gr:
                        if (sx - (gx0 + gr))**2 + (sy - (gy1 - gr))**2 > gr**2:
                            in_green = False
                    elif sx > gx1 - gr and sy > gy1 - gr:
                        if (sx - (gx1 - gr))**2 + (sy - (gy1 - gr))**2 > gr**2:
                            in_green = False
                            
                if in_green:
                    d_left = sx - gx0
                    d_right = gx1 - sx
                    d_top = sy - gy0
                    d_bot = gy1 - sy
                    min_d = min(d_left, d_right, d_top, d_bot)
                    
                    if min_d <= 2.0:
                        if d_top <= 2.0 or d_left <= 2.0:
                            pix = green_bevel_hi
                        else:
                            pix = green_bevel_lo
                    elif min_d <= 3.2:
                        if d_top <= 3.2 or d_left <= 3.2:
                            pix = green_bevel_sub
                        else:
                            pix = green_bevel_lo
                    else:
                        v_t = (sy - gy0) / (gy1 - gy0)
                        cx_norm = (sx - width/2) / (frame_w/2)
                        cy_norm = (sy - height/2) / (frame_h/2)
                        radial = 1.0 - 0.20 * (cx_norm**2 + cy_norm**2)
                        
                        r = int((green_top[0] * (1.0 - v_t) + green_bot[0] * v_t) * radial)
                        g = int((green_top[1] * (1.0 - v_t) + green_bot[1] * v_t) * radial)
                        b = int((green_top[2] * (1.0 - v_t) + green_bot[2] * v_t) * radial)
                        pix = (r, g, b)
                        
                    accum_r += pix[0]
                    accum_g += pix[1]
                    accum_b += pix[2]
                    accum_a += 255
                else:
                    dx = max(gx0 - sx, 0, sx - gx1)
                    dy = max(gy0 - sy, 0, sy - gy1)
                    dist_to_green = math.sqrt(dx*dx + dy*dy) if (dx > 0 and dy > 0) else max(dx, dy)
                    
                    if dist_to_green <= 1.8:
                        pix = bronze_deep
                    elif dist_to_green <= 3.4:
                        if sy < height/2 or sx < width/2:
                            pix = bronze_hi
                        else:
                            pix = bronze_mid
                    else:
                        angle = math.atan2(sy - height/2, sx - width/2)
                        shade = 0.5 - 0.5 * (math.cos(angle - 2.4))
                        r = int(bronze_dark[0] * shade + bronze_hi[0] * (1.0 - shade))
                        g = int(bronze_dark[1] * shade + bronze_hi[1] * (1.0 - shade))
                        b = int(bronze_dark[2] * shade + bronze_hi[2] * (1.0 - shade))
                        pix = (r, g, b)
                        
                    accum_r += pix[0]
                    accum_g += pix[1]
                    accum_b += pix[2]
                    accum_a += 255
                    
            idx = (y * width + x) * 4
            buf[idx] = accum_r // 4
            buf[idx+1] = accum_g // 4
            buf[idx+2] = accum_b // 4
            buf[idx+3] = accum_a // 4
            
    return bytes(buf)

for state in ["normal", "hover", "pressed"]:
    img_data = create_button(width=140, height=64, state=state)
    write_png(f"assets/btn_fire_{state}.png", 140, 64, img_data)
    print(f"Generated assets/btn_fire_{state}.png (140x64)")
