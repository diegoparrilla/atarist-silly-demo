import math

FRAMES_PER_SECOND = 50  # 50 Hertzs

# Generate a sine wave table for scroll text
# entries = 64

# Write in an array of strings to save later to the file
lines = []
lines.append("sprite_skew:\n")

# Let's start simply waiting for a few seconds
start_position = 0
frames = FRAMES_PER_SECOND * 5  # 5 seconds
for i in range(frames):
    lines.append("                dc.w %i\n" % start_position)

for entries in [96, 64, 48, 32, 48, 64, 96]:
    for j in range(int(1024 / entries)):
        start_position = 0  # The X axis position 0 is at start_position
        amplitude = 16  # The amplitude of the sine wave
        for i in range(entries):
            x = i * 360 / (entries - 1)
            y = (math.sin(math.radians(x)) * amplitude) + start_position
            lines.append(f"                dc.w {int(y)}\n")

# Let's finish simply waiting for a few seconds
start_position = 0
frames = FRAMES_PER_SECOND * 5  # 5 seconds
for i in range(frames):
    lines.append("                dc.w %i\n" % start_position)

# Write the array to the file out to the folder src/scroller.inc
# The frames variables is a buffer to make sure the sprite is not
# cut off at the end of the animation
with open("src/sprite_l.inc", "w") as f:
    f.writelines(lines)
    f.write("\n")
    f.write(f"sprite_table_size                dc.w  {(len(lines)-1 - frames) * 2}\n")
