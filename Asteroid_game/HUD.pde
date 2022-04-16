/* HUD class with minimal physics simulation
 * @author Volfegan Geist [Daniel Leite Lacerda]
 * https://github.com/volfegan/Asteroid_game_with_physics
 */

public class HUD {
  float score;
  float forceField;
  float waveCannon;

  public HUD () {
    this.score=0;
    this.forceField=0;
    this.waveCannon=0;
  }

  /*
   * Show the game score in the top middle 
   */
  void scoreBoard() {
    fill(0, 255, 0, 99);
    textSize(50);
    String scoreText = "Score: 100";
    float offsetX = textWidth(scoreText)/2;
    float x = width/2-offsetX;
    float y = 10;
    text("Score: "+(int)this.score, x, y);
  }
  /*
   * Add points to the score
   * @param float points
   */
  void addPoint(float points) {
    this.score+=points;
  }
  /*
   * Score = zero
   */
  void resetScore() {
    this.score=0;
  }

  /*
   * Show the particle wave cannon energy levels on top right screen
   * @param float value
   */
  void waveCannon(float value) {
    fill(0, 255, 0, 99);
    textSize(40);
    String waveCannon = "Wave Cannon: 100";
    float offsetX = textWidth(waveCannon);
    float x = width-20-offsetX;
    float y = 20;
    text("Wave Cannon: "+(int)value, x, y);
  }

  /*
   * Show the force field energy levels on top left screen
   * @param float value
   */
  void forceField(float value) {
    fill(0, 255, 0, 99);
    textSize(40);
    float x = 20;
    float y = 20;
    text("Shield: "+(int)value, x, y);
  }
}
