# Asteroid game with minimal physics

[![Asteroid game thumbnail](https://github.com/volfegan/Asteroid_game_with_physics/blob/main/inGameIMGs/frame%201251.png)](https://youtu.be/Gjoe6_RhmbU)

Click the image for video of gameplay

The asteroids can collide between themselves and the ship. They all have linear momentum and angular momentum. Depending on how they collide, they may change rotation. All collision are elastic and this is not an accurated physics model. There are references in the code for more precise physics if anyone wants to know how to make soemthing better. The game has a very 8-bit sounds the closest I could do to match the [original sounds of the asteroid game](http://www.classicgaming.cc/classics/asteroids/sounds). I only made 5 sounds for shooting normal bullets, particle wave cannon shot, shield, explosion, and ship's thrusters.

I made this game just to test how well the [GJK algorithm](https://github.com/volfegan/GeometricAlgorithms/tree/master/GJK_collision_detection) can detect collisions with some minimal physics involved (done in Processing v3.5). I didn't create any unit tests for this, testing all while it progressed, adding more components until it got to this point. The GJK algorithm works fine in the simple scope I did for handling the collision detections. That caused some bugs, but I'm satisfied with the results as I was not expecting this to work at all without any refinements. In fact, this is not optimized in any way, and if you are interesting on such a thing, check this book as reference, [Real-Time Collision Detection](http://www.r-5.org/files/books/computers/algo-list/realtime-3d/Christer_Ericson-Real-Time_Collision_Detection-EN.pdf), and my other [geometric algorithms](https://github.com/volfegan/GeometricAlgorithms) repository as it has a bit explored in the subject.

#### Game mechanics:

Controls inputs are A,D [spin the ship] / S [shield] / W [thrusters] / Spacebar [shoot/charge energy] / Enter [new game]. Only one control input action per frame. And while charging the particle wave cannon, little control on other inputs. Destroying a big asteroid will create 2 or 3 small ones from its debris. Big asteroids generate 20 points and need 2 shots to be destroyed, while small ones generate 10 points and need only 1 shot. The ship colliding with activated shields can destroy small asteroids, but only weakens big ones (only one extra shot needed to destroy it).

#### Knowing bugs:
* Sometimes, the particle wave cannon destroys asteroids even without any visible intersection. Probably some weirdness on asteroid mirror-vertices location when they are not warping from one side of the screen to another. Normally occurs after new batch of big asteroids are created. No idea why this happens.
* Sound issues. Sometimes no sound when action is done. I should have done an entire sound class to handle sounds, but I wanted simple and already wasted 3 weeks of my free time coding this game; good enough.
* There can be only one... control input per time. Nothing simutaneous, like turning the ship + shooting. Processing limitations. A better key mapping would solve this, but now it's a feature.
* During space-warping in the screen, sometimes asteroids ignore collision detection. I didn't want to proper handle edge cases on space-warping asteroids, nor did enough tests to discover them. Or have the patience to fix it.
* Asteroids can entangle their polygons with each other. From references I read before, they state there must be some mult-step process in handling the collisions. As right now, after a collision is processed, asteroids gain their new velocity and new position updates. But if that position is still within the other asteroid polygon, they will go back and forth, until something force them to disentangle. One way to handle part of this problem is to check if after the new velocity, the new position is going to be within the other polygon, so we should calculate a previous position, just before the intersection, and redo the "collision" (just update the new velocity and angular momentum on this outside old position). This would cause more processing, possibly some quantum leap shenanigans if not done in small steps, and still would not guarantee not having problems during multiple simultaneous collisions, so... handling collisions is hard.

#### Geometric Algorithms references

Now the actual usefull stuff! The references used on each function are in their header comment.
* Compute the intersection point between two segments: functions  intersectPoint(PVector segmentPoint1, PVector segmentPoint2, 
    PVector segmentPointA, PVector segmentPointB), and outOfRange(PVector p, PVector segmentPointA, PVector segmentPointB) in Bullet class.
* Compute polygon area: function computeMass(PVector[] vertices) in class Asteroid and Ship. I used Area = Mass.
* Compute mass moment of inertia: functions computeMomentOfInertia(PVector[] vertices), and momentOfInertiaOfTriangle(PVector[] triangle) in class Asteroid and Ship.
* Compute polygon centre: function calculateCentre(PVector[] vertices) in class Asteroid and Ship.
* Polygon rotation and angular momentum: functions rotatePoint(PVector point, PVector rotCentre), updateRotation(float mass, PVector velocity, PVector centroid) in Asteroid class, and rotatePoint(PVector point, PVector rotCentre, float rotationSpeed), and rotation(boolean rotateShip) in Ship class.
* Elastic collision linear momentum for velocity updates: functions updateVelocity(PVector v, float mass) in Asteroid class, and updateVelocity(PVector v, float mass, PVector centroid) in Ship class.
* Screen space-warping (toroidal mapping) without artifacts: function warpCoordinates(int[] warpCoordinatesMap, PVector point), warpCoordinates(PVector[] vertices),  warpOperations(PVector[] vertices), findIndexOfExtremePoints(), and updatePosition() in class Asteroid and Ship.

Good luck space-cadets! Use for reference!
     
         Space folding!
           .      .   . .   .  +   .    .         
                             .       .      .
              .     *
         .       *               . .     +  *
            .               :.       +   . 
          .  .   .  + .                         .  *
               _____________________     .
              / +.         .   *    "-_           .
             /   .- Y -.               \      +
            /   : \ | / ;    +   .      \      .
           /  +  '-___-'   .   .    + .  \
          /_______________________________\    .     .
               ____| |________________.J' #L
              /.+  J L   .   .     . +..    \    *  .   +
             /    / ! \     +   .            L
            /   :'  x  ':         :     .    F      .
           / .   '-___-'  +..  .     *      /    .
          /______________________________-="
                  .    * . . .  .              +     .
          . .     .      .            *
                .      .   .        ! /       + .   .
           *             .        - O -   .
               .     .          . / |
          +             .  ..             +  .
               .   .  *   .      +..  .          *

