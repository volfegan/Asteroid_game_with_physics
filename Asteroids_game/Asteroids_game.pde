/*
 * @author Volfegan Geist [Daniel Leite Lacerda]
 * https://github.com/volfegan/Asteroid_game_with_physics
 */

// Controls:
//     | w |
// | a | s | d |
// [ space bar ]
//
// A,D [spin the ship] / S [shield] / W [thrusters] / Spacebar [shoot/charge energy] / Enter [new game]
// Only one control input action/frame. And while charging the wave cannon, little control on other inputs

//Resources and references
//https://www.youtube.com/watch?v=QgDR8LrRZhk

import java.util.Collections;
import java.util.HashMap;
import processing.sound.*;

//Sound generator variables
BrownNoise noiseB;
WhiteNoise noiseW;
PinkNoise noiseP;
Pulse pulse;
SawOsc saw;
SinOsc sine;
SqrOsc square;
TriOsc triOsc;
// Create the sound envelopes
Env[] envExplosionAsteroid = new Env[5];
Env[] envExplosionShip = new Env[5];
Env envShield;
Env envThruster;
Env[] envWaveCannon = new Env[5];
Env[] envShot = new Env[5];


Asteroid asteroid;//for testing

float deltaTime=0, time=0, noAsteroidsTimer=0, shipDestructionTimer=0;

boolean INVULNERABLE = false; //cheat easy game
ArrayList<Ship> ship = new ArrayList<Ship>();
PVector[] shipHullVertices;//used to store the ship polygon for its destruction animation

ArrayList<Bullet> bullets = new ArrayList<Bullet>();

ArrayList<Asteroid> asteroids = new ArrayList<Asteroid>();
boolean noAsteroidsTimerCheck=false;
//key = time of collision, value = list of collisions location
HashMap<Float, ArrayList<PVector>> collisionSparks = new HashMap<Float, ArrayList<PVector>>();
//key = time of collision, value = asteroid vertices
HashMap<Float, ArrayList<PVector[]>> asteroidsDestroyed = new HashMap<Float, ArrayList<PVector[]>>();

HUD HUD; //display score, particle wave cannon energy level, ship's shield energy level

PFont gameFont;

boolean spaceBarReleased=false;//control shooting (particle wave cannon charge)
void keyReleased() {
  if (key == ' ') {
    spaceBarReleased=true;
  }
}

void setup() {
  size(1280, 720);
  stroke(0, 255, 0);
  rectMode(CENTER);
  noFill();
  
  //Init sound variables
  noiseB = new BrownNoise(this);
  noiseW = new WhiteNoise(this);
  noiseP = new PinkNoise(this);
  triOsc = new TriOsc(this); 
  saw = new SawOsc(this);
  saw = new SawOsc(this);
  square = new SqrOsc(this);
  //Init sound envelopes
  envShield = new Env(this);
  envThruster = new Env(this);
  for (int i=0; i<5; i++) {
    envExplosionAsteroid[i] = new Env(this);
    envExplosionShip[i] = new Env(this);
    envWaveCannon[i] = new Env(this);
    envShot[i] = new Env(this);
  }

  gameFont = createFont("Ubuntu Mono", 40);
  textFont(gameFont);
  textAlign(LEFT, TOP);


  //Create HUD
  HUD = new HUD();

  //Create ship
  ship.add(new Ship(width/2, height/2));
  //println("Ship:\nMass="+ship.mass);
  //println("Moment of inertia="+ship.moment_of_inertia+"\n");

  //Create asteroids
  PVector doNotSpawnHere = ship.get(0).centre;
  createAsteroids(asteroids, doNotSpawnHere);

  //asteroid = new Asteroid(300, 300, 100, (int)random(9, 18));//for testing
  //asteroids.add(asteroid);
  //asteroid.speed = new PVector();//zero velocity
  //println("Mass="+asteroid.mass);
  //println("Moment of inertia="+asteroid.moment_of_inertia);
}


void draw() {
  clear();
  deltaTime = millis() - time; //Elapsed time between frames
  time = millis(); //current time

  /*
  //Asteroid class
   */

  Collections.shuffle(asteroids); //suffle to better handle the collisions

  //Update asteroids variable status
  ArrayList<PVector[]> asteroidsDestroyedPolygonCollector = new ArrayList<PVector[]>();
  for (Asteroid asteroid : asteroids) {
    //update not destroyed asteroids status
    if (asteroid.destroyed == false) {

      asteroid.updatePosition();
      asteroid.rotation();
      asteroid.render();
      //
    } else {
      //Collects destroyed asteroid polygons to show their destruction later
      asteroidsDestroyedPolygonCollector.add(asteroid.vertices);
      if (asteroid.warping) {
        asteroidsDestroyedPolygonCollector.add(asteroid.mirrorVertices);
      }
    }
  }
  //Collect destroyed asteroid into HashMap
  asteroidsDestroyed.put(time, asteroidsDestroyedPolygonCollector);

  //Remove destroyed asteroid from the asteroids arrayList & create new asteroids if conditions apply 
  for (int i = asteroids.size() - 1; i >= 0; i--) {
    Asteroid asteroid = asteroids.get(i);
    if (asteroid.destroyed) {

      asteroids.remove(i);

      //Create 2 or 3 new asteroids if destroyed asteroid size was big
      if (asteroid.maxRadius > 50) {
        //get former points of asteroid polygon and generate new asteroid there
        int polygonSize = asteroid.vertices.length;
        int count=(int)random(0, 1.5);//start with 0 or 1
        for (int index=0; index<polygonSize; index+=polygonSize/3) {
          count++;
          if (count <=3) {
            PVector newLoc = asteroid.vertices[index];
            float radius = (asteroid.maxRadius/2 < 50) ? asteroid.maxRadius/2 : 50;
            asteroids.add(new Asteroid(newLoc.x, newLoc.y, radius, 2*polygonSize/3));
          }
        }
      }
    }
  }
  //If no astreroids on screen, create new batch
  if (asteroids.size() == 0) {
    //Get time of no asteroids in the screen
    if (noAsteroidsTimerCheck==false) {
      noAsteroidsTimer = time;
      noAsteroidsTimerCheck=true;
    }
    //Get current ship location
    PVector doNotSpawnHere = new PVector();
    if (ship.size()>0) {
      doNotSpawnHere = ship.get(0).centre;
    }
    //wait 3s to recreate asteroids
    if (millis()-noAsteroidsTimer > 3000) {
      createAsteroids(asteroids, doNotSpawnHere);
      noAsteroidsTimerCheck=false;
    }
  }

  //Testing: DESTROY asteroids randomly
  //for (Asteroid asteroid : asteroids)
  //  if (random(1) < .015) asteroid.destroyed = true;


  //Handle collisions between asteroid vs asteroid
  ArrayList<PVector> collisionsLocation = new ArrayList<PVector>();
  //Best loop for non-repeating pairs (https://youtu.be/75Cbkoo4Gwg?t=1108)
  for (int i = 0; i < asteroids.size()-1; i++) {
    for (int j = i + 1; j < asteroids.size(); j++) {
      Asteroid rock1 = asteroids.get(i);
      Asteroid rock2 = asteroids.get(j);

      if ((gfk_detectCollision(rock1.vertices, rock2.vertices))
        ||
        (rock2.warping && gfk_detectCollision(rock1.vertices, rock2.mirrorVertices))
        ||
        (rock1.warping && gfk_detectCollision(rock1.mirrorVertices, rock2.vertices))
        ||
        (rock1.warping && rock2.warping && gfk_detectCollision(rock1.mirrorVertices, rock2.mirrorVertices))
        ) {

        handleAsteroidCollisions(rock1, rock2, collisionsLocation);
      }
    }
  }
  //Collect new asteroid collisions location
  collisionSparks.put(time, collisionsLocation);

  //Collision animation on asteroids (asteroid glows)
  for (Asteroid rock : asteroids) {
    rock.renderCollision();
    if (rock.colliding == true) {
      rock.colliding = false;
    }
  }
  //Show sparks between colliding asteroids
  showCollisionSparks();

  //Show destroyed asteroid explosion
  showDestroyedAsteroidExplosion();


  /*
  //Ship class
   */
  //Update ship variable status
  for (Ship ship : ship) {
    ship.controlStatus();//handles force field status, ship's rotation status, thrusters, shooting
    ship.updatePosition();
    ship.render();
    ship.renderThrusters();
    ship.renderForceField();
    ship.renderWaveCannonCharging();

    //Handle collisions between ship vs asteroid
    for (int i = 0; i < asteroids.size(); i++) {
      Asteroid rock = asteroids.get(i);

      if ((gfk_detectCollision(rock.vertices, ship.vertices))
        ||
        (ship.warping && gfk_detectCollision(rock.vertices, ship.mirrorVertices))
        ||
        (rock.warping && gfk_detectCollision(rock.mirrorVertices, ship.vertices))
        ||
        (rock.warping && ship.warping && gfk_detectCollision(rock.mirrorVertices, ship.mirrorVertices))
        ) {
        handleAsteroidToShipCollisions(ship, rock, collisionsLocation);
      }
    }
  }

  //Show destroyed ship explosion
  showDestroyedShipExplosion();

  //Remove ship if destroyed
  for (int i = ship.size() - 1; i >= 0; i--) {
    Ship s = ship.get(i);
    if (s.destroyed && !INVULNERABLE) {
      ship.remove(i); //bye bye ship
    }
  }


  /*
  //Bullet class
   */
  if (ship.size() > 0) {
    Ship s = ship.get(0);

    //Add bullets when shooting
    if (s.shooting) {
      bullets.add(new Bullet(s.forwardPoint.x, s.forwardPoint.y, s.heading));
    }

    //Detect particle wave cannon activation and create a wave cannon bullet
    if (s.shootWaveCannon) {
      Bullet ParticleWaveCannon = new Bullet(s.forwardPoint.x, s.forwardPoint.y, s.heading);
      ParticleWaveCannon.waveCannonActivation();
      bullets.add(ParticleWaveCannon);
    }
  }

  //Update bullets variable status
  for (Bullet bullet : bullets) {
    bullet.updatePosition();
    bullet.waveCannonStatus();
    bullet.render();

    //Particle Wave Cannon shooting animation
    if (ship.size() > 0) {
      Ship s = ship.get(0);
      if (bullet.waveCannonActive) {
        bullet.updateParticleWaveCannonPolygon(s.forwardPoint, s.heading);
        bullet.renderParticleWaveCannon();
        s.waveCannonValue = 0; //do not recharge while shooting
      }
    }

    //Handle collisions between asteroids vs bullets/particle wave cannon
    for (Asteroid rock : asteroids) {

      if ((gfk_detectCollision(rock.vertices, bullet.particle)) ||
        (rock.warping && gfk_detectCollision(rock.mirrorVertices, bullet.particle)) ||
        (bullet.waveCannonActive && gfk_detectCollision(rock.vertices, bullet.waveCannon)) ||
        (bullet.waveCannonActive && gfk_detectCollision(rock.mirrorVertices, bullet.waveCannon))
        ) {

        //Normal bullet or a wave cannon hit a asteroid
        if (bullet.waveCannonActive || rock.life <= 0) {
          //Destroy asteroid
          rock.destroyed = true;

          rock.explosionSound();

          //Add points for small asteroid destruction
          if (rock.maxRadius < 50) {
            HUD.addPoint(10);
          }
          //Add points for big asteroid destruction
          if (rock.maxRadius > 50) {
            HUD.addPoint(20);
          }
        } else {
          //Show collision drawing and remove asteroid life points
          rock.life--;
          rock.colliding = true;
        }
        //Destroye normal bullets
        if (!bullet.waveCannonActive) bullet.destroyed = true;
      }
    }
  }

  //Remove any bullet outside the screen or destroyed by collision
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    if (b.destroyed) {
      bullets.remove(i);
    }
  }



  /*
  //HUD class
   */

  //Score
  HUD.scoreBoard();

  float ShieldValue=0;
  float waveCannonValue=0;
  if (ship.size() > 0) {
    Ship s = ship.get(0);
    ShieldValue = s.forceFieldValue;
    waveCannonValue = s.waveCannonValue;
  }
  //Force Field energy galge
  HUD.forceField(ShieldValue);

  //Particle Wave cannon energy galge
  HUD.waveCannon(waveCannonValue);


  //Restart Game
  if (keyPressed) {
    if (key == ENTER) {
      //Delete old ship and create new one
      ship.clear();
      ship.add(new Ship(width/2, height/2));

      //Delete everything
      bullets.clear();
      asteroids.clear();
      asteroidsDestroyed.clear();
      collisionSparks.clear();

      //Create new asteroids batch
      PVector doNotSpawnHere = ship.get(0).centre;
      createAsteroids(asteroids, doNotSpawnHere);

      //Erase Score;
      HUD.resetScore();

      //for testing
      //asteroid = new Asteroid(300, 300, 100, (int)random(9, 18));
      //asteroids.add(asteroid);
      //asteroid.speed = new PVector();//zero velocity
    }
  }
}
