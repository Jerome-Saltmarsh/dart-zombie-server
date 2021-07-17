const commandSpawn = 1;
const commandUpdate = 2;
const commandAttack = 3;
const commandSpawnZombie = 4;

const characterStateIdle = 0;
const characterStateWalking = 1;
const characterStateDead = 2;

const directionUp = 0;
const directionUpRight = 1;
const directionRight = 2;
const directionDownRight = 3;
const directionDown = 4;
const directionDownLeft = 5;
const directionLeft = 6;
const directionUpLeft = 7;

const keyFrame = '_f';
const keyPositionX = 'x';
const keyPositionY = 'y';
const keyDirection = 'd';
const keyState = 's';
const keyCommand = 'c';
const keyCharacterId = 'i';
const keyErrorCode = 'error';
const keyRotation = 'r';
const keyCharacters = 'v';
const keyBullets = 'b';
const keyPlayerX = 'px';
const keyPlayerY = 'py';
const keyPlayerDirection = 'pd';
const keyRequestDirection = 'rd';

const errorCodePlayerIdNotFound = 0;

const double characterSpeed = 1.5;
const double bulletRadius = 3;
const double characterRadius = 7;
const double characterRadius2 = characterRadius * 2;
const double characterBulletRadius = characterRadius + bulletRadius;

void updateCharacter(dynamic character) {
  switch (character[keyState]) {
    case characterStateIdle:
      break;
    case characterStateWalking:
      switch (character[keyDirection]) {
        case directionUp:
          character[keyPositionY] -= characterSpeed;
          break;
        case directionUpRight:
          character[keyPositionX] += characterSpeed * 0.5;
          character[keyPositionY] -= characterSpeed * 0.5;
          break;
        case directionRight:
          character[keyPositionX] += characterSpeed;
          break;
        case directionDownRight:
          character[keyPositionX] += characterSpeed * 0.5;
          character[keyPositionY] += characterSpeed * 0.5;
          break;
        case directionDown:
          character[keyPositionY] += characterSpeed;
          break;
        case directionDownLeft:
          character[keyPositionX] -= characterSpeed * 0.5;
          character[keyPositionY] += characterSpeed * 0.5;
          break;
        case directionLeft:
          character[keyPositionX] -= characterSpeed;
          break;
        case directionUpLeft:
          character[keyPositionX] -= characterSpeed * 0.5;
          character[keyPositionY] -= characterSpeed * 0.5;
          break;
      }
  }
}
