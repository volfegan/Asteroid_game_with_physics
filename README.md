# Asteroid game with minimal physics

I made this game just to test how good the [GJK algorithm](https://github.com/volfegan/GeometricAlgorithms/tree/master/GJK_collision_detection) can handle collisions with some minimal physics involved. I certainaly didn't create any unit tests for this, testing all while it progressed, adding more components until it got to this point. I can assert the GJK works fine, and this game has some bugs, but I'm satisfied.

* Game mechanics:

Controls inputs are A,D [spin the ship] / S [shield] / W [thrusters] / Spacebar [shoot/charge energy] / Enter [new game]. Only one control input action per frame. And while charging the particle wave cannon, little control on other inputs. Big asteroids generate 20 points and need 2 shots to be destroyed, while small ones generate 10 points and need only 1 shot. The ship colliding with shields activate can only destroy small asteroids, but weakens big ones (only one extra shot needed to destroy it). The game has very 8-bit sounds the closest I could do to the [original sounds of the asteroid game](http://www.classicgaming.cc/classics/asteroids/sounds).

* 
