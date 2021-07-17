import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

import 'common.dart';
import 'game_maths.dart';
import 'game_physics.dart';

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
      bullet[keyPositionX] -= cos(bulletRotation + (pi * 0.5)) * 3;
      bullet[keyPositionY] -= sin(bulletRotation + (pi * 0.5)) * 3;

      for (int j = 0; j < characters.length; j++) {
        if (bullet[keyCharacterId] == characters[j][keyCharacterId]) continue;
        double dis = distanceBetween(characters[j], bullet);
        if (dis < characterBulletRadius) {
          bullets.removeAt(i);
          i--;
          characters[j][keyState] = characterStateDead;
          break;
        }
      }
    }
    ;
  }

  void fixedUpdate() {
    characters.forEach(updateCharacter);
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

  int spawnCharacter(double x, double y) {
    Map<String, dynamic> object = new Map();
    object[keyPositionX] = x;
    object[keyPositionY] = y;
    object[keyCharacterId] = id;
    object[keyDirection] = directionDown;
    object[keyState] = characterStateIdle;
    characters.add(object);
    id++;
    return id - 1;
  }

  spawnCharacter(400, 400);

  var handler = webSocketHandler((webSocket) {
    void sendToClient(dynamic response) {
      webSocket.sink.add(jsonEncode(response));
    }

    webSocket.stream.listen((message) {
      dynamic messageObject = jsonDecode(message);
      dynamic command = messageObject[keyCommand];

      switch (command) {
        case commandSpawn:
          var id = spawnCharacter(500, 500);
          Map<String, dynamic> response = Map();
          response[keyCharacterId] = id;
          response[keyCharacters] = characters;
          response[keyBullets] = bullets;
          sendToClient(response);
          return;
        case commandUpdate:
          Map<String, dynamic> response = Map();
          response[keyCommand] = commandUpdate;
          response[keyCharacters] = characters;
          response[keyBullets] = bullets;
          if (messageObject[keyCharacterId] != null) {
            int playerId = messageObject[keyCharacterId];
            dynamic playerCharacter = findCharacterById(playerId);
            if (playerCharacter == null) {
              response[keyErrorCode] = errorCodePlayerIdNotFound;
            } else
            if (playerCharacter[keyState] != characterStateDead) {
              int direction = messageObject[keyDirection];
              int characterState = messageObject[keyState];
              playerCharacter[keyState] = characterState;
              playerCharacter[keyDirection] = direction;
            }
          }
          sendToClient(response);
          return;
        case commandSpawnZombie:
          spawnCharacter(randomBetween(0, 1000), randomBetween(0, 800));
          return;
        case commandAttack:
          if (messageObject[keyCharacterId] == null) return;
          int playerId = messageObject[keyCharacterId];
          dynamic playerCharacter = findCharacterById(playerId);
          Map<String, dynamic> bullet = Map();
          bullet[keyPositionX] = playerCharacter[keyPositionX];
          bullet[keyPositionY] = playerCharacter[keyPositionY];
          bullet[keyRotation] = messageObject[keyRotation];
          bullet[keyFrame] = 0;
          bullet[keyCharacterId] = playerId;
          bullets.add(bullet);
      }
    });
  });

  shelf_io.serve(handler, host, port).then((server) {
    print('Serving at wss://${server.address.host}:${server.port}');
  });
}
