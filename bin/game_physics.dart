

import 'common.dart';
import 'game_maths.dart';

void updateCollisions(List<dynamic> characters){
  for(int i = 0; i < characters.length; i++){
    dynamic characterI = characters[i];
    for(int j = i + 1; j < characters.length; j++){
      dynamic characterJ = characters[j];
      double distance = distanceBetween(characterI, characterJ);
      if (distance < characterRadius2) {
        double overlap = characterRadius2 - distance;
        double halfOverlap = overlap * 0.5;
        double xDiff = characterI[keyPositionX] - characterJ[keyPositionX];
        double yDiff = characterI[keyPositionY] - characterJ[keyPositionY];
        double mag = magnitude(xDiff, yDiff);
        double ratio = 1.0 / mag;
        double xDiffNormalized = xDiff * ratio;
        double yDiffNormalized = yDiff * ratio;
        double targetX = xDiffNormalized * halfOverlap;
        double targetY = yDiffNormalized * halfOverlap;
        characterI[keyPositionX] += targetX;
        characterI[keyPositionY] += targetY;
        characterJ[keyPositionX] -= targetX;
        characterJ[keyPositionY] -= targetY;
      }
    }
  }
}