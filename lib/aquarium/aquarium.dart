import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:aquarium/aquarium/fish_model.dart';
import 'package:aquarium/fish/fish.dart';
import 'package:aquarium/fish/fish_action.dart';
import 'package:aquarium/fish/fish_request.dart';
import 'package:aquarium/fish/genders.dart';
import 'package:aquarium/utils/fish_names.dart';
import 'package:uuid/uuid.dart';

class Aquarium {
  final Random _random = Random();
  final LinkedHashMap<String, FishModel> _fishList = LinkedHashMap();
  final ReceivePort _mainReceivePort = ReceivePort();
  int _newFishCount = 0;
  int _diedFishCount = 0;

  void runApp() {
    stdout.write("Enter initial fish count: ");
    final int count = int.tryParse(stdin.readLineSync() ?? '0') ?? 0;
    initial(count);
    portListener();
  }

  void portListener() {
    _mainReceivePort.listen((value) {
      if (value is FishRequest) {
        switch (value.action) {
          case FishAction.sendPort:
            _fishList.update(
              value.fishId,
              (value) {
                value.sendPort?.send(FishAction.startLife);
                return value.copyWith(
                  sendPort: value.sendPort,
                );
              },
            );
            break;
          case FishAction.fishDied:
            final model = _fishList[value.fishId];
            model?.sendPort?.send(FishAction.close);
            model?.isolate.kill(
              priority: Isolate.immediate,
            );
            _diedFishCount++;
            break;
          case FishAction.needPopulate:
            population(value.fishId, value.args as Genders);
            break;
          default:
            break;
        }
      }
    });
  }

  void population(String fishId, Genders gender) {
    if (_fishList.isNotEmpty) {

    }
  }

  void initial(int count) {
    for (int i = 0; i < count; i++) {
      createFish();
    }
  }

  void createFish({
    String? maleId,
    String? femaleId,
  }) async {
    final fishId = Uuid().v1(options: {
      "Male": maleId,
      "Female": femaleId,
    });
    final gender = _random.nextBool() ? Genders.male : Genders.female;
    final firstName = gender.isMale
        ? FishNames.maleFirst[_random.nextInt(FishNames.maleFirst.length)]
        : FishNames.femaleFirst[_random.nextInt(FishNames.femaleFirst.length)];
    final lastName = gender.isMale
        ? FishNames.maleLast[_random.nextInt(FishNames.maleLast.length)]
        : FishNames.femaleLast[_random.nextInt(FishNames.femaleLast.length)];
    final lifespan = Duration(seconds: _random.nextInt(50) + 10);
    final populateCount = _random.nextInt(2) + 1;
    final List<Duration> listPopulationTime = List.generate(
      populateCount,
      (index) => Duration(seconds: _random.nextInt(15) + 5),
    );

    final fish = Fish(
      id: fishId,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      lifespan: lifespan,
      listPopulationTime: listPopulationTime,
      sendPort: _mainReceivePort.sendPort,
    );
    final isolate = await Isolate.spawn(Fish.run, fish);
    _fishList[fishId] = FishModel(
      isolate: isolate,
      genders: gender,
    );
    _newFishCount++;
  }

  @override
  String toString() {
    int fishCount = 0;
    int maleCount = 0;
    int femaleCount = 0;

    _fishList.forEach((key, value) {
      fishCount++;
      if (value.genders == Genders.male) {
        maleCount++;
      } else {
        femaleCount++;
      }
    });
    print('\x1B[2J\x1B[0;0H');
    return 'Aquarium info\nFish count: $fishCount\nMale count: $maleCount\nFemale count: $femaleCount\nNew fish count: $_newFishCount\n Died fish count: $_diedFishCount';
  }
}
