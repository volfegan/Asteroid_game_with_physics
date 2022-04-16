/* Bullet class for big guns
 * @author Volfegan Geist [Daniel Leite Lacerda]
 * https://github.com/volfegan/Asteroid_game_with_physics
 */

public class Bullet {
  PVector pos;
  PVector speed;

  PVector[] particle;
  PVector[] waveCannon;//polygon of wavecannon

  float beam;
  float spread_wave;
  float waveCannonTimer;
  boolean waveCannonActive;

  boolean destroyed;

  public Bullet (float x, float y, PVector direction) {
    this.pos = new PVector(x, y);
    this.speed = direction;
    this.speed.normalize();

    this.particle = new PVector[1];
    this.particle[0] = this.pos;
    this.waveCannon = buildWaveCannonPolygon(this.pos, direction);
    this.beam=0;
    this.spread_wave=0;
    this.waveCannonActive = false;
    this.destroyed = false;
  }

  /*
   * Updates the position of the bullet (not a particle wave cannon) and checks if outside the screen
   */
  public void updatePosition() {

    if (this.waveCannonActive == false) {
      //calculate the amount of changed position for the ship
      PVector deltaPos = PVector.mult(this.speed, deltaTime);
      this.pos.add(deltaPos);
      this.particle[0] = this.pos;

      //Check if this.pos is outside the screen
      if (this.pos.x > width || this.pos.x < 0 ||this.pos.y > height || this.pos.y < 0) {
        this.destroyed = true;
      }
    }
  }
  /*
   * Show bullet as a square
   */
  public void render() {
    if (this.waveCannonActive == false) {
      stroke(0, 255, 0);
      fill(0, 255, 0);
      square(this.pos.x, this.pos.y, 5);
    }
  }

  /*
   * Build a retangular polygon that extends in front of the ship heading
   *
   * @param PVector shipForwardPoint
   * @param PVector direction
   * @return PVector[] vertices (of the Wave Cannon Polygon)
   */
  private PVector[] buildWaveCannonPolygon(PVector shipForwardPoint, PVector direction) {
    PVector[] vertices = new PVector[4];
    float sideSize = 25;
    float WaveCannonLength=0; //it will be big enough to touch the screen from where the ship point to

    PVector[] screen ={new PVector(0, 0), new PVector(width, 0), new PVector(width, height), new PVector(0, height)};
    //a point from the ship's forward point in the direction of its heading far away with size = width+height
    PVector shipHeadingOutwards = PVector.add(shipForwardPoint, PVector.mult(direction, width+height));

    //Find the intersection point from the ship's heading to the screen segment it point towards
    for (int i=0; i<screen.length-1; i++) {
      int j=i+1;
      PVector intersectScreen = intersectPoint(screen[i], screen[j], shipForwardPoint, shipHeadingOutwards);

      if (intersectScreen != null) {
        float temp = dist(shipForwardPoint.x, shipForwardPoint.y, intersectScreen.x, intersectScreen.y);
        if (temp > WaveCannonLength) WaveCannonLength=temp;
      }

      if (i==0) {
        intersectScreen = intersectPoint(screen[0], screen[3], shipForwardPoint, shipHeadingOutwards);
        if (intersectScreen != null) {
          float temp = dist(shipForwardPoint.x, shipForwardPoint.y, intersectScreen.x, intersectScreen.y);
          if (temp > WaveCannonLength) WaveCannonLength=temp;
        }
      }
    }
    if (WaveCannonLength==0) WaveCannonLength = width+height;

    //Create a very big rectangle centred on origin (0,0)
    vertices[0] = new PVector(-sideSize/2, 0);
    vertices[1] = new PVector(sideSize/2, 0);
    vertices[2] = new PVector(sideSize/2, -WaveCannonLength);
    vertices[3] = new PVector(-sideSize/2, -WaveCannonLength);

    //Rotate the polygon in the given direction
    float angle = direction.heading()+PI/2;
    for (PVector point : vertices) {
      PVector p = new PVector(point.x, point.y);
      point.x = p.x * cos(angle) - p.y * sin(angle);
      point.y = p.x * sin(angle) + p.y * cos(angle);
    }
    //Move all polygon towards the ship forward point
    for (PVector point : vertices) {
      point.add(shipForwardPoint);
    }
    return vertices;
  }
  /*
   * Checks if intersection point is within segment range
   * @param PVector point
   * @param PVector segmentPointA
   * @param PVector segmentPointB
   * @return boolean
   */
  boolean outOfRange(PVector p, PVector segmentPointA, PVector segmentPointB) {
    PVector sA = segmentPointA;
    PVector sB = segmentPointB;
    return ((p.x < sA.x && p.x < sB.x) || (p.x > sA.x && p.x > sB.x)
      || (p.y <sA.y && p.y < sB.y) || (p.y >sA.y && p.y > sB.y));
  }

  /*
   * Calculates the intersection point between two segments
   *
   * @param PVector segmentPoint1
   * @param PVector segmentPoint2
   * @param PVector segmentPointA
   * @param PVector segmentPointB
   * @return PVector intersection or null
   */
  private PVector intersectPoint(PVector segmentPoint1, PVector segmentPoint2, 
    PVector segmentPointA, PVector segmentPointB) {
    PVector intersection = new PVector();
    PVector s1 = segmentPoint1;
    PVector s2 = segmentPoint2;
    PVector sA = segmentPointA;
    PVector sB = segmentPointB;

    //calculate the intersection point (x, y)
    intersection.x = ((sA.x * sB.y - sA.y * sB.x)
      * (s1.x - s2.x) - (sA.x - sB.x)
      * (s1.x * s2.y - s1.y * s2.x))
      / ((sA.x - sB.x) * (s1.y - s2.y) - (sA.y - sB.y)
      * (s1.x - s2.x));
    intersection.y = ((sA.x * sB.y - sA.y * sB.x)
      * (s1.y - s2.y) - (sA.y - sB.y)
      * (s1.x * s2.y - s1.y * s2.x))
      / ((sA.x - sB.x) * (s1.y - s2.y) - (sA.y - sB.y)
      * (s1.x - s2.x));

    if (outOfRange(intersection, sA, sB) || outOfRange(intersection, s1, s2)
      || Float.isNaN(intersection.x) || Float.isNaN(intersection.y)) {
      intersection = null;
    }
    //check if end points of a segment is the intersection 
    if (intersection == null) {
      if ((s1.x==sA.x && s1.y==sA.y) || (s2.x==sA.x && s2.y==sA.y)) {
        intersection = sA;
      }
      if ( (s1.x==sB.x && s1.y==sB.y) || (s2.x==sB.x && s2.y==sB.y)) {
        intersection = sB;
      }
    }

    return intersection;
  }

  /*
   * Updates the bullet's variables to become a particle wave cannon
   */
  public void waveCannonActivation() {
    this.waveCannonActive = true;
    this.waveCannonTimer = time;
  }

  /*
   * Updates the particle wave cannon lifespan duration (1s), if active
   */
  public void waveCannonStatus() {
    if (this.waveCannonActive && millis() - this.waveCannonTimer > 1000) {
      this.waveCannonActive = false;
      this.destroyed = true;
    }
  }

  /*
   * Update the particle wave cannon retangular polygon that will be used for collision detection
   * @param PVector shipForwardPoint
   * @param PVector direction
   */
  public void updateParticleWaveCannonPolygon(PVector shipForwardPoint, PVector direction) {

    this.pos = new PVector(shipForwardPoint.x, shipForwardPoint.y);//the normal bullet is frozen on this.pos
    this.speed = direction;
    this.speed.normalize();
    this.waveCannon = buildWaveCannonPolygon(shipForwardPoint, direction);

    //visualize the particle wave cannon retangular polygon
    boolean visualizeWaveCannonPolygon = false;
    if (visualizeWaveCannonPolygon) {
      stroke(0, 255, 0, 99);
      for (int i=0; i<this.waveCannon.length-1; i++) {
        int j=i+1;
        PVector p1 = this.waveCannon[i];
        PVector p2 = this.waveCannon[j];
        line(p1.x, p1.y, p2.x, p2.y);
        if (i==0) {
          p2 = this.waveCannon[this.waveCannon.length-1];
          line(p1.x, p1.y, p2.x, p2.y);
        }
      }
    }
  }
  /*
   * Render the particle wave cannon
   *
   * References: 
   * https://www.youtube.com/watch?v=PqW1GOrVMS0
   * https://www.dwitter.net/d/24463, https://www.dwitter.net/d/24467
   */
  public void renderParticleWaveCannon() {

    noStroke();
    float diagonal = 1.414*width;
    //controls the speed of the particle wave beam
    if (this.beam < diagonal+abs(this.spread_wave)) {
      this.beam+=deltaTime*3;
    }
    for (int repeat_rays=30; repeat_rays>0; repeat_rays--) {
      float d=0, y=0;
      //create a random walk like beam
      for (float x=0; x<this.beam+this.spread_wave; x++) {
        d+=(random(-1, 1));
        this.spread_wave = random(d)*random(-1, 1);

        //this ray runs from Origin (0,0) in x direction -> in incremental steps
        //while the y direction is random up or down
        PVector rayFragmentPos = new PVector(x, y+d);

        //Rotate the fragment ray point in the ship's direction
        float angle = this.speed.heading();
        rayFragmentPos = rotatePoint(rayFragmentPos, angle);

        //Move the fragment ray point to the ship forward point (bullet exit pos)
        rayFragmentPos.add(this.pos);

        fill(0, 255-pow(x, .2)*pow(d/7, 2), 0); //magic numbers create the thickness of the beam
        rect(rayFragmentPos.x, rayFragmentPos.y, 1, 1);
      }
    }
    //inner black rays
    fill(0);
    for (int repeat_rays=5; repeat_rays>0; repeat_rays--) {
      float d=0, y=0;
      for (int x=0; x<this.beam; x++) {
        d+=(random(-2, 2));
        //this ray runs from Origin (0,0) in x direction
        PVector rayFragmentPos = new PVector(x, y+d);
        //Rotate the point in the ship's direction
        float angle = this.speed.heading();
        rayFragmentPos = rotatePoint(rayFragmentPos, angle);
        //Move point to the ship forward point
        rayFragmentPos.add(this.pos);

        rect(rayFragmentPos.x, rayFragmentPos.y, 3, 3);
      }
    }
  }
  /*
   * Rotate 1 point around the orgin (0,0) by some angle
   * @param PVector[] point
   * @param float angle
   * @return PVector[] p
   */
  private PVector rotatePoint(PVector point, float angle) {
    //rotational matrix from the origin
    //[Px_rot] = [cos(angle)  -sin(angle)]*[Px]
    //[Py_rot] = [sin(angle)   cos(angle)] [Py]
    PVector p = new PVector();
    p.x = point.x * cos(angle) - point.y * sin(angle);
    p.y = point.x * sin(angle) + point.y * cos(angle);
    return p;
  }
}
