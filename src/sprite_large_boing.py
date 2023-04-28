import math

FRAMES_PER_SECOND = 50  # 50 Hertzs

# Generate a sine wave table for boing large sprite
# entries = 64

# Write in an array of strings to save later to the file
lines = []
lines.append("sprite_boing:\n")

# Let's start simply waiting for a few seconds
start_position = 0
frames = FRAMES_PER_SECOND * 0  # 0 seconds
for i in range(frames):
    lines.append("                dc.w %i\n" % start_position)

# entries = 256
# for j in range(int(256 / entries)):
#     start_position = 0  # The X axis position 0 is at start_position
#     amplitude = 120  # The amplitude of the sine wave
#     for i in range(entries):
#         x = i * 180 / (entries - 1)
#         y = abs((math.cos(math.radians(x)) * amplitude) + start_position)
#         lines.append(f"                dc.w {int(y)}\n")

entries = 410
amplitude = 200 - 60  # The amplitude of the sine wave
start_position = amplitude  # The X axis position 0 is at start_position
for x in range(entries):
    y = start_position - abs(amplitude * math.cos(1 * math.radians(x))) * (
        math.e ** (-math.radians(x) / 4)
    )
    lines.append(f"                dc.w {int(y)}\n")

entries = 410
amplitude = 200 - 60  # The amplitude of the sine wave
start_position = amplitude  # The X axis position 0 is at start_position
for x in range(entries, 1, -1):
    y = start_position - abs(amplitude * math.cos(1 * math.radians(x))) * (
        math.e ** (-math.radians(x) / 4)
    )
    lines.append(f"                dc.w {int(y)}\n")

start_position = 0
frames = int(FRAMES_PER_SECOND * 0.1)  # 0.1 seconds
for i in range(frames):
    lines.append("                dc.w %i\n" % start_position)

# Write the array to the file out to the folder src/scroller.inc
with open("src/sprite_b.inc", "w") as f:
    f.writelines(lines)
    f.write("\n")
    f.write(f"sprite_boing_table_size                dc.w  {(len(lines)-1) * 2}\n")
