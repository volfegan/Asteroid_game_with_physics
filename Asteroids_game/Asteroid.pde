/* Asteroid class with minimal physics simulation
 * @author Volfegan Geist [Daniel Leite Lacerda]
 * https://github.com/volfegan/Asteroid_game_with_physics
 */

public class Asteroid {
  PVector centre;
  PVector speed;
  float maxSpeed;
  float maxRadius;
  float minRadius;
  float mass;
  float moment_of_inertia;
  float rotationSpeed;
  PVector[] vertices;
  PVector[] mirrorVertices; //duplicate asteroid to render warping screen movements

  boolean warping; //going from one side of the screen to another
  boolean colliding;
  PVector collisionPoint;
  boolean destroyed;

  PShape asteroid;
  PShape mirrorAsteroid;

  float life; //how many shoots it needs to be destroyed (either 2 or 1 shots) 

  public Asteroid (float x, float y, float maxRadius, float polygonSize) {

    this.centre = new PVector(x, y);
    this.vertices = buildAsteroidPolygon(polygonSize, maxRadius);
    this.mirrorVertices = new PVector[(int)polygonSize];
    System.arraycopy(this.vertices, 0, this.mirrorVertices, 0, this.vertices.length);

    this.mass = computeMass(this.vertices);
    this.moment_of_inertia = computeMomentOfInertia(this.vertices);
    float velocity = .12;
    this.speed = new PVector(random(-velocity, velocity), random(-velocity, velocity));
    this.rotationSpeed = random(-.01, .01);
    this.maxSpeed = .3;//magnitude of the vector

    this.life = (this.maxRadius > 50) ? 1 : 0;

    this.warping = false;
    this.colliding = false;
    this.destroyed = false;
  }
  /*
   * Build a possible non-convex polygon shape of the asteroid with a given number of vertices
   * Also generates the maxRadius and minRadius of this polygon
   *
   * REMINDER: the GJK algorithm will detect collisions on the convex form of this polygon.
   * If someone wanted this to be a perfect collision detection,
   * just subdivide this non-convex polygon into 2 or more convex polygons.
   * @param float polygonSize (number of vertices)
   * @param float maxRadius
   * @return PVector[] vertices (of the asteroid)
   */
  private PVector[] buildAsteroidPolygon(float polygonSize, float maxRadius) {
    PVector[] vertices = new PVector[(int)polygonSize];
    float tempMaxRadius = 0;
    float tempMinRadius = 999999;
    for (int i = 0; i < polygonSize; i++) {
      float radius = maxRadius*(random(0.6, 1));
      float angle = ((float)i/polygonSize)*TAU;
      //Create a point from the origin (0,0)
      PVector point = new PVector(radius * sin(angle), radius *cos(angle));
      vertices[i] = PVector.add(this.centre, point);

      if (radius > tempMaxRadius) {
        tempMaxRadius = radius;
      }      
      if (radius < tempMinRadius) {
        tempMinRadius = radius;
      }
    }
    this.minRadius = tempMinRadius;
    this.maxRadius = tempMaxRadius;
    return vertices;
  }
  /*
   * Computes the Area of the polygon. Area = Mass
   * References:
   * https://web.archive.org/web/20100405070507/http://valis.cs.uiuc.edu/~sariel/research/CG/compgeom/msg00831.html
   * https://www.baeldung.com/cs/2d-polygon-area
   *
   * @param float size (number of vertices)
   * @return PVector[] vertices (of the asteroid)
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
   * Computes the mass moment of inertia
   * References:
   * https://stackoverflow.com/questions/41592034/computing-tensor-of-inertia-in-2d/41618980#41618980
   * https://fotino.me/moment-of-inertia-algorithm/
   * @param PVector[] vertices
   * @return float moment_of_inertia
   */
  private float computeMomentOfInertia(PVector[] vertices) {
    float moment_of_inertia=0;

    //Triangulate the asteroid polygon
    PVector o = calculateCentre(vertices);
    PVector[][] triangles  = new PVector[vertices.length][3];
    for (int i=0; i < vertices.length; i++) {
      PVector a = vertices[i];
      PVector b = vertices[(i+1)%(vertices.length)];
      PVector[] Triangle  = {a, b, o};
      triangles[i]=Triangle;
    }

    float[] mass_of_triangles = new float[triangles.length];
    float[] moment_of_inertial_triangles = new float[triangles.length];
    PVector[] centroid_of_triangles = new PVector[triangles.length];
    PVector combinedCentroid = new PVector();

    float totalMass = 0;

    //Calculate the mass, moment_of_inertial and centroid for each Triangle
    for (int i=0; i < triangles.length; i++) {
      //There is a redudance here as computeMass() and calculateCentre() are also called inside  
      //momentOfInertiaOfTriangle() for the same triangle.
      //But as this is only called during asteroid construction, it won't affect performance.
      mass_of_triangles[i] = computeMass(triangles[i]);
      centroid_of_triangles[i] = calculateCentre(triangles[i]);
      moment_of_inertial_triangles[i] = momentOfInertiaOfTriangle(triangles[i]);

      totalMass += mass_of_triangles[i];
      combinedCentroid.add(PVector.mult(centroid_of_triangles[i], mass_of_triangles[i]));
    }
    combinedCentroid.div(totalMass);
    for (int i=0; i < triangles.length; i++) {
      moment_of_inertia += moment_of_inertial_triangles[i] + mass_of_triangles[i] * PVector.sub(centroid_of_triangles[i], combinedCentroid).magSq();
    }
    return moment_of_inertia;
    //test PVector[] vertices = {new PVector(0,0),new PVector(10,0),new PVector(10,10),new PVector(0,10)}; //=2222.2
    //From textbook, a square shape (10 by 10) with mass = 100, it should be 1666,666.
    //For rectangular shapes I = mass*(a^2 + b^2)/12
  }
  /*
   * Computes the mass moment of inertia for a triangle under its centroid
   * @param PVector[] triangle
   * @return float moment_of_inertia_of_triangle
   */
  private float momentOfInertiaOfTriangle(PVector[] triangle) {
    float mass_of_triangle = computeMass(triangle);
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
  }

  /*
   * Show asteroid polygon and its mirror-asteroid if warping outside the screen
   */
  public void render() {
    this.asteroid = createShape();
    this.asteroid.beginShape();
    this.asteroid.noFill();
    this.asteroid.stroke(0, 255, 0);
    for (int i=0; i< this.vertices.length; i++) {
      float x = this.vertices[i].x;
      float y = this.vertices[i].y;
      asteroid.vertex(x, y);
    }
    this.asteroid.endShape(CLOSE);
    shape(this.asteroid);

    //show mirror asteroid when Warping outside the screen
    //it shows even without this because warping coordinates does the job. This is just precaution
    if (this.warping) {
      this.mirrorAsteroid = createShape();
      this.mirrorAsteroid.beginShape();
      this.mirrorAsteroid.noFill();
      this.mirrorAsteroid.stroke(0, 255, 0);
      for (int i=0; i< this.mirrorVertices.length; i++) {
        float x = this.mirrorVertices[i].x;
        float y = this.mirrorVertices[i].y;
        this.mirrorAsteroid.vertex(x, y);
      }
      this.mirrorAsteroid.endShape(CLOSE);
      shape(this.mirrorAsteroid);
    }
  }
  /*
   * Show all vertices of asteroid polygon connected to each other when colliding
   */
  public void renderCollision() {
    if (this.colliding == true) {
      for (int i=0; i< this.vertices.length; i++) {
        for (int j = i + 2; j < this.vertices.length; j++) {
          float x1 = this.vertices[i].x;
          float y1 = this.vertices[i].y;
          float x2 = this.vertices[j].x;
          float y2 = this.vertices[j].y;
          stroke(0, 255, 0, 69);
          line(x1, y1, x2, y2);
        }
      }
      if (this.warping) {
        for (int i=0; i< this.mirrorVertices.length; i++) {
          for (int j = i + 2; j < this.mirrorVertices.length; j++) {
            float x1 = this.mirrorVertices[i].x;
            float y1 = this.mirrorVertices[i].y;
            float x2 = this.mirrorVertices[j].x;
            float y2 = this.mirrorVertices[j].y;
            stroke(0, 255, 0, 42);
            line(x1, y1, x2, y2);
          }
        }
      }
    }
  }

  /*
   * Asteroid explosion sound effect
   */
  public void explosionSound() {

    float attackTime = 0.001;
    float sustainTime = 0.02;
    float sustainLevel = 0.5;
    float releaseTime = .9;

    try {
      noiseB.play();
      noiseB.pan(sin(frameRate));
      noiseB.amp(0.3+0.2*abs(sin(frameRate)));
      noiseW.play();
      noiseW.amp(0.3+0.2*abs(sin(frameRate)));
      envExplosionAsteroid[0].play(noiseW, attackTime, sustainTime, sustainLevel, releaseTime);
      envExplosionAsteroid[1].play(noiseB, attackTime, sustainTime, sustainLevel, releaseTime);
    } 
    catch (Exception e) {
      println("Asteroid Explosion sound failed. Time: "+time);
    }
  }


  /*
   * Compute the new asteroid velocity and direction after colliding with another asteroid/ship
   * Reference: https://en.wikipedia.org/wiki/Elastic_collision (this does not account angular movements)
   * @param PVector v (speed of another asteroid)
   * @param float mass (mass of another asteroid)
   */
  public void updateVelocity(PVector v, float mass) {
    PVector newSpeed = new PVector();

    newSpeed.x = ((this.mass - mass)/(this.mass + mass))*this.speed.x + (2*mass/(this.mass + mass))*v.x;
    newSpeed.y = ((this.mass - mass)/(this.mass + mass))*this.speed.y + (2*mass/(this.mass + mass))*v.y;

    if (newSpeed.mag() > this.maxSpeed) {
      newSpeed.normalize();
      newSpeed.mult(this.maxSpeed);
    }
    this.speed = newSpeed;
  }

  /*
   * Rotate all points of the asteroid by its rotation speed. Also recalculates its centre
   */
  public void rotation() {
    int index = 0;
    this.centre = calculateCentre(this.vertices);
    for (PVector point : this.vertices) {
      this.vertices[index] = rotatePoint(point, this.centre);
      index++;
    }
    //update the mirrorVertices of asteroid if warping
    if (this.warping == true) {
      System.arraycopy(this.vertices, 0, this.mirrorVertices, 0, this.vertices.length);
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
   * Rotate 1 point around some centre position by current rotational speed
   * @param PVector point
   * @param PVector rotCentre
   * @return PVector p (rotated)
   */
  private PVector rotatePoint(PVector point, PVector rotCentre) {
    //rotational matrix from the origin
    //[Px_rot] = [cos(angle)  -sin(angle)]*[Px]
    //[Py_rot] = [sin(angle)   cos(angle)] [Py]
    PVector p = new PVector();
    point.sub(rotCentre);
    p.x = point.x * cos(this.rotationSpeed) - point.y * sin(this.rotationSpeed);
    p.y = point.x * sin(this.rotationSpeed) + point.y * cos(this.rotationSpeed);
    p.add(rotCentre);
    return p;
  }

  /*
   * Updates the rotational speed after a collision and finds the nearest collision point
   * This is not accurated at all. For something realistic see Reference:
   * https://physics.stackexchange.com/questions/510171/elastic-collision-between-a-point-and-a-rotating-solid
   * @param float mass
   * @param PVector velocity
   * @param PVector centroid of another colliding object
   */
  public void updateRotation(float mass, PVector velocity, PVector centroid) {
    // w_new = w + 1/I (r x n) p, where w is angular momentum, I=MomentOfInertia
    // r = radius vector on where the object collided, p is the linear mommentum of the colliding object

    this.collisionPoint=null;
    //Check if the distance of the centres of objects are not absurd, continue
    if (dist(centroid.x, centroid.y, this.centre.x, this.centre.y) < (width+height)/4) {
      //find the closest asteroid point on which there was the collision
      PVector d = PVector.sub(centroid, this.centre);
      d.normalize();
      PVector possibleCollisionPoint = furthestPoint(this.vertices, d); //FUNCTION FROM GJK_algorithm
      PVector possibleCollisionPoint2 = furthestPoint(this.mirrorVertices, d); //FUNCTION FROM GJK_algorithm

      //The real collision point is the closest to the other asteroid centre
      if (possibleCollisionPoint.dist(centroid) <  possibleCollisionPoint2.dist(centroid)) {
        this.collisionPoint=possibleCollisionPoint;
      } else {
        this.collisionPoint=possibleCollisionPoint2;
      }
      //circle(this.collisionPoint.x, this.collisionPoint.y, 20);//Check if collision point is the right one

      PVector r = PVector.sub(this.collisionPoint, this.centre);
      PVector n = new PVector(velocity.x, velocity.y);
      n.normalize();
      float angularMomentum = this.rotationSpeed + 1/this.moment_of_inertia * (mass*velocity.mag()) * (r.x*n.y-n.x*r.y);
      //println(angularMomentum);

      if (abs(angularMomentum)<.05 && this.collisionPoint != null) {
        this.rotationSpeed=angularMomentum;
      }
    }
  }

  /*
   * Updates the position of the asteroid polygon and mirror-asteroid if warping outside the screen
   */
  public void updatePosition() {

    int[] extremePoints = findIndexOfExtremePoints();//{mostLeft, mostRight, mostUp, mostDown};
    float mostLeftX = this.vertices[extremePoints[0]].x;
    float mostRightX = this.vertices[extremePoints[1]].x;
    float mostUpY = this.vertices[extremePoints[2]].y;
    float mostDownY = this.vertices[extremePoints[3]].y;
    //First extreme point outside the screen = warping. Show mirror-asteroid in the other side if warping
    if (mostLeftX < 0 || mostRightX > width || mostUpY < 0 || mostDownY > height) {
      this.warping = true;
    } else {
      this.warping = false;
    }

    //Last extreme point finish warping (asteroid ouside the screen).
    boolean warpingLastPoint=false;
    if (mostRightX < 0 || mostLeftX > width || mostDownY < 0 || mostUpY > height) {
      warpingLastPoint = true;
    }

    //calculate the amount of changed position
    PVector deltaPos = PVector.mult(this.speed, deltaTime);
    int index = 0;
    for (PVector p : this.vertices) {
      p.add(deltaPos);
      this.vertices[index] = p;
      index++;
    }

    //Only warp points of the asteroid if all of its extreme points passed the screen limits
    if (warpingLastPoint) {
      warpCoordinates(this.vertices);
    }

    //update the mirrorVertices of asteroid in the other side if warping
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
   * of Y and X, while another points of the asteroid polygon only asks for one translation.
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
