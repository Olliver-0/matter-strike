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
# Clean 24x24 Icons
# -------------------------------------------------------------
def create_cork_icon(size=24):
    buf = bytearray(size * size * 4)
    for y in range(size):
        for x in range(size):
            # Isometric cork wood block
            in_top = (5 <= y <= 10 and 6 + (y-5)*0.5 <= x <= 18 - (10-y)*0.5)
            in_front = (11 <= y <= 18 and 5 <= x <= 14)
            in_side = (10 <= y <= 18 and 14 < x <= 19 - (y-10)*0.3)
            
            if in_top:
                idx = (y * size + x) * 4
                buf[idx] = 195; buf[idx+1] = 155; buf[idx+2] = 110; buf[idx+3] = 255
            elif in_front:
                t = (y - 11) / 7.0
                idx = (y * size + x) * 4
                buf[idx] = int(160 * (1 - 0.2*t)); buf[idx+1] = int(120 * (1 - 0.2*t)); buf[idx+2] = int(80 * (1 - 0.2*t)); buf[idx+3] = 255
            elif in_side:
                t = (y - 10) / 8.0
                idx = (y * size + x) * 4
                buf[idx] = int(125 * (1 - 0.2*t)); buf[idx+1] = int(90 * (1 - 0.2*t)); buf[idx+2] = int(58 * (1 - 0.2*t)); buf[idx+3] = 255
    return bytes(buf)

def create_stone_icon(size=24):
    buf = bytearray(size * size * 4)
    for y in range(size):
        for x in range(size):
            cx = (x - 12.0)
            cy = (y - 12.0)
            # Oval rock boulder
            d = (cx/7.5)**2 + (cy/6.5)**2
            if d <= 1.0:
                # 3D spherical lighting
                lx = -0.4; ly = -0.5; lz = 0.77
                nx = cx / 7.5; ny = cy / 6.5; nz = math.sqrt(max(0.0, 1.0 - d))
                diff = max(0.0, nx*lx + ny*ly + nz*lz)
                v = int(60 + 130 * diff)
                idx = (y * size + x) * 4
                buf[idx] = v; buf[idx+1] = int(v * 0.96); buf[idx+2] = int(v * 0.92); buf[idx+3] = 255
    return bytes(buf)

def create_iron_icon(size=24):
    buf = bytearray(size * size * 4)
    for y in range(size):
        for x in range(size):
            in_top = (6 <= y <= 11 and 5 + (y-6)*0.5 <= x <= 18 - (11-y)*0.4)
            in_front = (12 <= y <= 18 and 4 <= x <= 15)
            in_side = (10 <= y <= 17 and 15 < x <= 20 - (y-10)*0.3)
            
            if in_top:
                idx = (y * size + x) * 4
                buf[idx] = 210; buf[idx+1] = 215; buf[idx+2] = 220; buf[idx+3] = 255
            elif in_front:
                t = (y - 12) / 6.0
                v = int(160 * (1 - 0.3*t))
                idx = (y * size + x) * 4
                buf[idx] = v; buf[idx+1] = int(v * 1.02); buf[idx+2] = int(v * 1.05); buf[idx+3] = 255
            elif in_side:
                idx = (y * size + x) * 4
                buf[idx] = 95; buf[idx+1] = 100; buf[idx+2] = 108; buf[idx+3] = 255
    return bytes(buf)

def create_lead_icon(size=24):
    buf = bytearray(size * size * 4)
    for y in range(size):
        for x in range(size):
            in_top = (6 <= y <= 11 and 5 + (y-6)*0.5 <= x <= 18 - (11-y)*0.4)
            in_front = (12 <= y <= 18 and 4 <= x <= 15)
            in_side = (10 <= y <= 17 and 15 < x <= 20 - (y-10)*0.3)
            
            if in_top:
                idx = (y * size + x) * 4
                buf[idx] = 110; buf[idx+1] = 120; buf[idx+2] = 135; buf[idx+3] = 255
            elif in_front:
                t = (y - 12) / 6.0
                v = int(80 * (1 - 0.3*t))
                idx = (y * size + x) * 4
                buf[idx] = int(v * 0.9); buf[idx+1] = v; buf[idx+2] = int(v * 1.15); buf[idx+3] = 255
            elif in_side:
                idx = (y * size + x) * 4
                buf[idx] = 45; buf[idx+1] = 50; buf[idx+2] = 62; buf[idx+3] = 255
    return bytes(buf)

write_png("assets/mat_cork.png", 24, 24, create_cork_icon(24))
write_png("assets/mat_stone.png", 24, 24, create_stone_icon(24))
write_png("assets/mat_iron.png", 24, 24, create_iron_icon(24))
write_png("assets/mat_lead.png", 24, 24, create_lead_icon(24))
print("Icons regenerated cleanly!")
