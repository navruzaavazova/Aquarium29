import 'dart:async';

import 'package:aquarium/fish/genders.dart';

abstract class BaseFish {
  final String id;
  final String firstName;
  final String lastName;
  final Genders gender;
  final Duration lifespan;
  final List<Duration> listPopulationTime;

  const BaseFish({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.lifespan,
    required this.listPopulationTime,
  });

  FutureOr<void> startLife();

  FutureOr<void> died();

  FutureOr<void> population();
}
