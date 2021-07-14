import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

import 'common.dart';

void main() {
  print('starting web socket server');

  List<dynamic> _characters = [];

  void fixedUpdate() {
    _characters.forEach(updateCharacter);
  }

  const host = '0.0.0.0';
  const port = 8080;
  Timer updateTimer =
      Timer.periodic(Duration(milliseconds: 1000 ~/ 60), (timer) {
    fixedUpdate();
  });
  int _id = 0;

  void pause() {
    if (!updateTimer.isActive) return;
    updateTimer.cancel();
  }

  void resume() {
    if (updateTimer.isActive) return;

    updateTimer = Timer.periodic(Duration(milliseconds: 1000 ~/ 60), (timer) {
      fixedUpdate();
    });
  }

  dynamic findCharacterById(int id) {
    return _characters.firstWhere((element) => element[keyId] == id, orElse: (){
      throw Exception("character not found with id $id");
    });
  }

  int spawnCharacter() {
    Map<String, dynamic> object = new Map();
    object[keyPositionX] = 500;
    object[keyPositionY] = 400;
    object[keyId] = _id;
    object[keyState] = characterStateIdle;
    _characters.add(object);
    _id++;
    return _id - 1;
  }

  var handler = webSocketHandler((webSocket) {
    webSocket.stream.listen((message) {

      Map<String, dynamic> response = Map();
      response[keyCommand] = commandUpdate;
      response[keyValue] = _characters;
      webSocket.sink.add(jsonEncode(response));

      if (message == commandUpdate) return;

      dynamic messageObject = jsonDecode(message);
      dynamic command = messageObject[keyCommand];

      if (command == commandSpawn) {
        var id = spawnCharacter();
        Map<String, dynamic> response = Map();
        response[keyCommand] = commandId;
        response[keyValue] = id;
        webSocket.sink.add(jsonEncode(response));
        return;
      }

      dynamic id = messageObject[keyId];

      if (id == null) return;

      dynamic character = findCharacterById(id);

      switch (command) {
        case commandMoveUp:
          character[keyState] = characterStateWalkingUp;
          return;
        case commandMoveRight:
          character[keyState] = characterStateWalkingRight;
          return;
        case commandMoveDown:
          character[keyState] = characterStateWalkingDown;
          return;
        case commandMoveLeft:
          character[keyState] = characterStateWalkingLeft;
          return;
        case commandIdle:
          character[keyState] = characterStateIdle;
          return;
        case commandPause:
          pause();
          return;
        case commandResume:
          resume();
          return;
      }
    });
  });

  shelf_io.serve(handler, host, port).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });
}
