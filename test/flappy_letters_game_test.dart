import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/models/flappy_letters_game.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';

void main() {
  test('difficulty changes only travel speed', () {
    final games = Difficulty.values.map(FlappyLettersGame.new).toList();
    expect(games[0].speed, lessThan(games[1].speed));
    expect(games[1].speed, lessThan(games[2].speed));
    for (final game in games) {
      game.flap();
      game.advance(.05);
      expect(game.y, games.first.y);
      expect(game.gapCenter(8), games.first.gapCenter(8));
    }
  });

  test('pause freezes flight and resume continues it', () {
    final game = FlappyLettersGame(Difficulty.easy)..flap();
    game.pause();
    game.advance(.1);
    expect(game.y, 300);
    expect(game.distance, 0);
    game.resume();
    game.advance(.05);
    expect(game.distance, greaterThan(0));
  });

  test('pipe and ground collisions cost one life and wait for continue', () {
    final game = FlappyLettersGame(Difficulty.easy)..flap();
    game.distance = 340;
    game.y = 80;
    expect(game.advance(.01), isEmpty);
    expect(game.state, FlightState.hit);
    expect(game.lives, 2);
    game.advance(.1);
    expect(game.lives, 2);
    expect(game.passed, 0);
    final ground = FlappyLettersGame(Difficulty.easy)..flap();
    ground.y = 590;
    ground.advance(.01);
    expect(ground.state, FlightState.hit);
    expect(ground.lives, 2);
  });

  test('three crashes end the game; continue keeps cleared letters', () {
    final game = FlappyLettersGame(Difficulty.easy)..flap();
    game.passed = 4;
    for (var remaining = 2; remaining >= 0; remaining--) {
      game.y = 590;
      game.advance(.01);
      expect(game.lives, remaining);
      expect(game.passed, 4);
      if (remaining > 0) {
        game.continueFlight();
        expect(game.state, FlightState.ready);
        expect(game.pipeX(4), 440);
        game.flap();
      }
    }
    expect(game.state, FlightState.lost);
    game.continueFlight();
    game.flap();
    game.advance(.1);
    expect(game.lives, 0);
    expect(game.state, FlightState.lost);
    expect(FlappyLettersGame(Difficulty.easy).lives, 3);
  });

  test('each fully cleared pipe emits one name, ending exactly at Z', () {
    final game = FlappyLettersGame(Difficulty.hard)..flap();
    final heard = <String>[];
    for (var i = 0; i < 26; i++) {
      game.distance = 440 +
          i * FlappyLettersGame.spacing +
          FlappyLettersGame.pipeWidth -
          (FlappyLettersGame.birdX - FlappyLettersGame.radius) -
          .5;
      game.y = game.gapCenter(i);
      game.velocity = 0;
      heard.addAll(game.advance(.01));
      expect(game.advance(.01), isEmpty);
    }
    expect(heard.join(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    expect(game.passed, 26);
    expect(game.state, FlightState.won);
    game.flap();
    expect(game.advance(.1), isEmpty);
  });

  test('all letter-name recordings and the loading mascot exist', () {
    for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
      final asset = PhonicsAudioService.assetForPhrase('lesson-letter-$letter');
      expect(asset, isNotNull);
      expect(File('assets/$asset').existsSync(), isTrue, reason: letter);
    }
    expect(File('assets/images/app_mascot.png').existsSync(), isTrue);
  });
}
