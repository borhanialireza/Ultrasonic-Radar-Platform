#include <Arduino.h>
#include <ESP32Servo.h>

const int SERVO_PIN = 18;   
const int TRIG_PIN  = 14;    
const int ECHO_PIN  = 25;   

const int MIN_ANGLE = 15;   // For mechanical end stops
const int MAX_ANGLE = 165;
const int STEP_ANGLE = 2;

const int SERVO_SETTLE_MS = 60;   // Wait after each move
const int GAP_BETWEEN_READS_MS = 30; // Time between readings at the same angle
const int SAMPLES_PER_ANGLE = 3; // because the sensor is noisy

const float MAX_VALID_DISTANCE_CM = 400.0;
const float MIN_VALID_DISTANCE_CM = 2.0;

const unsigned long ECHO_TIMEOUT_US = 30000; // if there is no object within range

Servo radarServo;

// put function declarations here:
float measureDistance() {
  // 3 microsecond low pulse to ensure clean HIGH pulse
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(3);

  // 10 us trigger pulse
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  unsigned long duration = pulseIn(ECHO_PIN, HIGH, ECHO_TIMEOUT_US);

  if (duration == 0) {
    return -1.0; // no echo
  }

  float distance = (duration * 0.0343f) / 2.0f; // The speed of sound devided by 2 (go and back)

  if (distance < MIN_VALID_DISTANCE_CM || distance > MAX_VALID_DISTANCE_CM) {
    return -1.0;
  }

  return distance;
}

float measureDistanceAverage() {
  float sum = 0.0;
  int count = 0;

  for (int i = 0; i < SAMPLES_PER_ANGLE; i++) {
    float d = measureDistance();
    if (d >= 0) {
      sum += d;
      count++;
    }
    delay(GAP_BETWEEN_READS_MS);
  }

  if (count == 0) {
    return -1.0;
  }

  return sum / count;
}

void printReading(int angle, float distance) {
  // if (distance < 0) {
  //   Serial.print("Angle: ");
  //   Serial.print(angle);
  //   Serial.println(" deg | Distance: Out of range");
  // } else {
  //   Serial.print("Angle: ");
  //   Serial.print(angle);
  //   Serial.print(" deg | Distance: ");
  //   Serial.print(distance, 2);
  //   Serial.println(" cm");
  // }
  Serial.print("DATA,");
  Serial.print(angle);
  Serial.print(",");
  Serial.println(distance, 2);   // -1.00 means out of range
}

void moveMeasure(int angle) {
  radarServo.write(angle);
  delay(SERVO_SETTLE_MS);

  float distance = measureDistanceAverage();
  printReading(angle, distance);
}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  radarServo.setPeriodHertz(50); // Standard for servo
  radarServo.attach(SERVO_PIN, 500, 2400); //Calibration range for servo

  radarServo.write(90);
  delay(1000);

  Serial.println("Radar scan starting...");
}

void loop() {
  // put your main code here, to run repeatedly:
  // Sweep left to right
  for (int angle = MIN_ANGLE; angle <= MAX_ANGLE; angle += STEP_ANGLE) {
    moveMeasure(angle);
  }

  // Sweep right to left
  for (int angle = MAX_ANGLE; angle >= MIN_ANGLE; angle -= STEP_ANGLE) {
    moveMeasure(angle);
  }
}