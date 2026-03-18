import math
import serial
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

# ---------------- SETTINGS ----------------
PORT = "COM5"
BAUD = 115200
MAX_DISTANCE = 400     # cm
# ------------------------------------------

ser = serial.Serial(PORT, BAUD, timeout=0.05)

points = {}            # angle -> distance
current_angle = 90

fig, ax = plt.subplots(figsize=(8, 5))
ax.set_aspect("equal")
ax.set_xlim(-MAX_DISTANCE, MAX_DISTANCE)
ax.set_ylim(0, MAX_DISTANCE)
ax.set_xlabel("X (cm)")
ax.set_ylabel("Y (cm)")
ax.set_title("ESP32 Radar Visualization")

# Draw semicircle grid
for r in [100, 200, 300, 400]:
    xs = [r * math.cos(math.radians(a)) for a in range(0, 181, 2)]
    ys = [r * math.sin(math.radians(a)) for a in range(0, 181, 2)]
    ax.plot(xs, ys, linestyle="--", linewidth=0.8)

for a in range(0, 181, 30):
    x = MAX_DISTANCE * math.cos(math.radians(a))
    y = MAX_DISTANCE * math.sin(math.radians(a))
    ax.plot([0, x], [0, y], linewidth=0.8)

points_plot, = ax.plot([], [], marker='o', linestyle='None')
scan_line, = ax.plot([], [], linewidth=2)
status_text = ax.text(0.02, 0.95, "", transform=ax.transAxes)

def update(frame):
    global current_angle

    # Read several serial lines each frame
    for _ in range(40):
        try:
            line = ser.readline().decode("utf-8", errors="ignore").strip()
        except Exception:
            continue

        if not line:
            continue

        if not line.startswith("DATA,"):
            continue

        parts = line.split(",")
        if len(parts) != 3:
            continue

        try:
            angle = int(parts[1])
            distance = float(parts[2])
        except ValueError:
            continue

        current_angle = angle

        if distance >= 0:
            points[angle] = distance
        else:
            if angle in points:
                del points[angle]

    # Convert polar data to x,y
    xs = []
    ys = []
    for angle, distance in sorted(points.items()):
        # If the display looks mirrored, change angle to (180 - angle)
        display_angle = angle
        x = distance * math.cos(math.radians(display_angle))
        y = distance * math.sin(math.radians(display_angle))
        xs.append(x)
        ys.append(y)

    points_plot.set_data(xs, ys)

    # Current sweep line
    line_x = [0, MAX_DISTANCE * math.cos(math.radians(current_angle))]
    line_y = [0, MAX_DISTANCE * math.sin(math.radians(current_angle))]
    scan_line.set_data(line_x, line_y)

    status_text.set_text(f"Current angle: {current_angle}°")

    return points_plot, scan_line, status_text

ani = FuncAnimation(fig, update, interval=40, blit=False)

try:
    plt.show()
finally:
    ser.close()