import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

import 'common.dart';
import 'game_maths.dart';
import 'game_physics.dart';

void main() {
  print('starting web socket server');
  int _id = 0;
  List<dynamic> characters = [];
  const host = '0.0.0.0';
  const port = 8080;

  void fixedUpdate() {
    characters.forEach(updateCharacter);
    updateCollisions(characters);
  }

  Timer updateTimer = Timer.periodic(Duration(milliseconds: 1000 ~/ 60), (timer) {
    fixedUpdate();
  });


  dynamic findCharacterById(int id) {
    return characters.firstWhere((element) => element[keyCharacterId] == id,
        orElse: () {
      throw Exception("character not found with id $id");
    });
  }

  int spawnCharacter(double x, double y) {
    Map<String, dynamic> object = new Map();
    object[keyPositionX] = x;
    object[keyPositionY] = y;
    object[keyCharacterId] = _id;
    object[keyDirection] = directionDown;
    object[keyState] = characterStateIdle;
    characters.add(object);
    _id++;
    return _id - 1;
  }

  spawnCharacter(400, 400);

  var handler = webSocketHandler((webSocket) {

    webSocket.stream.listen((message) {
      dynamic messageObject = jsonDecode(message);
      dynamic command = messageObject[keyCommand];

      switch (command) {
        case commandSpawn:
          var id = spawnCharacter(500, 500);
          Map<String, dynamic> response = Map();
          response[keyCommand] = commandSpawn;
          response[keyCharacterId] = id;
          response[keyCharacters] = characters;
          webSocket.sink.add(jsonEncode(response));
          return;
        case commandUpdate:
          Map<String, dynamic> response = Map();
          response[keyCommand] = commandUpdate;
          response[keyCharacters] = characters;
          if (messageObject[keyCharacterId] != null) {
            int playerId = messageObject[keyCharacterId];
            dynamic playerCharacter = findCharacterById(playerId);
            int direction = messageObject[keyDirection];
            int characterState = messageObject[keyState];
            playerCharacter[keyState] = characterState;
            playerCharacter[keyDirection] = direction;
          }
          webSocket.sink.add(jsonEncode(response));
          return;
        case commandSpawnZombie:
          spawnCharacter(randomBetween(0, 1000), randomBetween(0, 800));
          return;
      }
    });
  });

  shelf_io.serve(handler, host, port).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });
}
