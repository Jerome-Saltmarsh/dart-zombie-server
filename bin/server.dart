import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

import 'character_utils.dart';
import 'common.dart';
import 'game_maths.dart';
import 'game_physics.dart';
import 'variables.dart';

void main() {
  print('starting web socket server');
  int id = 0;
  List<dynamic> characters = [];
  List<dynamic> bullets = [];
  const host = '0.0.0.0';
  const port = 8080;

  void updateBullets() {
    for (int i = 0; i < bullets.length; i++) {
      dynamic bullet = bullets[i];
      bullet[keyFrame]++;

      if (bullet[keyFrame] > 300) {
        bullets.removeAt(i);
        i--;
        continue;
      }
      double bulletRotation = bullet[keyRotation];
      bullet[keyPositionX] -= cos(bulletRotation + (pi * 0.5)) * 6;
      bullet[keyPositionY] -= sin(bulletRotation + (pi * 0.5)) * 6;

      for (int j = 0; j < characters.length; j++) {
        if (bullet[keyCharacterId] == characters[j][keyCharacterId]) continue;
        if (isDead(characters[j])) continue;
        double dis = distanceBetween(characters[j], bullet);
        if (dis < characterBulletRadius) {
          bullets.removeAt(i);
          i--;
          characters[j][keyState] = characterStateDead;
          characters[j][keyFrameOfDeath] = frame;
          break;
        }
      }
    }
  }

  void updateCharacters() {
    for (int i = 0; i < characters.length; i++) {
      dynamic character = characters[i];

      // TODO Remove this hack
      if (character[keyPositionX] == double.nan) {
        character[keyPositionX] = 0;
        character[keyPositionY] = 0;
      }

      if (isHuman(character) && connectionExpired(character)) {
        characters.removeAt(i);
        i--;
        continue;
      }

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
          break;
        case characterStateDead:
          if (frame - character[keyFrameOfDeath] > 120) {
            if (isNpc(character)) {
              characters.removeAt(i);
              i--;
            } else {
              character[keyState] = characterStateIdle;
              setPosition(character, x: 0, y: 0);
            }
          }
      }
    }
  }

  void fixedUpdate() {
    frame++;
    updateCharacters();
    updateCollisions(characters);
    updateBullets();
  }

  Timer.periodic(Duration(milliseconds: 1000 ~/ 60), (timer) {
    fixedUpdate();
  });

  dynamic findCharacterById(int id) {
    return characters.firstWhere((element) => element[keyCharacterId] == id,
        orElse: () {
      return null;
    });
  }

  spawnCharacter(double x, double y, {String name = "", bool npc = false}) {
    if (x == double.nan) {
      throw Exception("x is nan");
    }
    Map<String, dynamic> character = new Map();
    character[keyPositionX] = x;
    character[keyPositionY] = y;
    character[keyCharacterId] = id;
    character[keyDirection] = directionDown;
    character[keyState] = characterStateIdle;
    character[keyType] = npc ? typeNpc : typeHuman;
    if (name != "") {
      character[keyPlayerName] = name;
    }
    if (!npc) {
      character[keyLastUpdateFrame] = frame;
    }
    characters.add(character);
    id++;
    return character;
  }

  spawnCharacter(100, 100, npc: true);

  void spawnRandomZombie() {
    double r = 500;
    spawnCharacter(randomBetween(-r, r), randomBetween(-r, r), npc: true);
  }

  var handler = webSocketHandler((webSocket) {
    void sendToClient(dynamic response) {
      webSocket.sink.add(jsonEncode(response));
    }

    void handleCommandSpawn(dynamic request) {
      var character =
          spawnCharacter(0, 0, name: request[keyPlayerName], npc: false);
      Map<String, dynamic> response = Map();
      response[keyCharacterId] = getId(character);
      response[keyCharacters] = characters;
      response[keyBullets] = bullets;
      sendToClient(response);
      return;
    }

    void onEvent(requestString) {
      dynamic request = jsonDecode(requestString);
      switch (request[keyCommand]) {
        case commandSpawn:
          handleCommandSpawn(request);
          return;
        case commandUpdate:
          Map<String, dynamic> response = Map();
          response[keyCommand] = commandUpdate;
          response[keyCharacters] = characters;
          response[keyBullets] = bullets;
          if (request[keyCharacterId] != null) {
            int playerId = request[keyCharacterId];
            dynamic playerCharacter = findCharacterById(playerId);
            if (playerCharacter == null) {
              handleCommandSpawn(request);
              return;
            } else if (playerCharacter[keyState] != characterStateDead) {
              int direction = request[keyDirection];
              int characterState = request[keyState];
              playerCharacter[keyState] = characterState;
              playerCharacter[keyDirection] = direction;
              playerCharacter[keyLastUpdateFrame] = frame;
            }
          }
          sendToClient(response);
          return;
        case commandSpawnZombie:
          spawnRandomZombie();
          return;
        case commandAttack:
          if (request[keyCharacterId] == null) return;
          int playerId = request[keyCharacterId];
          dynamic playerCharacter = findCharacterById(playerId);
          if (playerCharacter == null) return;
          if (isDead(playerCharacter)) return;
          Map<String, dynamic> bullet = Map();
          bullet[keyPositionX] = playerCharacter[keyPositionX];
          bullet[keyPositionY] = playerCharacter[keyPositionY];
          bullet[keyRotation] = request[keyRotation];
          bullet[keyFrame] = 0;
          bullet[keyCharacterId] = playerId;
          bullets.add(bullet);
      }
    }

    // onEvent
    webSocket.stream.listen(onEvent);
  });

  shelf_io.serve(handler, host, port).then((server) {
    print('Serving at wss://${server.address.host}:${server.port}');
  });
}
