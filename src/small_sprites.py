import math

FRAMES_PER_SECOND = 50  # 50 Hertzs

# Generate a sine and cosine waves table for front sprites
entries = 256
# Write in an array of strings to save later to the file
lines_x = []
lines_y = []
lines_x.append("sprite_x_pos:\n")
lines_y.append("sprite_y_pos:\n")

# Let's start at the center of the screen witout moving the sprite
start_position_x = 96
start_position_y = 88
frames = FRAMES_PER_SECOND * 10  # 10 seconds
for i in range(frames):
    lines_x.append("                dc.w %i\n" % start_position_x)
    lines_y.append("                dc.w %i\n" % start_position_y)

for j in range(2):
    # Sine wave for X axis
    start_position = 96  # The X axis position 0 is at start_position
    amplitude = 96  # The amplitude of the sine wave
    start_phase = 0  # The phase of the sin wave to start
    for i in range(entries):
        x = start_phase + (i * 360 / (entries - 1))
        y = (math.sin(math.radians(x)) * amplitude) + start_position
        lines_x.append("                dc.w %i\n" % int(y))

    # Sine wave for Y axis
    start_position = 88  # The Y axis position 0 is at start_position
    amplitude = 88  # The amplitude of the cosine wave
    start_phase = 180  # The phase of the cosine wave to start
    for i in range(entries):
        x = start_phase + (i * 720 / (entries - 1))
        y = (math.sin(math.radians(x)) * amplitude) + start_position
        lines_y.append("                dc.w %i\n" % int(y))

# Let's start at the center of the screen witout moving the sprite
start_position_x = 96
start_position_y = 88
frames = FRAMES_PER_SECOND * 5  # 5 seconds
for i in range(frames):
    lines_x.append("                dc.w %i\n" % start_position_x)
    lines_y.append("                dc.w %i\n" % start_position_y)

for j in range(2):
    # Sine wave for X axis
    start_position = 96  # The X axis position 0 is at start_position
    amplitude = 96  # The amplitude of the sine wave
    start_phase = 0  # The phase of the sin wave to start
    for i in range(entries):
        x = start_phase + (i * 720 / (entries - 1))
        y = (math.sin(math.radians(x)) * amplitude) + start_position
        lines_x.append("                dc.w %i\n" % int(y))

    # Cosine wave for Y axis
    start_position = 88  # The Y axis position 0 is at start_position
    amplitude = 88  # The amplitude of the cosine wave
    start_phase = 90  # The phase of the cosine wave to start
    for i in range(entries):
        x = start_phase + (i * 360 / (entries - 1))
        y = (math.cos(math.radians(x)) * amplitude) + start_position
        lines_y.append("                dc.w %i\n" % int(y))

# Let's finish at the center of the screen to hide change in the positions
start_position_x = 96
start_position_y = 88º
frames = FRAMES_PER_SECOND * 3  # 3 seconds
for i in range(frames):
    lines_x.append("                dc.w %i\n" % start_position_x)
    lines_y.append("                dc.w %i\n" % start_position_y)

# Write the array to the file out to the folder src/sprite_s.inc
offset = 7 * 8  # 7 sprites and a sliding window of 8 bytes
with open("src/sprite_s.inc", "w") as f:
    f.writelines(lines_x)
    f.write("\n")
    f.writelines(lines_y)
    f.write("\n")
    f.write(f"sprites_table_size                dc.w  {(len(lines_x)-1 -offset) * 2}\n")
