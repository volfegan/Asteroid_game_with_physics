/*
 * @author Volfegan Geist [Daniel Leite Lacerda]
 * https://github.com/volfegan/Asteroid_game_with_physics
 * Functions used on Asteroid_game.pde
 */


/*
 * Create 8 new asteroids in the screen, except on given location (adding them to the asteroids ArrayList)
 * If doNotSpawHere is outside the screen or some edge case, it will generate 9 asteroids
 * @param ArrayList<Asteroid> asteroids, PVector doNotSpawnHere
 */
void createAsteroids(ArrayList<Asteroid> asteroids, PVector doNotSpawnHere) {
  int n=asteroids.size(); //asteroids starting index

  float notHereX = doNotSpawnHere.x;
  float notHereY = doNotSpawnHere.y;

  float extentionX=width/3;
  float extentionY=height/3;
  float upperBoundX=0;
  float upperBoundY=extentionY;
  for (float screenX=0; screenX < width-2; screenX+=extentionX) {
    upperBoundX=screenX+extentionX;
    for (float screenY=0; screenY < height-2; screenY+=extentionY) {
      //Create an astreoid, except at No Spawn Location
      if ((notHereX>screenX && notHereX<=upperBoundX && notHereY>screenY && notHereY<=upperBoundY)==false) {

        float maxRadius=random(50, 80);
        int polygonSize = (int)random(12, 21);
        float posX = random(screenX+100, upperBoundX-100);
        float posY = random(screenY+100, upperBoundY-100);
        asteroids.add(new Asteroid(posX, posY, maxRadius, polygonSize));
        //asteroids.get(n).speed = new PVector(); //ZERO speed for debug
        //println("Mass="+asteroids.get(n).mass);
        //println("Moment of inertia="+asteroids.get(n).moment_of_inertia);
        n++;
      }
      upperBoundY+=extentionY;
    }
    upperBoundY=extentionY;
  }
}

/*
 * Handle all variables between two colliding asteroids, and updates the collisionLocation list
 * Update velocities, angular momentum, collision location, and force entangled asteroids to separate
 * @param Asteroid rock1, Asteroid rock2, ArrayList<PVector> collisionsLocation
 */
void handleAsteroidCollisions(Asteroid rock1, Asteroid rock2, ArrayList<PVector> collisionsLocation) {

  //Update Velocities
  PVector tempVelocity = rock1.speed;
  rock1.updateVelocity(rock2.speed, rock2.mass);
  rock2.updateVelocity(tempVelocity, rock1.mass);

  //Update Angular momentum
  rock1.updateRotation(rock2.mass, rock2.speed, rock2.centre);
  rock2.updateRotation(rock1.mass, rock1.speed, rock1.centre);

  //Show collision drawing
  rock1.colliding = true;
  rock2.colliding = true;
  if (rock1.collisionPoint != null && rock2.collisionPoint != null) {
    collisionsLocation.add(PVector.add(rock1.collisionPoint, rock2.collisionPoint).mult(.5));
  }
  //Separate asteroids that are entangled
  //Check if they are on same direction with a max difference of 10 degrees (10*PI/180 radians)
  float angle = PVector.angleBetween(rock1.speed, rock2.speed);
  if ((degrees(angle) < 10) && 
    ((rock1.maxRadius+rock2.maxRadius) < dist(rock1.centre.x, rock1.centre.y, rock2.centre.x, rock2.centre.y))) {
    //Change a bit the direction of the asteroids
    rock1.speed.rotate(angle/7);
    rock2.speed.rotate(-angle/7);

    //QUANTUM LEAP (Change the position a bit in the opposite direction of the other asteroid)
    if ((rock1.minRadius+rock2.minRadius) < dist(rock1.centre.x, rock1.centre.y, rock2.centre.x, rock2.centre.y)) {
      PVector d = PVector.sub(rock1.centre, rock2.centre);
      d.normalize();
      float quantumLeapStep = 10;
      d.mult(quantumLeapStep);
      //Quantum leap if the direction between new pos is not against its velocity (greater than 120degree)
      angle = PVector.angleBetween(rock1.speed, d);
      if (degrees(angle) > 120) {
        for (PVector verticePoint : rock1.vertices) {
          verticePoint.add(d);
        }
        if (rock1.warping) {
          for (PVector verticePoint : rock1.mirrorVertices) {
            verticePoint.add(d);
          }
        }
      }
      //for the other asteroid
      d.mult(-1);
      angle = PVector.angleBetween(rock1.speed, d);
      if (degrees(angle) >  120) {
        for (PVector verticePoint : rock2.vertices) {
          verticePoint.add(d);
        }
        if (rock1.warping) {
          for (PVector verticePoint : rock2.mirrorVertices) {
            verticePoint.add(d);
          }
        }
      }
      rock1.updatePosition();
      rock2.updatePosition();
    }
  }
}

/*
 * Show sparks between colliding asteroids
 */
void showCollisionSparks() {
  ArrayList<Float> expiredSparks = new ArrayList<Float>(); //collects keys from collisionSparks HashMap
  //the key set of collisionSparks it's the collision occurrence time
  for (float t : collisionSparks.keySet()) {
    //show animation for 255ms
    float timer = millis() - t;
    if (timer > 255) {
      expiredSparks.add(t);
    } else {
      for (PVector sparkAt : collisionSparks.get(t)) {
        float alpha = map(timer, 0, 255, 255, 0); //the near the expiration, less alpha
        stroke(0, 255, 0, alpha);
        for (int r=0; r<=10; r+=5) {
          float spreadAngle = r*noise(time)+time;
          float sparkSize = map(timer, 0, 255, 9, 3);// the near the expiration, size decreases
          square(sparkAt.x + r*cos(spreadAngle), sparkAt.y + r*sin(spreadAngle), sparkSize);
        }
      }
    }
  }
  //Remove expired sparks collision from the HashMap
  for (float t : expiredSparks) {
    collisionSparks.remove(t);
  }
}

/*
 * Rotates a segment line on its mid-point
 */
void rotateSegment(PVector[] line, float rotationSpeed) {
  PVector mid = calculateCentre(line);
  for (PVector point : line) {
    //rotational matrix from the origin
    //[Px_rot] = [cos(angle)  -sin(angle)]*[Px]
    //[Py_rot] = [sin(angle)   cos(angle)] [Py]
    PVector p = new PVector(point.x, point.y);
    p.sub(mid);
    point.x = p.x * cos(rotationSpeed) - p.y * sin(rotationSpeed);
    point.y = p.x * sin(rotationSpeed) + p.y * cos(rotationSpeed);
    point.add(mid);
  }
}

/*
 * Show destroyed asteroid explosion
 */
void showDestroyedAsteroidExplosion() {
  ArrayList<Float> expiredAsteroids = new ArrayList<Float>(); //collects keys from asteroidsDestroyed HashMap
  //the key set of asteroidsDestroyed it's the destruction occurrence time
  for (float t : asteroidsDestroyed.keySet()) {
    //show animation for 1000ms
    float timer = millis() - t;
    if (timer > 1000) {
      expiredAsteroids.add(t);
    } else {
      //Show some segments of asteroid polygon disconnected and rotating on their own centre
      for (PVector[] points : asteroidsDestroyed.get(t)) {
        PVector centroid = calculateCentre(points);
        float alpha = map(timer, 0, 1000, 255, 50);//the more the timer, less alpha
        stroke(0, 255, 0, alpha);
        for (int i=0; i< points.length-1; i+=2) {
          int j=i+1;
          //get the segment lines from the destroyed asteroid polygon and rotate it
          PVector point1 = points[i];
          PVector point2 = points[j];
          PVector[] line = {point1, point2};
          float rotationSpeed =.1*(i%3==0 ? -1:1);
          rotateSegment(line, rotationSpeed);

          //push the lines away from former centroid of asteroid
          for (PVector point : line) {
            PVector d = PVector.sub(centroid, point);//vector from centroid to point
            d.normalize();
            //point.add(d);//blackhole effect
            point.sub(d);
          }
          //show the segment
          line(point1.x, point1.y, point2.x, point2.y);
        }
      }
    }
  }
  //Remove destroyed asteroid from the HashMap
  for (float t : expiredAsteroids) {
    asteroidsDestroyed.remove(t);
  }
}


/*
 * Handle all variables between two colliding asteroid vs ship, and updates the collisionLocation list
 * Update velocities, angular momentum, collision location, and destroy asteroid or ship if applied
 * @param Asteroid rock, Ship ship, ArrayList<PVector> collisionsLocation
 */
void handleAsteroidToShipCollisions(Ship ship, Asteroid rock, ArrayList<PVector> collisionsLocation) {

  //Update Velocities
  PVector tempVelocity = rock.speed;
  rock.updateVelocity(ship.speed, ship.mass);
  ship.updateVelocity(tempVelocity, rock.mass, rock.centre);

  //Update Angular momentum
  rock.updateRotation(ship.mass, ship.speed, ship.centre);

  //Show collision drawing
  rock.colliding = true;
  if (rock.collisionPoint != null && ship.collisionPoint != null) {
    collisionsLocation.add(PVector.add(rock.collisionPoint, ship.collisionPoint).mult(.5));
  }

  //Destroy small asteroid if colliding with ship's shield
  if (ship.forceFieldActive && ship.forceFieldValue > 0 && rock.maxRadius < 50) {
    rock.destroyed=true;
    
    rock.explosionSound();
    //Add points for small asteroid destruction
    HUD.addPoint(10);
  }
  //Weaken big asteroids if colliding with ship's shield
  if (ship.forceFieldActive && ship.forceFieldValue > 0 && rock.maxRadius > 50) {
    ship.forceFieldValue--; //Drain the force field faster when colliding
    //Show collision drawing and remove asteroid life points
    if (rock.life > 0) {
      rock.life--;
      rock.colliding = true;
    }
  }

  //Destroy ship if shield not active
  if (ship.forceFieldActive == false || (ship.forceFieldActive && ship.forceFieldValue < 0)) {
    ship.destroyed=true;
    
    ship.explosionSound();

    //Create a ship hull vertices for destruction animation 
    shipHullVertices = new PVector[ship.vertices.length*2];
    int index=0;
    //duplicating points to create a set of independent segments for each consecutive pair of points
    //Ship = [p1,p2,p3] / shipHullVertices = [p1,p2,p2,p3,p3,p1]
    for (PVector p : ship.vertices) {
      if (index==0) {
        shipHullVertices[index] = new PVector(p.x, p.y);
        shipHullVertices[ship.vertices.length*2-1] = new PVector(p.x, p.y);
        index++;
      } else {
        for (int i=0; i<2; i++) {
          shipHullVertices[index] = new PVector(p.x, p.y);
          index++;
        }
      }
    }
    shipDestructionTimer=time;
  }
}

/*
 * Show destroyed ship explosion
 */
void showDestroyedShipExplosion() {
  if (ship.size()==0) {
    //show animation for 1000ms
    float timer = millis() - shipDestructionTimer;
    if (timer < 5000 || true) {

      //Show segments of ship polygon disconnected and rotating on their own centre
      PVector centroid = calculateCentre(shipHullVertices);
      float alpha = map(timer, 0, 1000, 255, 50);//the more the timer, less alpha
      stroke(0, 255, 0, alpha);

      for (int i=0; i< shipHullVertices.length-1; i+=2) {
        int j=i+1;
        //get the segment lines from the destroyed asteroid polygon and rotate it
        PVector point1 = shipHullVertices[i];
        PVector point2 = shipHullVertices[j];
        PVector[] line = {point1, point2};
        float rotationSpeed =.1*(i%3==0 ? -1:1);
        rotateSegment(line, rotationSpeed);

        //push the lines away from former centroid of asteroid
        for (PVector point : line) {
          PVector d = PVector.sub(centroid, point);//vector from centroid to point
          d.normalize();
          d.mult(.2);
          point.add(d);//blackhole effect
        }
        //show the segment
        line(point1.x, point1.y, point2.x, point2.y);
      }
    }
  }
}
