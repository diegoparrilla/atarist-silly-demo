import math

FRAMES_PER_SECOND = 50  # 50 Hertzs
# START_POSITION = (192 - 60 - 24) / 2
START_POSITION = (200 - 30) / 2
AMPLITUDE = START_POSITION
# Generate a sine wave table for scroll text
# entries = 64

# Write in an array of strings to save later to the file
lines_y = []
lines_y.append("scroll_y_pos:\n")

# Let's start at the top of the screen witout moving the scroll
start_position_y = 0
frames = FRAMES_PER_SECOND * 5  # 5 seconds
for i in range(frames):
    lines_y.append("                dc.w %i\n" % start_position_y)

# Let's use a wave to move from the top to the middle of the screen
start_position = START_POSITION  # The X axis position 0 is at start_position
amplitude = AMPLITUDE  # The amplitude of the sine wave
entries = 256
for i in range(entries):
    if i >= 192:
        x = i * 360 / (entries - 1)
        y = (math.sin(math.radians(x)) * amplitude) + start_position
        lines_y.append(f"                dc.w {int(y)}\n")

for entries in [256, 192, 128, 96, 128, 192, 256]:
    for j in range(int(1024 / entries)):
        start_position = START_POSITION  # The X axis position 0 is at start_position
        amplitude = AMPLITUDE  # The amplitude of the sine wave
        for i in range(entries):
            x = i * 360 / (entries - 1)
            y = (math.sin(math.radians(x)) * amplitude) + start_position
            lines_y.append(f"                dc.w {int(y)}\n")

# Let's use a wave to return to the top of the screen
start_position = START_POSITION  # The X axis position 0 is at start_position
amplitude = AMPLITUDE  # The amplitude of the sine wave
entries = 256
for i in range(entries):
    if i < 192:
        x = i * 360 / (entries - 1)
        y = (math.sin(math.radians(x)) * amplitude) + start_position
        lines_y.append(f"                dc.w {int(y)}\n")

# Write the array to the file out to the folder src/scroller.inc
with open("src/scroller.inc", "w") as f:
    f.writelines(lines_y)
    f.write("\n")
    f.write(f"scroll_table_size                dc.w  {(len(lines_y)-1) * 2}\n")
