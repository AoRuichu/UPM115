import processing.net.*;
import processing.serial.*;
import ddf.minim.*;
import http.requests.*;
import java.util.Base64;


Minim minim;
AudioInput mic;
AudioRecorder recorder;
int recordStartTime;
String GOOGLE_API_KEY = "AIzaSyDUaqhjdu82yn104_g91BmkPc_urqTIKQU";

Client client;
String ip = "192.168.0.105";

Button btnW, btnA, btnS, btnD，btnX;
String currentAction = "";  

void setup() {
  size(600, 400);
  client = new Client(this, ip, 80);
  minim = new Minim(this);
  mic = minim.getLineIn(Minim.MONO, 2048);
  btnW = new Button(260, 100, 80, 50, "W", "GO");
  btnA = new Button(180, 160, 80, 50, "A", "LEFT");
  btnS = new Button(260, 160, 80, 50, "S", "STOP");
  btnD = new Button(340, 160, 80, 50, "D", "RIGHT");
  btnX = new Button(260, 220, 80, 50, "X", "BACK");
}

void draw() {
  background(200);
  fill(0);
  textSize(20);
  text("Click or press WSAD to control", 160, 30);
  
  fill(0);
  textSize(24);
  text("Action: " + currentAction, 230, 350);

  // Draw buttons
  btnW.display();
  btnA.display();
  btnS.display();
  btnD.display();
  
  textSize(20);
  text("Press R to record, T to send to Google", 20, 50);
}

void mousePressed() {
  if (btnW.isClicked()) activateButton(btnW);
  if (btnA.isClicked()) activateButton(btnA);
  if (btnS.isClicked()) activateButton(btnS);
  if (btnD.isClicked()) activateButton(btnD);
}

void keyPressed() {
  if (key == 'r') {
    println("Recording...");
    recorder = minim.createRecorder(mic, "voice.wav");
    recordStartTime = millis();
    recorder.beginRecord();
  }
  if (key == 't') {
    if (millis() - recordStartTime < 1000) {
      println("Too short! Record at least 1 second.");
      return;
    }
    println("Saving and translate...");
    recorder.endRecord();
    recorder.save();
    delay(200);
    sendToGoogleSpeech(getBase64(sketchPath("voice.wav")));
  }
  if (key == 'w' || key == 'W') activateButton(btnW);
  if (key == 's' || key == 'S') activateButton(btnS);
  if (key == 'a' || key == 'A') activateButton(btnA);
  if (key == 'd' || key == 'D') activateButton(btnD);
  if (key == 'x' || key == 'X') activateButton(btnX);
}

void keyReleased() {
  deactivateAllButtons();  // 松开键时恢复按钮状态
}

void activateButton(Button btn) {
  deactivateAllButtons();           // 确保只有一个按钮高亮
  btn.isActive = true;              // 高亮按钮
  currentAction = btn.cmd;          // 更新屏幕显示动作
  sendCommand(btn.cmd);             // 发送控制指令
}

void deactivateAllButtons() {
  btnW.isActive = btnA.isActive = btnS.isActive = btnD.isActive = false;
}

void sendCommand(String cmd) {
  println("Send: " + cmd);
  client.write("GET /?cmd=" + cmd + " HTTP/1.1\r\n\r\n");
}


String getBase64(String filename) {
  try {
    byte[] fileContent = java.nio.file.Files.readAllBytes(new File(filename).toPath());
    return Base64.getEncoder().encodeToString(fileContent);
  } catch (Exception e) {
    e.printStackTrace();
    return "";
  }
}

void sendToGoogleSpeech(String base64Audio) {
  String url = "https://speech.googleapis.com/v1/speech:recognize?key=" + GOOGLE_API_KEY;
  
  String json = "{"
    + "\"config\": {"
    + "  \"encoding\": \"LINEAR16\","
    + "  \"sampleRateHertz\": 44100,"
    + "  \"languageCode\": \"en-US\","
    + "  \"maxAlternatives\": 1,"
    + "  \"model\": \"command_and_search\","
    + "  \"enableAutomaticPunctuation\": false"
    + "},"
    + "\"audio\": {"
    + "  \"content\": \"" + base64Audio + "\""
    + "}}";

  PostRequest post = new PostRequest(url);
  post.addHeader("Content-Type", "application/json");
  post.addData(json);
  post.send();
  String rawResponse = post.getContent();
  println("Google Response: " + rawResponse);
  String finalText = extractBestTranscript(rawResponse);
  println("Google Response: " + finalText);
  if (finalText.toLowerCase().contains("go straight")) {
    sendCommand("GO\n");
  }
  
  if (finalText.toLowerCase().contains("stop")) {
    sendCommand("STOP\n");
  }
  
  if (finalText.toLowerCase().contains("turn left")) {
     sendCommand("LEFT\n");
  }
  
  
  if (finalText.toLowerCase().contains("turn right")) {
     sendCommand("RIGHT\n");
  }
}



String extractBestTranscript(String json) {
  String bestTranscript = "";
  float bestConfidence = -1;

  String[] parts = json.split("\"alternatives\":");

  for (String part : parts) {
    int tStart = part.indexOf("\"transcript\": \"") + 15;
    int tEnd = part.indexOf("\"", tStart);
    int cStart = part.indexOf("\"confidence\": ") + 14;
    int cEnd = part.indexOf("\n", cStart);

    if (tStart > 15 && tEnd > tStart && cStart > 14) {
      String transcript = part.substring(tStart, tEnd).trim();
      float confidence = Float.parseFloat(part.substring(cStart, cEnd).trim());

      if (confidence > bestConfidence) {
        bestConfidence = confidence;
        bestTranscript = transcript;
      }
    }
  }

  return bestTranscript;
}

// === Button Class ===
class Button {
  float x, y, w, h;
  String label;
  String cmd;
  boolean isActive = false;

  Button(float x, float y, float w, float h, String label, String cmd) {
    this.x = x; 
    this.y = y; 
    this.w = w; 
    this.h = h; 
    this.label = label;
    this.cmd = cmd;
  }
  
  void display() {
    if (isActive) {
      fill(255, 200, 0);      // 激活状态：黄色
    } else if (isHover()) {
      fill(100, 200, 100);    // 悬停状态：绿色
    } else {
      fill(180);              // 常态：灰色
    }
    rect(x, y, w, h, 10);
    
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(18);
    text(label, x + w/2, y + h/2);
  }

  boolean isClicked() {
    return mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h;
  }
  
  boolean isHover() {
    return mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h;
  }
}
