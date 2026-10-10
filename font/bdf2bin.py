import sys, re

def parse_bdf(path):
    glyphs = {}
    current = None
    with open(path, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('ENCODING'):
                current = int(line.split()[1])
            elif line.startswith('BITMAP') and current is not None:
                bits = []
                for _ in range(8):          # 5x8 font has 8 rows
                    row_hex = f.readline().strip()
                    bits.append(int(row_hex, 16))
                glyphs[current] = bits
                current = None
    return glyphs

def make_raw(glyphs):
    raw = bytearray(256 * 8)
    for code, rows in glyphs.items():
        if code < 256:
            offset = code * 8
            for i, val in enumerate(rows):
                # BDF rows are 5 bits; we need 8 bits, left-aligned
                raw[offset + i] = val & 0xFF
    return raw

if __name__ == '__main__':
    glyphs = parse_bdf(sys.argv[1])
    raw = make_raw(glyphs)
    with open(sys.argv[2], 'wb') as f:
        f.write(raw)
    print(f"Wrote {len(raw)} bytes to {sys.argv[2]}")
