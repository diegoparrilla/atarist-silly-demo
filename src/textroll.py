import math

FRAMES_PER_SECOND = 50  # 50 Hertzs

# Generate a sine wave table for boing large sprite
# entries = 64

# Write in an array of strings to save later to the file
lines = []
lines.append("textroll_sinwave:\n")

# # Let's start at the top of the screen witout moving the scroll
# start_position_y = 4
# frames = FRAMES_PER_SECOND * 2  # 2 seconds
# for i in range(frames):
#     lines.append("                dc.w %i\n" % start_position_y)

entries = 24
for j in range(1):
    start_position = 0  # The X axis position 0 is at start_position
    amplitude = 3  # The amplitude of the sine wave
    for i in range(entries):
        x = i * 180 / (entries)
        y = (math.sin(math.radians(x)) * amplitude) + start_position
        lines.append(f"                dc.w {int(y)}\n")

# entries = 16
# for j in range(1):
#     start_position = 0  # The X axis position 0 is at start_position
#     amplitude = 4  # The amplitude of the sine wave
#     for i in range(entries):
#         x = i * 180 / (entries - 1)
#         y = abs((math.cos(math.radians(x)) * amplitude) + start_position)
#         lines.append(f"                dc.w {int(y)}\n")

# Write the array to the file out to the folder src/scroller.inc
with open("src/textroll.inc", "w") as f:
    f.writelines(lines)
    f.write("\n")
    f.write(f"textroll_table_size                dc.w  {(len(lines)-1) * 2}\n")
