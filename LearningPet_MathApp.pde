/*

 Learning Pet Math
 ------------------------
 RobotGrrl.com/LearningPet
 
 Licensed under BSD-3 license
 
 Loop: 
 http://www.freesound.org/people/pryght%20one/sounds/27130/
 Lasers:
 http://www.freesound.org/people/HardPCM/sounds/32954/
 http://www.freesound.org/people/junggle/sounds/28917/
 http://www.freesound.org/people/THE_bizniss/sounds/39459/
 
 */

import processing.serial.*;
import ddf.minim.*;

Minim minim;
AudioSnippet laser1, laser2, laser3, loopSound;

Serial myPort;
boolean arduino = true;

int[] numbers = new int[4];
boolean[] done = new boolean[4];
int level = 0;

int s;
float brrdX = 0;

PFont font;

int tries = 0;
int answers = 0;

final int l = 14;
char[] in = new char[l];

int ultraVal;
int switchVal;

int ultraLow = 9;
int ultraHigh = 620;

int firedTime = 0;
int numSendTimes = 40;

PFont statsFont;

int question = 0;
int incorrect = 0;

PImage space, brrd, spaceship;

boolean backgroundMusic = false;

boolean doneGame = false;

final int irSample = 5;

int irBuff[] = new int[irSample];
int irCount = 0;
float irAvg_t0 = 0.0;

void setup() {

  size(960, 640);
  //size(screen.width, screen.height);

  minim = new Minim(this);

  laser1 = minim.loadSnippet("laser1.wav");
  laser2 = minim.loadSnippet("laser2.wav");
  laser3 = minim.loadSnippet("laser3.wav");
  loopSound = minim.loadSnippet("loop.wav");

  if (backgroundMusic) loopSound.loop(10000);

  noStroke();

  space = loadImage("space.jpg");
  brrd = loadImage("brrd.png");
  spaceship = loadImage("spaceship.png");

  font = loadFont("ArnoPro-Bold-48.vlw");
  
  statsFont = loadFont("PTSans-NarrowBold-34.vlw");

  s = width/9;

  background(0);
  smooth();

  println(Serial.list());

  int xbee = 99; // crazy value so we know that if it is not set, then it is not connected

  for (int i=0; i<Serial.list().length; i++) {
    if (Serial.list()[0].equals("/dev/tty.usbserial-A40082TP")) { // hardcode in here your xbee or arduino, so that way it is easier to connect in the future
      xbee = i;
      println("Choosing #" + xbee);
      break;
    }
  }

  if (xbee != 99) {
    myPort = new Serial(this, Serial.list()[xbee], 115200);
    println("Connected!");
  } 
  else {
    println("Xbee not connected!");
  }

  chooseNumbers();

  colorMode(RGB, 100);

  println(s);
}

void draw() {

  //background(space);

  //tint(0, 0, 0, 1); 
  //image(space, 0, 0, width, height);

  fill(255, 255, 255);
  for (int i=0; i<2; i++) {
    rect(random(0, width), random(0, height), 2, 2);
    rect(random(0, width), random(0, height), 1, 1);
  }

  fill(0, 0, 0, 30);
  rect(0, 0, width, height);

  if (!doneGame) {

    if (arduino) checkSerial();

    fill(255, 255, 255, 10);
    if (!done[0]) {
      //rect(s, 100, s, s);
      image(spaceship, s-50, 40, 2*s, 2*s);
    }
    if (!done[1]) {
      //rect(s*3, 100, s, s);
      image(spaceship, (s*3)-50, 40, 2*s, 2*s);
    }
    if (!done[2]) {
      //rect(s*5, 100, s, s);
      image(spaceship, (s*5)-50, 40, 2*s, 2*s);
    }
    if (!done[3]) {
      //rect(s*7, 100, s, s);
      image(spaceship, (s*7)-50, 40, 2*s, 2*s);
    }

    //rect(brrdX, height-300, 200, 200);
    image(brrd, brrdX-80, height-300, 364, 200);

    fill(128, 128, 128);
    textFont(font, 48);
    if (!done[0]) text(numbers[0], s+(s/3), 100+(s/2));
    if (!done[1]) text(numbers[1], s*3+(s/3), 100+(s/2));
    if (!done[2]) text(numbers[2], s*5+(s/3), 100+(s/2));
    if (!done[3]) text(numbers[3], s*7+(s/3), 100+(s/2));
  } 
  else {

    fill(255, 255, 255);
    textFont(statsFont, 50);
    text("Math in Space Quest", (width/2)-200, (height/2));
    text("COMPLETE! :)", (width/2)-150, (height/2)+60);
  }

  fill(255, 255, 255);
  textFont(statsFont, 34);
  text("Quest: Math in Space!", 20, height-20);

  text("Points", width-450, height-50);
  text(answers, width-425, height-20);

  text("Health", width-350, height-50);
  text(100-incorrect, width-325, height-20);

  text("Question", width-250, height-50);
  text(question+1, width-200, height-20);

  text("Level", width-100, height-50);
  text(level+1, width-75, height-20);
}

void checkSerial() {

  if (myPort.available() > 0) {
    // put all 15 of the chars in an array first (if there are 15)
    for (int j=0; j<l; j++) {
      if (myPort.available() > 0) in[j] = myPort.readChar();
      //println("["+j+"]: " + in[j]);
    }

    // now we go through all
    for (int j=0; j<l; j++) {

      // look for the first delimiter
      if (in[j] == '~') {

        // have to make sure that this is long enough to be a complete message, and that there is a complete message in the serial
        if (l-j > 6 && myPort.available() > 6) {

          char sensor = in[j+1];

          // here is where we do things for whichever specific sensor it is
          switch(sensor) {
          case 'U': 
            {
              ultraVal = (((int)in[j+2]-48)*1000) + (((int)in[j+3]-48)*100) + (((int)in[j+4]-48)*10) + ((int)in[j+5]-48); // changing a char to an int
              irBuff[irCount] = ultraVal;
              irCount++;
              //brrdX = (int)map(ultraVal, ultraLow, ultraHigh, -100, (width-100));
              //println("Ultrasonic: " + ultraVal);
              break;
            }
          case 'S': 
            {
              switchVal = (((int)in[j+2]-48)*1000) + (((int)in[j+3]-48)*100) + (((int)in[j+4]-48)*10) + ((int)in[j+5]-48);
              if (switchVal < 900 && (millis() > (firedTime+200))) {
                fired();
                firedTime = millis();
              }
              //println("Switch: " + switchVal);
              break;
            }
          }
        }
      }
      in[j] = '-'; // reset the in buffer as we go
    }

    myPort.clear();
  }

  if (irCount == irSample) {
    irCount = 0;
    float total = 0.0;
    for (int i=0; i<irSample; i++) {
      total += irBuff[i];
    }
    total /= irSample;
    //println("total: "+total);
    brrdX = map(total, ultraLow, ultraHigh, -100, (width-100));
    irAvg_t0 = total;
  }
}

void mouseMoved() {
  brrdX = mouseX-100;
}

void mousePressed() {

  fired();
}

void keyPressed() {

  switch(key) {
  case 'n':
    chooseNumbers();
    break;
  case 'd':
    if (arduino) {
      for (int i=0; i<numSendTimes; i++) {
        myPort.write("~DD!");
      }
    }
    break;
  }
}

void fired() {

  int sound = (int)random(0, 3);

  switch(sound) {
  case 0:
    println("l1");
    laser1.loop(0);
    break;
  case 1:
    println("l2");
    laser2.loop(0);//play();
    break;
  case 2:
    println("l3");
    laser3.loop(0);//play();
    break;
  }

  int adjustedX = (int)brrdX+100;
  int block = 0;

  for (int i=1; i<9; i++) {

    if (adjustedX > (s*i) && adjustedX < (s*(i+1))) {
      block = (i-1)/2;
    }
  }

  println(block + "pew!");

  checkAnswer(block);
}

void checkAnswer(int block) {

  if (done[block]) return;

  int val = numbers[block];
  boolean correct = true;

  for (int i=0; i<4; i++) {
    if (val > numbers[i] && done[i] == false) {
      correct = false;
    }
  }

  tries++;
  println("tries: "+tries);

  if (correct) {
    done[block] = true;
    answers++;


    if (answers%4 == 0 && answers != 0) {

      question++;
      println("question: "+question);

      if (question%3 == 0 && question != 0) {
        level++;
        println("level: "+level);
        if (arduino) {
          for (int i=0; i<numSendTimes; i++) {
            myPort.write("~L"+level+"!");
          }
        }
      }

      chooseNumbers();
    }

    println("answers: "+answers);
  } 
  else {
    incorrect++;
    println("incorrect: "+incorrect);
  }

  if (correct) {
    if (arduino) {
      for (int i=0; i<numSendTimes; i++) {
        myPort.write("~A1!");
      }
    }
  } 
  else {
    if (arduino) {
      for (int i=0; i<numSendTimes; i++) {
        myPort.write("~A0!");
      }
    }
  }
}

void chooseNumbers() {

  int lowerBound = 1;
  int upperBound = 10;

  switch(level) {
  case 1:
    lowerBound = 10;
    upperBound = 30;
    break;
  case 2:
    lowerBound = 30;
    upperBound = 60;
    break;
  case 3:
    lowerBound = 60;
    upperBound = 100;
    break;
  case 4:
    lowerBound = 100;
    upperBound = 1000;
    break;
  case 5:
    doneGame = true;
    break;
  default:
    break;
  }

  for (int i=0; i<4; i++) {

    int n = (int)random(lowerBound, upperBound);
    boolean regen = false;

    if (i > 0) {

      for (int j=(i-1); j>=0; j--) {
        if (n == numbers[j]) {
          regen = true;
        }
      }

      while (regen) {
        regen = false;
        n = (int)random(lowerBound, upperBound);
        for (int j=(i-1); j>=0; j--) {
          if (n == numbers[j]) {
            regen = true;
          }
        }
      }
    }

    done[i] = false;
    numbers[i] = n;
    //println("["+i+"]"+" "+n);
  }
}

void stop() {
  myPort.stop();

  laser1.close();
  laser2.close();
  laser3.close();
  minim.stop();

  super.stop();
}

