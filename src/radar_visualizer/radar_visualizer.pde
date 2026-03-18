import processing.serial.*;

Serial myPort;

float[] distances = new float[181];
int currentAngle = 90;

float maxDistanceCm = 400.0;
float displayMaxDistanceCm = 100.0;

int portIndex = 2;

// Sweep trail history
int trailLength = 18;
int[] sweepTrail = new int[trailLength];

PFont titleFont;
PFont infoFont;

void setup() {
  size(1200, 800, P2D);
  smooth(8);
  surface.setTitle("ESP32 Radar Visualizer");

  for (int i = 0; i < distances.length; i++) {
    distances[i] = -1;
  }

  for (int i = 0; i < sweepTrail.length; i++) {
    sweepTrail[i] = currentAngle;
  }

  println("Available serial ports:");
  printArray(Serial.list());

  myPort = new Serial(this, Serial.list()[portIndex], 115200);
  myPort.clear();
  myPort.bufferUntil('\n');

  titleFont = createFont("Arial Bold", 26);
  infoFont  = createFont("Arial", 18);
}

void draw() {
  drawBackgroundGlow();
  drawRadarGrid();
  drawSweepTrail();
  drawDetections();
  drawSweepLine();
  drawCenterHub();
  drawInfoPanel();
}

void serialEvent(Serial p) {
  String line = p.readStringUntil('\n');
  if (line == null) return;

  line = trim(line);
  if (line.length() == 0) return;
  if (!line.startsWith("DATA,")) return;

  String[] parts = split(line, ',');
  if (parts.length != 3) return;

  int angle = int(parts[1]);
  float distance = float(parts[2]);

  if (angle < 0 || angle > 180) return;

  if (angle != currentAngle) {
    pushTrail(angle);
  }
  currentAngle = angle;

  if (distance >= 0 && distance <= maxDistanceCm) {
    distances[angle] = distance;
  } else {
    distances[angle] = -1;
  }
}

void pushTrail(int angle) {
  for (int i = 0; i < sweepTrail.length - 1; i++) {
    sweepTrail[i] = sweepTrail[i + 1];
  }
  sweepTrail[sweepTrail.length - 1] = angle;
}

void drawBackgroundGlow() {
  background(3, 10, 6);

  float cx = width / 2.0;
  float cy = height - 55;
  float radarRadius = min(width * 0.42, height * 0.80);

  noStroke();

  fill(0, 90, 30, 22);
  ellipse(cx, cy, radarRadius * 2.25, radarRadius * 2.25);

  fill(0, 140, 40, 14);
  ellipse(cx, cy, radarRadius * 1.85, radarRadius * 1.85);

  fill(0, 220, 70, 8);
  ellipse(cx, cy, radarRadius * 1.45, radarRadius * 1.45);
}

void drawRadarGrid() {
  float cx = width / 2.0;
  float cy = height - 55;
  float radarRadius = min(width * 0.42, height * 0.80);

  noFill();

  // Outer glow arc
  stroke(0, 255, 120, 35);
  strokeWeight(8);
  arc(cx, cy, radarRadius * 2.02, radarRadius * 2.02, PI, TWO_PI);

  // Main outer arc
  stroke(0, 255, 120, 160);
  strokeWeight(2.5);
  arc(cx, cy, radarRadius * 2, radarRadius * 2, PI, TWO_PI);

  // Range arcs
  for (int i = 1; i <= 4; i++) {
    float r = radarRadius * i / 4.0;
    stroke(0, 200, 90, 70);
    strokeWeight(1.5);
    arc(cx, cy, 2 * r, 2 * r, PI, TWO_PI);
  }

  // Minor angle lines every 15 degrees
  for (int a = 15; a <= 165; a += 15) {
    float theta = radians(180 - a);
    float x = cx + radarRadius * cos(theta);
    float y = cy - radarRadius * sin(theta);

    if (a % 45 == 0 || a == 90) {
      stroke(0, 255, 120, 90);
      strokeWeight(1.6);
    } else {
      stroke(0, 180, 80, 45);
      strokeWeight(1);
    }

    line(cx, cy, x, y);
  }

  // Distance labels
  textFont(infoFont);
  fill(120, 255, 170);
  textAlign(LEFT, CENTER);
  for (int i = 1; i <= 4; i++) {
    float r = radarRadius * i / 4.0;
    float d = displayMaxDistanceCm * i / 4.0;
    text(int(d) + " cm", cx + 12, cy - r);
  }

  // Angle labels
  textAlign(CENTER, CENTER);
  int[] angleMarks = {15, 45, 90, 135, 165};
  for (int a : angleMarks) {
    float theta = radians(180 - a);
    float x = cx + (radarRadius + 28) * cos(theta);
    float y = cy - (radarRadius + 28) * sin(theta);
    text(a + "°", x, y);
  }
}

void drawSweepTrail() {
  float cx = width / 2.0;
  float cy = height - 55;
  float radarRadius = min(width * 0.42, height * 0.80);

  for (int i = 0; i < sweepTrail.length; i++) {
    float theta = radians(180 - sweepTrail[i]);
    float x = cx + radarRadius * cos(theta);
    float y = cy - radarRadius * sin(theta);

    float alpha = map(i, 0, sweepTrail.length - 1, 8, 90);
    float w = map(i, 0, sweepTrail.length - 1, 1.0, 4.0);

    stroke(0, 255, 120, alpha);
    strokeWeight(w);
    line(cx, cy, x, y);
  }
}

void drawDetections() {
  float cx = width / 2.0;
  float cy = height - 55;
  float radarRadius = min(width * 0.42, height * 0.80);

  noStroke();

  for (int angle = 15; angle <= 165; angle++) {
    if (distances[angle] >= 0) {
      float shownDistance = constrain(distances[angle], 0, displayMaxDistanceCm);
      float r = map(shownDistance, 0, displayMaxDistanceCm, 0, radarRadius);
      float theta = radians(180 - angle);

      float x = cx + r * cos(theta);
      float y = cy - r * sin(theta);

      float dotSize = map(shownDistance, 0, displayMaxDistanceCm, 14, 7);

      // soft glow
      fill(0, 255, 120, 35);
      ellipse(x, y, dotSize * 2.6, dotSize * 2.6);

      fill(0, 255, 120, 80);
      ellipse(x, y, dotSize * 1.6, dotSize * 1.6);

      // bright core
      fill(180, 255, 210, 230);
      ellipse(x, y, dotSize, dotSize);
    }
  }
}

void drawSweepLine() {
  float cx = width / 2.0;
  float cy = height - 55;
  float radarRadius = min(width * 0.42, height * 0.80);

  float theta = radians(180 - currentAngle);
  float x = cx + radarRadius * cos(theta);
  float y = cy - radarRadius * sin(theta);

  // glow layers
  stroke(0, 255, 120, 25);
  strokeWeight(10);
  line(cx, cy, x, y);

  stroke(0, 255, 120, 70);
  strokeWeight(6);
  line(cx, cy, x, y);

  stroke(180, 255, 210, 240);
  strokeWeight(2.5);
  line(cx, cy, x, y);

  // current target highlight
  if (currentAngle >= 0 && currentAngle <= 180 && distances[currentAngle] >= 0) {
    float shownDistance = constrain(distances[currentAngle], 0, displayMaxDistanceCm);
    float r = map(shownDistance, 0, displayMaxDistanceCm, 0, radarRadius);
    float px = cx + r * cos(theta);
    float py = cy - r * sin(theta);

    noStroke();
    fill(0, 255, 120, 35);
    ellipse(px, py, 36, 36);

    fill(0, 255, 120, 90);
    ellipse(px, py, 22, 22);

    fill(220, 255, 230);
    ellipse(px, py, 10, 10);
  }
}

void drawCenterHub() {
  float cx = width / 2.0;
  float cy = height - 55;

  noStroke();
  fill(0, 255, 120, 35);
  ellipse(cx, cy, 48, 48);

  fill(0, 255, 120, 100);
  ellipse(cx, cy, 22, 22);

  fill(220, 255, 230);
  ellipse(cx, cy, 8, 8);
}

void drawInfoPanel() {
  float panelX = 28;
  float panelY = 10;
  float panelW = 330;
  float panelH = 125;

  noStroke();
  fill(0, 25, 12, 190);
  rect(panelX, panelY, panelW, panelH, 18);

  stroke(0, 255, 120, 70);
  strokeWeight(1.5);
  noFill();
  rect(panelX, panelY, panelW, panelH, 18);

  fill(180, 255, 210);
  textFont(titleFont);
  textAlign(LEFT, TOP);
  text("ESP32 RADAR", panelX + 18, panelY + 14);

  textFont(infoFont);
  fill(120, 255, 170);

  String distText;
  if (distances[currentAngle] >= 0) {
    distText = nf(distances[currentAngle], 0, 2) + " cm";
  } else {
    distText = "Out of range";
  }

  text("Angle: " + currentAngle + "°", panelX + 18, panelY + 58);
  text("Distance: " + distText, panelX + 18, panelY + 84);
}