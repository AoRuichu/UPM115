#include <SPI.h>
#include <WiFiNINA.h>
#include <Servo.h>
int servoPin_1 = 9;
int servoPin_2 = 10;
int ledPin = 13;
int servo_led_1 = 8;
int servo_led_2 = 7;


Servo myServo_1;
Servo myServo_2;
bool servoActive_1 = false;
bool servoActive_2 = false;
int pos1 = 90;
int pos2 = 90;
bool goingForward = true;
char ssid[] = "Athens2016";
char pass[] = "Arduino2016";
unsigned long lastMoveTime_1 = 0;
unsigned long lastMoveTime_2 = 0;
const int moveInterval = 20;
WiFiServer server(80);

void setup() {
  Serial.begin(9600);
 
  myServo_1.attach(servoPin_1);
  myServo_2.attach(servoPin_2);
  myServo_1.write(90); 
  myServo_2.write(90);
  WiFi.begin(ssid, pass);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print("WIFI NOT CONNECTED.");
  }
  pinMode(ledPin, OUTPUT);
  pinMode(servo_led_1, OUTPUT);
  pinMode(servo_led_2, OUTPUT);
  digitalWrite(ledPin,HIGH);
  Serial.println("Connected to WiFi!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  server.begin(); // Start HTTP server
}

int direction1 = 0;   // 1=正转, -1=反转, 0=停止
int direction2 = 0;

void loop() {

  // ======= 舵机运动控制（非阻塞） =======
  if (servoActive_1 && millis() - lastMoveTime_1 > moveInterval) {
    lastMoveTime_1 = millis();
    pos1 += direction1;  
    pos1 = constrain(pos1, 0, 180);
    myServo_1.write(pos1);
  }

  if (servoActive_2 && millis() - lastMoveTime_2 > moveInterval) {
    lastMoveTime_2 = millis();
    pos2 += direction2;
    pos2 = constrain(pos2, 0, 180);
    myServo_2.write(pos2);
  }

  WiFiClient client = server.available();
  if (client) {
    String request = client.readStringUntil('\r');
    client.flush();

    if (request.indexOf("GO") != -1) {
      Serial.println("GO");
      servoActive_1 = true;
      servoActive_2 = true;
      direction1 = 1;     // 正转
      direction2 = -1;    // 反转
      pos1 = 90;
      pos2 = 90;
      myServo_1.write(pos1);
      myServo_2.write(pos2);
      digitalWrite(servo_led_1,HIGH);
      digitalWrite(servo_led_2,LOW);
    }
    else if (request.indexOf("STOP") != -1) {
      Serial.println("STOP");
      servoActive_1 = false;
      servoActive_2 = false;
      pos1 = 90;
      pos2 = 90;
      myServo_1.write(pos1);
      myServo_2.write(pos2);
      digitalWrite(servo_led_1,LOW);
      digitalWrite(servo_led_2,HIGH);
    }
    else if (request.indexOf("BACK") != -1){
      Serial.println("BACK");
      servoActive_1 = true;
      servoActive_2 = true;
      direction1 = -1;     // 正转
      direction2 = 1;    // 反转
      pos1 = 90;
      pos2 = 90;
      myServo_1.write(pos1);
      myServo_2.write(pos2);
      digitalWrite(servo_led_1,HIGH);
      digitalWrite(servo_led_2,LOW);
    }
    else if (request.indexOf("RIGHT") != -1) {
      Serial.println("LEFT");
      servoActive_1 = true;
      servoActive_2 = false;
      direction1 = 1; // 只让右边转
      direction2 = 0; // 只让右边转
      pos1 = 90;
      pos2 = 90;
      myServo_1.write(pos1);
      myServo_2.write(pos2);
      digitalWrite(servo_led_1,HIGH);
      digitalWrite(servo_led_2,HIGH);
    }
    else if (request.indexOf("LEFT") != -1) {
      Serial.println("RIGHT");
      servoActive_1 = false;
      servoActive_2 = true;
      direction1 = 0; // 只让左边转
      direction2 = -1; // 只让左边转
      pos1 = 90;
      pos2 = 90;
      myServo_1.write(pos1);
      myServo_2.write(pos2);
      digitalWrite(servo_led_1,LOW);
      digitalWrite(servo_led_2,LOW);
    }
  }
}