import 'dart:math';
import 'common.dart';

const double degreesToRadions = 0.0174533;
const double radionsToDegrees =  57.29578;
final Random random = Random();

class Vector2 {
  double x;
  double y;
  Vector2(this.x, this.y);
}

double randomBetween(num a, num b){
  return (random.nextDouble() * (b - a)) + a;
}

double magnitude(double a, double b){
  return sqrt((a * a) + (b * b));
}

double distanceBetween(dynamic characterA, dynamic characterB){
  double xDiff = characterA[keyPositionX] - characterB[keyPositionX];
  double yDiff = characterA[keyPositionY] - characterB[keyPositionY];
  return magnitude(xDiff, yDiff);
}

double abs(double value){
  if(value < 0) return -value;
  return value;
}

// utility methods
int millisecondsSince(DateTime value){
  return durationSince(value).inMilliseconds;
}

Duration durationSince(DateTime value){
  return DateTime.now().difference(value);
}

Vector2 convertRadionsToVector(num radions){
  num r = radions - (pi * 0.5);
  return Vector2(cos(r), sin(r));
}

double radionsBetweenObject(dynamic a, dynamic b) {
  return convertVectorToDegrees(a['x'] - b['x'], b['y'] - a['y']) * degreesToRadions;
}

double radionsBetween(double aX, double aY, double bX, double bY) {
  return convertVectorToDegrees(aX - bX, bY - aY) * degreesToRadions;
}

double convertVectorToDegrees(double x, double y) {
  if (x < 0)
  {
    return 360 - (atan2(x, y) * radionsToDegrees * -1);
  }
  return atan2(x, y) * radionsToDegrees;
}

