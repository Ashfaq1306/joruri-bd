import 'package:flutter/material.dart';

/// Maps the icon keys used in guide content to Material icons.
IconData guideIcon(String key) => switch (key) {
      'heart' => Icons.favorite,
      'stroke' => Icons.psychology,
      'unconscious' => Icons.airline_seat_flat,
      'choking' => Icons.air,
      'bleeding' => Icons.water_drop,
      'burn' => Icons.whatshot,
      'fracture' => Icons.accessibility_new,
      'electric' => Icons.bolt,
      'drowning' => Icons.pool,
      'snake' => Icons.pest_control,
      'animal' => Icons.pets,
      'poison' => Icons.science,
      'seizure' => Icons.waves,
      'road' => Icons.directions_car,
      'fire' => Icons.local_fire_department,
      'gas' => Icons.propane_tank,
      'collapse' => Icons.domain_disabled,
      'flood' => Icons.flood,
      'cyclone' => Icons.cyclone,
      'earthquake' => Icons.vibration,
      'lightning' => Icons.thunderstorm,
      'landslide' => Icons.landslide,
      'storm' => Icons.storm,
      _ => Icons.medical_services,
    };
