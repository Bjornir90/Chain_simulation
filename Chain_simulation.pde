ArrayList<Point> points;
ArrayList<Wire> wires;
ArrayList<Wire> wiresToRemove;
boolean simulationStarted;
Point selected;
int CIRCLE_RADIUS = 15, MAX_STEP = 5;

void setup() {
  size(1920, 1080);
  points = new ArrayList<Point>();
  wires = new ArrayList<Wire>();
  wiresToRemove = new ArrayList<Wire>();
  simulationStarted = false;
}


void draw() {
  background(50);
  for (int i = 0; i < points.size(); i++) {
    if (simulationStarted) {
      points.get(i).update();
    }
    points.get(i).render();
  }
  
  //Run the wires update a few times per frame to allow the system to settle to a stable state, to take into account chained wires
  for (int step = 0; step<MAX_STEP; step++) {
    for (int i = 0; i<wires.size(); i++) {
      if (simulationStarted) {
        wires.get(i).update();
      }
    }
  }

  for (int i = 0; i<wires.size(); i++) {
    wires.get(i).render();
  }

  for (int i = 0; i<wiresToRemove.size(); i++) {
    wires.remove(wiresToRemove.get(i));
  }

  wiresToRemove.clear();
}

void keyPressed() {
  if (key == ENTER) {
    simulationStarted = !simulationStarted;
  }
}

void mousePressed() {
  if (mouseButton == LEFT) {
    points.add(new Point(mouseX, mouseY, false));
  } else {
    for (int i = 0; i < points.size(); i++) {
      Point p = points.get(i);
      
      if (p.isOnPoint(mouseX, mouseY)) {
        if (mouseButton == RIGHT) {
          
          //Draw wires between points
          if (selected == null) {
            selected = p;
          } else {
            wires.add(new Wire(selected, p));
            selected = null;
          }
          
        } else if (mouseButton == CENTER) {
          //Lock and unlock points
          p.locked = !p.locked;
        }
      }
    }
  }
}

class Point {
  PVector position, prevPosition;
  boolean locked;

  Point(float x, float y, boolean isLocked) {
    position = new PVector(x, y);
    prevPosition = new PVector(x, y);
    locked = isLocked;
  }

  void update() {
    if (!locked) {
      PVector oldPosition = position.copy();
      
      PVector speed = PVector.sub(position, prevPosition);
      float frictionMag = speed.mag() * speed.mag() * 0.001f;//Air drag is proportionnal to the speed squared, here with a low coefficient for a rope
      PVector friction = speed.copy().normalize().mult(frictionMag);
      
      position.add(PVector.sub(speed, friction));//Don't mess with Newton
      position.add(0, 0.2f);//Gravity
      prevPosition = oldPosition;
    }
  }

  void render() {
    noStroke();
    //Draw points in white, or in red if locked
    if (locked) {
      fill(250, 20, 20);
    } else {
      fill(255, 255, 255);
    }
    circle(position.x, position.y, CIRCLE_RADIUS);
  }

  boolean isOnPoint(float x, float y) {
    float distanceX = position.x - x;
    float distanceY = position.y - y;
    return sqrt(sq(distanceX) + sq(distanceY)) < CIRCLE_RADIUS;
  }
}


class Wire {
  Point p1, p2;
  float length;
  float strength;

  Wire(Point point1, Point point2) {
    p1 = point1;
    p2 = point2;
    length = currentLength();
    strength = 5.0f;
  }

  void update() {
    
    PVector centre = PVector.add(p1.position, p2.position);
    centre.div(2);
    PVector dir = PVector.sub(p1.position, p2.position);
    
    //If the wire is deformed by more than its strength on a given update, it breaks
    if (currentLength() - length > strength) {
      wiresToRemove.add(this);//Don't remove it directly because we may be iterating over the list still
    }
    
    dir.normalize();
    
    //Technically inaccurate, because if a point is locked it allows the wire to be deformed, as it will only do half the correction
    if (!p1.locked) {
      p1.position.set(PVector.add(centre, PVector.mult(dir, length/2)));
    }
    if (!p2.locked) {
      p2.position.set(PVector.sub(centre, PVector.mult(dir, length/2)));
    }
  }

  void render() {
    stroke(255);
    line(p1.position.x, p1.position.y, p2.position.x, p2.position.y);
  }

  float currentLength() {
    return p1.position.dist(p2.position);
  }
}
