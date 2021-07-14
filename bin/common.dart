const commandIdle = -1;
const commandMoveUp = 0;
const commandMoveRight = 1;
const commandMoveDown = 2;
const commandMoveLeft = 3;
const commandSpawn = 4;
const commandUpdate = 5;
const commandId = 6;
const commandPause = 7;
const commandResume = 8;
const commandRestart = 9;

const characterStateIdle = 0;
const characterStateWalkingUp = 1;
const characterStateWalkingRight = 2;
const characterStateWalkingDown = 3;
const characterStateWalkingLeft = 4;

const keyPositionX = 'x';
const keyPositionY = 'y';
const keyState = 's';
const keyCommand = 'c';
const keyId = 'i';
const keyValue = 'v';

const double characterSpeed = 5;

void updateCharacter(dynamic character) {
  switch (character[keyState]) {
    case characterStateIdle:
      break;
    case characterStateWalkingDown:
      character[keyPositionY] += characterSpeed;
      break;
    case characterStateWalkingUp:
      character[keyPositionY] -= characterSpeed;
      break;
    case characterStateWalkingLeft:
      character[keyPositionX] -= characterSpeed;
      break;
    case characterStateWalkingRight:
      character[keyPositionX] += characterSpeed;
      break;
  }
}

