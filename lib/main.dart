import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:math';

void main() => runApp(FlutterDefense());

class FlutterDefense extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Defense',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FlutterDefensePage(),
    );
  }
}

class FlutterDefensePage extends StatefulWidget {
  @override
  FlutterDefensePageState createState() => FlutterDefensePageState();
}

enum GameState { FIRST_TIME, END_OF_GAME, STARTED }

class Position {
  double x;
  double y;

  Position(this.x, this.y);

  double distanceSquared(Position other) =>
      (other.x - this.x) * (other.x - this.x) +
      (other.y - this.y) * (other.y - this.y);
}

class Velocity {
  double dx;
  double dy;

  Velocity({this.dx, this.dy});

  get magnitude => sqrt(dx * dx + dy * dy);
}

enum Type {
  DART,
  GOOGLE,
  FACEBOOK,
  MICROSOFT,
  JAVASCRIPT,
}

class GameItem {
  Position pos;
  Velocity v;
  Type type;

  GameItem({this.pos, this.v, this.type});
}

class IntRange {
  final int start;
  final int end;

  const IntRange(this.start, this.end);
}

class Round {
  final int generateTimeTicks;
  final IntRange generateCount;
  final RangeValues generateVelocityMagnitude;

  const Round(
      {this.generateTimeTicks,
      this.generateCount,
      this.generateVelocityMagnitude});
}

const timerTickTime = Duration(milliseconds: 1);
const gameItemSize = 50.0;

const firstRound = Round(
    generateTimeTicks: 500,
    generateCount: IntRange(1, 1),
    generateVelocityMagnitude: RangeValues(0.35, 0.35));
const secondRound = Round(
    generateTimeTicks: 600,
    generateCount: IntRange(1, 3),
    generateVelocityMagnitude: RangeValues(0.4, 0.45));
const thirdRound = Round(
    generateTimeTicks: 600,
    generateCount: IntRange(2, 3),
    generateVelocityMagnitude: RangeValues(0.3, 0.5));

const thirdRoundTimeSeconds = 3 * 60;
const secondRoundTimeSeconds = 1 * 60;

const flutterLogoSize = 50.0;
const fatalDistance = flutterLogoSize / 2;

const initLivesCount = 10;

Round getCurrentRound(DateTime start) {
  final now = DateTime.now();
  final diff = now.difference(start);

  if (diff.inSeconds > thirdRoundTimeSeconds) return thirdRound;
  if (diff.inSeconds > secondRoundTimeSeconds) return secondRound;
  return firstRound;
}

String getCurrentRoundTitle(DateTime start) {
  final now = DateTime.now();
  final diff = now.difference(start);

  if (diff.inSeconds > thirdRoundTimeSeconds) return "3";
  if (diff.inSeconds > secondRoundTimeSeconds) return "2";
  return "1";
}

bool isFlutterLinked(Type type) => type == Type.DART || type == Type.GOOGLE;

ImageProvider getTypeImage(Type type) {
  switch (type) {
    case Type.DART:
      return AssetImage("assets/dart.png");
    case Type.GOOGLE:
      return AssetImage("assets/google.png");
    case Type.FACEBOOK:
      return AssetImage("assets/facebook.png");
    case Type.MICROSOFT:
      return AssetImage("assets/microsoft.png");
    case Type.JAVASCRIPT:
      return AssetImage("assets/javascript.png");
    default:
      throw Exception("Invalid type.");
  }
}

GameItem generateGameItem(double maxX, double maxY,
    RangeValues velocityMagnitudeRange, Random random) {
  // side: 0 = top, 1 = right, 2 = bottom, 3 = left
  int side = random.nextInt(4);
  Position center =
      Position(maxX / 2 - flutterLogoSize / 2, maxY / 2 - flutterLogoSize / 2);

  double velocityMagnitude = velocityMagnitudeRange.start +
      random.nextDouble() *
          (velocityMagnitudeRange.end - velocityMagnitudeRange.start);
  double x, y;

  if (side == 0) {
    x = random.nextDouble() * maxX;
    y = -gameItemSize;
  } else if (side == 1) {
    x = maxX + gameItemSize;
    y = random.nextDouble() * maxY;
  } else if (side == 2) {
    x = random.nextDouble() * maxX;
    y = maxY + gameItemSize;
  } else if (side == 3) {
    x = -gameItemSize;
    y = random.nextDouble() * maxY;
  }

  Velocity v = Velocity(dx: center.x - x, dy: center.y - y);

  double velocityCoeff = velocityMagnitude / v.magnitude;

  v.dx *= velocityCoeff;
  v.dy *= velocityCoeff;

  Type type = Type.values[random.nextInt(Type.values.length)];

  return GameItem(pos: Position(x, y), v: v, type: type);
}

class FlutterDefensePageState extends State<FlutterDefensePage> {
  DateTime _startTime = DateTime.now();
  int _lives = initLivesCount;
  int _score = 0;
  GameState _gameState = GameState.FIRST_TIME;
  List<GameItem> _gameItems = <GameItem>[];

  Timer _timer;
  Random _random = new Random();

  void onTimerTick(Timer timer) {
    Round round = getCurrentRound(_startTime);
    double maxX = MediaQuery.of(context).size.width;
    double maxY = MediaQuery.of(context).size.height;
    GameItem gameItemGenerator(int i) =>
        generateGameItem(maxX, maxY, round.generateVelocityMagnitude, _random);
    List<GameItem> generatedItems = timer.tick % round.generateTimeTicks == 0
        ? List.generate(
            round.generateCount.start +
                _random.nextInt(
                    round.generateCount.end - round.generateCount.start + 1),
            gameItemGenerator)
        : <GameItem>[];
    Position center = Position(
        maxX / 2 - flutterLogoSize / 2, maxY / 2 - flutterLogoSize / 2);

    if (generatedItems.length == 0 && _gameItems.length == 0) return;

    setState(() {
      _gameItems.addAll(generatedItems);
      _gameItems.forEach((i) {
        i.pos.x += i.v.dx;
        i.pos.y += i.v.dy;
      });
      final badCount = _gameItems
          .where((item) =>
              center.distanceSquared(item.pos) <=
                  fatalDistance * fatalDistance &&
              !isFlutterLinked(item.type))
          .length;
      _gameItems = _gameItems
          .where((i) =>
              center.distanceSquared(i.pos) > fatalDistance * fatalDistance)
          .toList();
      _lives -= badCount;
    });
  }

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(timerTickTime, onTimerTick);
  }

  List<Widget> _buildGameItems() {
    return _gameItems
        .asMap()
        .map((index, item) {
          return MapEntry(
              index,
              Positioned(
                  left: item.pos.x,
                  top: item.pos.y,
                  child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (!isFlutterLinked(item.type)) {
                            _score += 1;
                          } else
                            _lives -= 1;
                          _gameItems.removeAt(index);
                        });
                      },
                      child: Image(
                        image: getTypeImage(item.type),
                        width: gameItemSize,
                        height: gameItemSize,
                      ))));
        })
        .values
        .toList();
  }

  List<Widget> _buildStackChildren() {
    if (_gameState == GameState.FIRST_TIME) {
      return <Widget>[
        Center(
            child: RaisedButton(
          child: Text("Начать игру"),
          onPressed: () {
            setState(() {
              _startTime = DateTime.now();
              _gameState = GameState.STARTED;
            });
          },
        ))
      ];
    } else if (_gameState == GameState.STARTED) {
      final stackChildren = <Widget>[
        Positioned(
            left: MediaQuery.of(context).size.width / 2 - flutterLogoSize / 2,
            top: MediaQuery.of(context).size.height / 2 - flutterLogoSize / 2,
            child: FlutterLogo(
              size: flutterLogoSize,
            )),
        Positioned(
          top: 10,
          child: Align(
            alignment: AlignmentDirectional.center,
            child: Text(
              "Раунд: ${getCurrentRoundTitle(_startTime)}",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        Positioned(
            left: 10,
            bottom: 10,
            child: Text(
              "Счет: $_score",
              style: TextStyle(fontSize: 16),
            )),
        Positioned(
            right: 10,
            bottom: 10,
            child: Text(
              "Жизни: $_lives",
              style: TextStyle(color: Colors.red, fontSize: 16),
            )),
      ];
      stackChildren.addAll(_buildGameItems());
      return stackChildren;
    } else if (_gameState == GameState.END_OF_GAME) {
      return <Widget>[
        Center(
            child: SizedBox(
                height: 100,
                child: Column(
                  children: <Widget>[
                    Text("Ваш счет: $_score"),
                    RaisedButton(
                      child: Text("Новая игра"),
                      onPressed: () {
                        setState(() {
                          _score = 0;
                          _lives = initLivesCount;
                          _startTime = DateTime.now();
                          _gameState = GameState.STARTED;
                          _timer = Timer.periodic(timerTickTime, onTimerTick);
                        });
                      },
                    )
                  ],
                )))
      ];
    } else
      throw Exception("Invalid game state");
  }

  @override
  Widget build(BuildContext context) {
    if (_gameState == GameState.STARTED && _lives <= 0) {
      setState(() {
        _timer.cancel();
        _gameItems = <GameItem>[];
        _gameState = GameState.END_OF_GAME;
      });
    }

    return Scaffold(
        appBar: AppBar(
          title: Text("Flutter Defense"),
        ),
        body: Stack(
          children: _buildStackChildren(),
          alignment: AlignmentDirectional.center,
        ));
  }
}
