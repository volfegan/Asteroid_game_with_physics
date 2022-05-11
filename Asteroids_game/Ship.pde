/* Ship class with minimal physics simulation
 * @author Volfegan Geist [Daniel Leite Lacerda]
 * https://github.com/volfegan/Asteroid_game_with_physics
 */

public class Ship {
  PVector centre;
  PVector heading; //directions from origin the ship points to
  PVector forwardPoint;
  PVector speed;
  float maxSpeed;
  float mass;
  float moment_of_inertia;
  float rotationSpeed;
  PVector[] vertices;
  PVector[] mirrorVertices; //duplicate ship to render warping screen movements
  PVector[] forceFieldVertices;

  float waveCannonValue;
  boolean shooting;
  boolean shootWaveCannon;

  float forceFieldAngle;
  float forceFieldValue;
  boolean forceFieldActive;

  boolean thrusterActive;
  int particleTrailSize;
  int particleTrailMin;

  boolean warping; //going from one side of the screen to 
  PVector collisionPoint;
  boolean destroyed;

  PShape ship;
  PShape mirrorShip;
  PShape forceField;
  PShape mirrorForceField;

  public Ship (float x, float y) {

    this.centre = new PVector(x, y);
    this.heading = new PVector(0, -1);//Points UP!
    this.vertices = buildShipPolygon();
    this.mirrorVertices = new PVector[3];
    System.arraycopy(this.vertices, 0, this.mirrorVertices, 0, this.vertices.length);
    this.forceFieldVertices = buildForceFieldPolygon();

    this.mass = computeMass(this.vertices)*9;// massive and made of Unobtainium
    this.moment_of_inertia = momentOfInertiaOfTriangle(this.vertices);
    this.speed = new PVector(0, 0);
    this.maxSpeed = .5;//magnitude of the vector

    this.thrusterActive = false;
    this.particleTrailSize=0;
    this.particleTrailMin=30;

    this.waveCannonValue=0;//max = 100
    this.shooting=false;
    this.shootWaveCannon=false;

    this.forceFieldValue = 100; //100% energy level
    this.forceFieldActive = true;
    this.forceFieldAngle=0;

    this.warping = false;
    this.destroyed = false;
  }
  /*
   * Build a triangle and also generates the forwardPoint of this polygon
   *
   * @return PVector[] vertices (of the ship)
   */
  private PVector[] buildShipPolygon() {

    float size = 25;
    this.forwardPoint = PVector.add(this.centre, PVector.mult(this.heading, size));
    PVector SternPort = new PVector(-size/2, size/2);
    SternPort.add(this.centre);//Port side is the left side of a vessel. Stern = rear
    PVector SternSTBD = new PVector(size/2, size/2);
    SternSTBD.add(this.centre);//Starboard (STBD) side is the right side of a vessel.
    PVector[] vertices = {this.forwardPoint, SternSTBD, SternPort};
    return vertices;
  }
  /*
   * Build the force field polygon
   *
   * @return PVector[] forceFieldVertices
   */
  private PVector[] buildForceFieldPolygon() {
    PVector[] forceFieldVertices = new PVector[6];
    float radius = 35;
    int polygonSize = forceFieldVertices.length;
    for (int i = 0; i < polygonSize; i++) {
      float angle = ((float)i/polygonSize)*TAU;
      //Create a point from the origin (0,0)
      PVector point = new PVector(radius * sin(angle), radius *cos(angle));
      forceFieldVertices[i] = PVector.add(this.centre, point);
    }
    return forceFieldVertices;
  }
  /*
   * Computes the Area of the polygon. Area = Mass
   * References:
   * https://web.archive.org/web/20100405070507/http://valis.cs.uiuc.edu/~sariel/research/CG/compgeom/msg00831.html
   * https://www.baeldung.com/cs/2d-polygon-area
   *
   * @param PVector[] vertices (of the ship)
   * @return float mass (actually area)
   */
  private float computeMass(PVector[] vertices) {
    float mass = 0;
    for (int i=0; i < vertices.length; i++) {
      int j = (i+1)%vertices.length;
      mass += vertices[i].x * vertices[j].y;
      mass -= vertices[i].y * vertices[j].x;
    }
    return abs(mass)/2;
    //test PVector[] vertices = {new PVector(0, 0),new PVector(10, 0),new PVector(10, 10),new PVector(0, 10)}; //area=100;
    //test PVector[] vertices = {new PVector(0, 0),new PVector(10, 10),new PVector(0, 10)};//area=50;
  }
  /*
   * Computes the mass moment of inertia for a triangle under its centroid
   * @param PVector[] triangle
   * @return float moment_of_inertia_of_triangle
   */
  private float momentOfInertiaOfTriangle(PVector[] triangle) {
    float mass_of_triangle = this.mass;
    PVector centroid = calculateCentre(triangle);
    PVector a = PVector.sub(triangle[0], centroid);
    PVector b = PVector.sub(triangle[1], centroid);
    PVector c = PVector.sub(triangle[2], centroid);

    float aa = PVector.dot(a, a);
    float bb = PVector.dot(b, b);
    float cc = PVector.dot(c, c);
    float ab = PVector.dot(a, b);
    float bc = PVector.dot(b, c);
    float ca = PVector.dot(a, a);
    return (aa + bb + cc + ab + bc + ca) * mass_of_triangle/6;
    //test PVector[] vertices = {new PVector(0, 0),new PVector(10, 10),new PVector(0, 10)};//=1111.1
    //for mass_of_triangle = 50;
  }

  /*
   * Show ship's polygon and its mirror-ship if warping outside the screen
   */
  public void render() {

    this.ship = createShape();
    this.ship.beginShape();
    this.ship.fill(0);
    this.ship.stroke(0, 255, 0);
    for (int i=0; i< this.vertices.length; i++) {
      float x = this.vertices[i].x;
      float y = this.vertices[i].y;
      ship.vertex(x, y);
    }
    this.ship.endShape(CLOSE);
    shape(this.ship);

    //show mirror-ship when Warping outside the screen
    //it shows even without this because warping coordinates does the job. This is just precaution
    if (this.warping) {
      this.mirrorShip = createShape();
      this.mirrorShip.beginShape();
      this.mirrorShip.noFill();
      this.mirrorShip.stroke(0, 255, 0);
      for (int i=0; i< this.mirrorVertices.length; i++) {
        float x = this.mirrorVertices[i].x;
        float y = this.mirrorVertices[i].y;
        this.mirrorShip.vertex(x, y);
      }
      this.mirrorShip.endShape(CLOSE);
      shape(this.mirrorShip);
    }
  }
  /*
   * Show force field polygon if it has energy and it is active
   */
  public void renderForceField() {
    if (this.forceFieldValue > 0 && this.forceFieldActive == true) {
      
      //Re-build force field polygon around the ship
      this.forceFieldVertices = buildForceFieldPolygon();

      //Update force field angle and rotate force field
      this.forceFieldAngle += this.rotationSpeed;
      PVector forceFieldCentre = this.centre;
      int index = 0;
      for (PVector point : this.forceFieldVertices) {
        this.forceFieldVertices[index] = rotatePoint(point, forceFieldCentre, this.forceFieldAngle);
        index++;
      }

      this.forceField = createShape();
      this.forceField.beginShape();
      this.forceField.noFill();
      this.forceField.stroke(0, 255, 0, 99);
      if (random(1)<.4) this.forceField.stroke(0, 255, 0, 0); //blinking effect
      for (int i=0; i< this.forceFieldVertices.length; i++) {
        float x = this.forceFieldVertices[i].x;
        float y = this.forceFieldVertices[i].y;
        forceField.vertex(x, y);
      }
      this.forceField.endShape(CLOSE);
      shape(this.forceField);
    }
  }
  /*
   * Show a thruster particle trail using a bunch of magic numbers and noise 
   * Basic template: https://twitter.com/SnowEsamosc/status/1507273442709876737
   */
  void renderThrusters() {
    this.centre = calculateCentre(this.vertices);
    //ships particle trail
    stroke(0, 255, 0, 99);
    noFill();
    float angleExaust = this.heading.heading() + PI +radians(-30);

    println(degrees(this.heading.heading()));
    for (int trail=this.particleTrailMin; trail < this.particleTrailSize; trail++) {

      float dispersion = 1.2;
      float flux=dispersion*noise(trail-frameCount);

      float offsetX = 0;
      float offsetY = 0;
      //Finding good offsets to fit well the trail
      //0º to 45º
      if (degrees(this.heading.heading()) > 0 && degrees(this.heading.heading()) < 45) {
        offsetX = map(degrees(this.heading.heading()), 0, 45, 5, 0);
        offsetY = map(degrees(this.heading.heading()), 0, 45, -5, 0);
      }
      //45º to 90º
      if (degrees(this.heading.heading()) > 45 && degrees(this.heading.heading()) < 90) {
        offsetX = map(degrees(this.heading.heading()), 45, 90, 0, 0);
        offsetY = 0;
      }
      //90º to 135º
      if (degrees(this.heading.heading()) > 90 && degrees(this.heading.heading()) < 135) {
        offsetX = map(degrees(this.heading.heading()), 90, 135, 0, -5);
        offsetY = map(degrees(this.heading.heading()), 90, 135, 0, -5);
      }
      //135º to 180º
      if (degrees(this.heading.heading()) > 135 && degrees(this.heading.heading()) <= 180) {
        offsetX = map(degrees(this.heading.heading()), 135, 180, -5, -10);
        offsetY = map(degrees(this.heading.heading()), 135, 180, -5, 0);
      }
      //-180º to -135º
      if (degrees(this.heading.heading()) > -180 && degrees(this.heading.heading()) <= -135) {
        offsetX = -10;
        offsetY =  map(degrees(this.heading.heading()), -180, -135, 0, -10);
      }
      //-135º to -90º
      if (degrees(this.heading.heading()) > -135 && degrees(this.heading.heading()) <= -90) {
        offsetX = map(degrees(this.heading.heading()), -135, -90, -10, -0);
        offsetY = -10;
      }
      //-90º to -45º
      if (degrees(this.heading.heading()) > -90 && degrees(this.heading.heading()) <= -45) {
        offsetX = map(degrees(this.heading.heading()), -90, -45, -0, 5);
        offsetY = map(degrees(this.heading.heading()), -90, -45, -10, -5);
      }
      //-45º to -0º
      if (degrees(this.heading.heading()) > -45 && degrees(this.heading.heading()) <= -0) {
        offsetX = 5;
        offsetY = -5;
      }

      float posX = this.centre.x + offsetX + trail*cos(flux + angleExaust);
      float posY = this.centre.y + offsetY + trail*sin(flux + angleExaust);
      float scale = 17-trail/(this.particleTrailSize/17.5);

      square(posX, posY, scale);
    }
  }

  /*
   * Show random particles at the ship's heading when charging the wave cannon
   */
  void renderWaveCannonCharging() {
    if (this.waveCannonValue > 0) {
      PVector sparkAt = PVector.add(this.forwardPoint, PVector.mult(this.heading, 15));
      float alpha = map(this.waveCannonValue, 0, 100, 50, 255);
      stroke(0, 255, 0, alpha);
      fill(0, 255, 0, alpha);
      if (random(1) < .2 + this.waveCannonValue/200) {
        for (int r=5; r<=15; r+=5-this.waveCannonValue/50) {
          float spreadAngle = r*noise(time)+time;
          float sparkSize = random(3, 7);
          square(sparkAt.x + r*cos(spreadAngle), sparkAt.y + r*sin(spreadAngle), sparkSize);
        }
      }
    }
  }

  /*
   * Ship explosion sound effect
   */
  public void explosionSound() {

    float attackTime = 0.001;
    float sustainTime = 0.1;
    float sustainLevel = 0.5;
    float releaseTime = .5;

    try {
      noiseB.play();
      noiseW.play();
      noiseW.amp(0.5);
      envExplosionShip[0].play(noiseW, attackTime, sustainTime, sustainLevel, releaseTime);
      envExplosionShip[1].play(noiseB, attackTime, sustainTime, sustainLevel, releaseTime);
    } 
    catch (Exception e) {
      println("Ship Explosion sound failed. Time: "+time);
    }
  }

  /*
   * Ship shield sound effect
   */
  public void shieldSound() {

    float attackTime = 0.01;
    float sustainTime = 0.1;
    float sustainLevel = 0.5;
    float releaseTime = .2;

    try {
      triOsc.play();
      triOsc.freq(190+frameRate%20);
      triOsc.amp(.1);
      envShield.play(triOsc, attackTime, sustainTime, sustainLevel, releaseTime);
    } 
    catch (Exception e) {
      println("Ship Shield sound failed. Time: "+time);
    }
  }

  /*
   * Ship thruster sound effect
   */
  public void thrusterSound() {

    float attackTime = 0.001;
    float sustainTime = 0.2;
    float sustainLevel = 0.1;
    float releaseTime = .2;

    try {
      saw.play();
      saw.amp(.05);
      saw.freq(30+(frameRate)%20);
      envThruster.play(saw, attackTime, sustainTime, sustainLevel, releaseTime);
    } 
    catch (Exception e) {
      println("Ship thrusters sound failed. Time: "+time);
    }
  }

  /*
   * Ship shooting sound effect
   */
  public void shootingSound() {

    float attackTime = 0.01;
    float sustainTime = 0.1;
    float sustainLevel = 0.4;
    float releaseTime = .2;
    int[] freqs = {80, 120, 270, 290, 330};

    try {

      for (int i=0; i< freqs.length; i++) {
        attackTime += 0.01;
        sustainTime -= 0.02;
        sustainLevel -= 0.05;
        releaseTime += .005;

        if (i%2==0) {
          square.freq(freqs[i]);
          square.amp(.2);
          square.play();
          envShot[i].play(square, attackTime, sustainTime, sustainLevel, releaseTime);
        } else {
          pulse.freq(freqs[i]);
          pulse.amp(-.3*(freqs.length-i)/(freqs.length));
          envShot[i].play(pulse, attackTime, sustainTime, sustainLevel, releaseTime);
        }
      }
    } 
    catch (Exception e) {
      println("Ship Shooting sound failed. Time: "+time);
    }
  }

  /*
   * Ship Particle Wave Cannon sound effect
   */
  public void waveCannonSound() {

    float attackTime = 0.15;
    float sustainTime = 0.2;
    float sustainLevel = 0.3;
    float releaseTime = .8;

    try {

      saw.play();
      saw.amp(.2);
      saw.freq(550);
      envWaveCannon[0].play(saw, attackTime, sustainTime, sustainLevel, releaseTime);

      attackTime = 0.001;
      sustainTime = 0.4;
      sustainLevel = 0.7;
      releaseTime = .9;

      square.play();
      square.amp(.2);
      square.freq(220);
      envWaveCannon[1].play(square, attackTime, sustainTime, sustainLevel, releaseTime);

      sine.play();
      sine.amp(.3);
      sine.freq(280);
      envWaveCannon[2].play(sine, attackTime, sustainTime, sustainLevel, releaseTime);

      noiseP.play();
      noiseP.amp(.3);
      envWaveCannon[2].play(noiseP, attackTime, sustainTime, sustainLevel, releaseTime);
    } 
    catch (Exception e) {
      println("Ship Particle Wave Cannon sound failed. Time: "+time);
    }
  }


  /*
   * Handle Control keys function for all ship's action. Only handle one input key per turn!
   * [s,S] = shield; [a,A,d,D] = rotate ship; [w,W] = thrusters; [space bar] = shoot/charge wave cannon
   * 
   */
  public void controlStatus() {
    //Force Field control
    boolean activeForceField = false;
    //Thruster control
    boolean activeThruster = false;
    //Ship's rotation control
    boolean rotateShip = false;

    if (keyPressed) {
      if (key == 's' || key == 'S') {
        activeForceField = true;
      }
      if (key == 'w' || key == 'W') {
        activeThruster = true;
      }
      if (key == 'a' || key == 'A') {
        this.rotationSpeed = -.05;
        rotateShip = true;
      }
      if (key == 'd' || key == 'D') {
        this.rotationSpeed = .05;
        rotateShip = true;
      }
      //Charge wave cannon when space bar is pressed
      if (key == ' ') {
        this.waveCannonValue+=1;
        if (this.waveCannonValue > 100) this.waveCannonValue = 100;
      }
    }
    //Shooting control for bullets or a 100% charged wave cannon
    if (key == ' ' && spaceBarReleased) {
      //Reset variable
      spaceBarReleased=false;
      if (this.waveCannonValue == 100) {
        this.shootWaveCannon = true; //Shoot a 100% charged wave cannon

        //particle wave cannon sound effect
        this.waveCannonSound();
      } else {
        this.shooting = true; //Shoot normal bullet
        //shoot sound effect
        this.shootingSound();
      }
      this.waveCannonValue = 0; //Reset the wave cannon value after shooting;
    } else {
      this.shooting = false;
      this.shootWaveCannon = false;
    }
    //No wave cannon charging if warping
    if (this.warping) this.waveCannonValue = 0;

    //println(this.waveCannonValue);

    this.forceFieldStatus(activeForceField);
    this.thrusterStatus(activeThruster);
    this.rotation(rotateShip);
  }

  /*
   * Control key [s] is pressed for force field activation
   * Force Field energy level consuption/generation is also computed
   * @param boolean activeForceField
   */
  public void forceFieldStatus(boolean activeForceField) {

    if (activeForceField) {
      this.forceFieldActive = true;
      //Drain force field power values
      this.forceFieldValue--;
      if (this.forceFieldValue < -1) this.forceFieldValue=-1;

      //play shield sound effet
      if (this.forceFieldValue > 0) this.shieldSound();
    } else {
      this.forceFieldActive = false;
      //Recharge force field
      this.forceFieldValue += .5;
      if (this.forceFieldValue > 100) this.forceFieldValue=100;
    }
    //println(this.forceFieldValue);
  }

  /*
   * Control key [w] is pressed to activate thrusters
   * Thruster engine increases velocity on heading direction
   * @param boolean activeThruster
   */
  public void thrusterStatus(boolean activeThruster) {

    if (activeThruster) {
      this.thrusterActive = true;
      //play thruster sound effet
      this.thrusterSound();

      //calculate new speed on heading direction
      PVector newSpeed = new PVector(this.heading.x, this.heading.y);
      newSpeed.normalize();
      newSpeed.mult(.005);//speed step
      newSpeed = PVector.add(this.speed, newSpeed);

      if (newSpeed.mag() > this.maxSpeed) {
        newSpeed.normalize();
        newSpeed.mult(this.maxSpeed);
      }
      this.speed = newSpeed;

      //increase thruster particle trail Size
      this.particleTrailSize += 5;
      if (this.particleTrailSize > 100) this.particleTrailSize=100;
      //
    } else {
      //vanish the thruster particle trail
      this.particleTrailMin += 5;
      if (this.particleTrailSize <= this.particleTrailMin) {
        this.thrusterActive = false;
        //Reset all variables to initial values
        this.particleTrailSize=0;
        this.particleTrailMin=30;
      }
    }
  }

  /*
   * Rotate all points of the ship by its rotation speed when control keys [a, d] are pressed.
   * Also recalculates its centre, forward point and heading
   * @param boolean rotateShip
   */
  public void rotation(boolean rotateShip) {
    if (rotateShip) {
      this.centre = calculateCentre(this.vertices);
      int index = 0;
      for (PVector point : this.vertices) {
        this.vertices[index] = rotatePoint(point, this.centre, this.rotationSpeed);
        index++;
      }
      //update the mirrorVertices of this ship rotation if warping
      if (this.warping == true) {
        System.arraycopy(this.vertices, 0, this.mirrorVertices, 0, this.vertices.length);
      }
      this.forwardPoint = this.vertices[0];
      this.heading = PVector.sub(this.forwardPoint, this.centre);
      this.heading.normalize();
    }
  }
  /*
   * Compute the average centre (roughly) of a polygon
   * @param PVector[] vertices[(x0,y0),(x1,y1),...]
   * @return PVector centre
   */
  private PVector calculateCentre(PVector[] vertices) {
    int gonSize = vertices.length; //Number of edges in the polygon
    PVector centre = new PVector();
    for (int i = 0; i < gonSize; i++) {
      float x = vertices[i].x;
      float y = vertices[i].y;
      centre.x += x;
      centre.y += y;
    }
    centre.x /= gonSize;
    centre.y /= gonSize;
    return centre;
  }
  /*
   * Rotate 1 point around some centre position by some angle
   * @param PVector[] point
   * @param PVector rotCentre
   * @param float rotationSpeed (the angle)
   * @return PVector[] p (pointed rotated)
   */
  private PVector rotatePoint(PVector point, PVector rotCentre, float rotationSpeed) {
    //rotational matrix from the origin
    //[Px_rot] = [cos(angle)  -sin(angle)]*[Px]
    //[Py_rot] = [sin(angle)   cos(angle)] [Py]
    
    PVector p = new PVector();
    point.sub(rotCentre);
    p.x = point.x * cos(rotationSpeed) - point.y * sin(rotationSpeed);
    p.y = point.x * sin(rotationSpeed) + point.y * cos(rotationSpeed);
    p.add(rotCentre);
    return p;
  }


  /*
   * Compute the new ship velocity and direction after colliding with an asteroid
   * Also finds the nearest collision point
   * Reference: https://en.wikipedia.org/wiki/Elastic_collision (this does not account angular movements)
   * @param PVector v (speed of asteroid)
   * @param float mass (mass of asteroid)
   * @param PVector centroid (of asteroid)
   */
  public void updateVelocity(PVector v, float mass, PVector centroid) {
    PVector newSpeed = new PVector();

    newSpeed.x = ((this.mass - mass)/(this.mass + mass))*this.speed.x + (2*mass/(this.mass + mass))*v.x;
    newSpeed.y = ((this.mass - mass)/(this.mass + mass))*this.speed.y + (2*mass/(this.mass + mass))*v.y;

    if (newSpeed.mag() > this.maxSpeed) {
      newSpeed.normalize();
      newSpeed.mult(this.maxSpeed);
    }
    this.speed = newSpeed;

    //Find the collision point
    this.collisionPoint=null;
    //Check if the distance of the centres of objects are not absurd, continue
    if (dist(centroid.x, centroid.y, this.centre.x, this.centre.y) < (width+height)/4) {
      //find the closest ship's point on which there was the collision
      PVector d = PVector.sub(centroid, this.centre);
      d.normalize();//direction
      PVector possibleCollisionPoint = furthestPoint(this.vertices, d); //FUNCTION FROM GJK_algorithm
      PVector possibleCollisionPoint2 = furthestPoint(this.mirrorVertices, d); //FUNCTION FROM GJK_algorithm

      //The real collision point is the closest to the other asteroid centre
      if (possibleCollisionPoint.dist(centroid) <  possibleCollisionPoint2.dist(centroid)) {
        this.collisionPoint=possibleCollisionPoint;
      } else {
        this.collisionPoint=possibleCollisionPoint2;
      }
      //circle(this.collisionPoint.x, this.collisionPoint.y, 20);//Check if collision point is the right one
    }
  }

  /*
   * Updates the position of the ship polygon and their mirror-polygon if warping outside the screen
   */
  public void updatePosition() {

    int[] extremePoints = findIndexOfExtremePoints();//{mostLeft, mostRight, mostUp, mostDown};
    float mostLeftX = this.vertices[extremePoints[0]].x;
    float mostRightX = this.vertices[extremePoints[1]].x;
    float mostUpY = this.vertices[extremePoints[2]].y;
    float mostDownY = this.vertices[extremePoints[3]].y;
    //First extreme point outside the screen = warping. Show mirror-ship in the other side if warping
    if (mostLeftX < 0 || mostRightX > width || mostUpY < 0 || mostDownY > height) {
      this.warping = true;
    } else {
      this.warping = false;
    }

    //Last extreme point finish warping (ship ouside the screen).
    boolean warpingLastPoint=false;
    if (mostRightX < 0 || mostLeftX > width || mostDownY < 0 || mostUpY > height) {
      warpingLastPoint = true;
    }

    //calculate the amount of changed position for the ship
    PVector deltaPos = PVector.mult(this.speed, deltaTime);
    int index = 0;
    for (PVector p : this.vertices) {
      p.add(deltaPos);
      this.vertices[index] = p;
      index++;
    }

    //Only warp points of the ship if all of its extreme points passed the screen limits
    if (warpingLastPoint) {
      warpCoordinates(this.vertices);
    }

    //update the mirrorVertices of ship in the other side if warping
    if (this.warping == true && !warpingLastPoint) {
      this.mirrorVertices = warpCoordinates(this.vertices);
    }
  }
  /*
   * Get the index of extreme points from the polygon vertices
   * @return int[] extremePoints = {mostLeft, mostRight, mostUp, mostDown};
   */
  private int[] findIndexOfExtremePoints() {
    int mostLeft=0;
    int mostRight=0;
    int mostUp=0;
    int mostDown=0;

    int index = 0;
    for (PVector p : this.vertices) {
      //mostLeft
      if (p.x < this.vertices[mostLeft].x) {
        mostLeft = index;
      }
      //mostRight
      if (p.x > vertices[mostRight].x) {
        mostRight = index;
      }
      //mostUp
      if (p.y < this.vertices[mostUp].y) {
        mostUp = index;
      }
      //mostDown
      if (p.y > this.vertices[mostDown].y) {
        mostDown = index;
      }
      index++;
    }
    int[] extremePoints = {mostLeft, mostRight, mostUp, mostDown};
    return extremePoints;
  }
  /*
   * Creates a warping Coordinate Map to see the maximun translation operations to apply to all vertices
   * This cover edge cases where one point passes throughout the corner of the screen and needs both translation
   * of Y and X, while another points of the polygon only asks for one translation.
   * All points must receive the same coordinate translation operations to not create artifacts.
   * @param PVector[] vertices
   * @return int[] warpCoordinatesMap, where there are 4 values of 0 or 1 
   */
  private int[] warpOperations(PVector[] vertices) {
    int[] warpCoordinatesMap = {0, 0, 0, 0};

    for (PVector p : vertices) {
      int outsideRightScreen = warpCoordinatesMap[0];
      int outsideLeftScreen = warpCoordinatesMap[1];
      int outsideBottomScreen = warpCoordinatesMap[2];
      int outsideTopScreen = warpCoordinatesMap[3];

      if (outsideRightScreen==0) {
        warpCoordinatesMap[0] = (p.x > width) ? 1 : 0;//checks if outside right side of screen
      }
      if (outsideLeftScreen==0) {
        warpCoordinatesMap[1] = (p.x < 0) ? 1 : 0;//checks if outside left side of screen
      }
      if (outsideBottomScreen==0) {
        warpCoordinatesMap[2] = (p.y > height) ? 1 : 0;//checks if outside bottom side of screen
      }
      if (outsideTopScreen==0) {
        warpCoordinatesMap[3] = (p.y < 0) ? 1 : 0;//checks if outside top side of screen
      }
    }
    //Possible resoults are [0,0,0,0] (do nothing), [1,0,0,0] (translation from the right side),
    //[0,1,0,0] (translation from the left side), ..., [1,0,1,0] (translation from left-bottom side),
    //[0,1,0,1] (translation from right-top side), and the rest of the corners [1,0,0,1], [0,1,1,0].
    return warpCoordinatesMap;
  }
  /*
   * Toroidal mapping to warp together the edges of the screen for all points passing its limits
   * @param PVector[] vertices
   * @return PVector[] vertices with translated coordinates
   */
  private PVector[] warpCoordinates(PVector[] vertices) {
    int[] warpCoordinatesMap = warpOperations(vertices);
    int index = 0;
    for (PVector p : vertices) {
      vertices[index] = warpCoordinates(warpCoordinatesMap, p);
      index++;
    }
    return vertices;
  }
  /*
   * Toroidal mapping to warp together the edges of the screen for 1 point passing its limits
   * according to a warp Coordinates Mapping to dictate what translational operations to do
   * @param int[] warpCoordinatesMap
   * @param PVector point
   * @return PVector point with translated coordinates
   */
  private PVector warpCoordinates(int[] warpCoordinatesMap, PVector point) {
    if (warpCoordinatesMap[0]==1) {
      point.x -= width;
    }
    if (warpCoordinatesMap[1]==1) {
      point.x += width;
    }
    if (warpCoordinatesMap[2]==1) {
      point.y -= height;
    }
    if (warpCoordinatesMap[3]==1) {
      point.y += height;
    }
    return point;
  }
}
