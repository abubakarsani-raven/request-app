enum TrafficLevel {
  free,
  moderate,
  heavy,
}

class RouteStep {
  final String instruction;
  final double distance; // in km
  final double duration; // in minutes
  final Map<String, double> startLocation;
  final Map<String, double> endLocation;
  final String polyline; // encoded polyline for this step

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.polyline,
  });

  /// Clean HTML from instruction text
  String get cleanInstruction {
    return instruction
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}

class RouteModel {
  final List<Map<String, double>> polylinePoints;
  final double distance; // in km
  final double duration; // in minutes (free-flow)
  final double durationInTraffic; // in minutes (with traffic)
  final List<RouteStep> steps;
  final TrafficLevel trafficLevel;
  final Map<String, double>? bounds;

  RouteModel({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.durationInTraffic,
    required this.steps,
    required this.trafficLevel,
    this.bounds,
  });

  /// Get traffic delay in minutes
  double get trafficDelay => durationInTraffic - duration;

  /// Get formatted distance string
  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  /// Get formatted duration string
  String get formattedDuration {
    if (durationInTraffic < 60) {
      return '${durationInTraffic.toStringAsFixed(0)} min';
    }
    final hours = (durationInTraffic / 60).floor();
    final minutes = (durationInTraffic % 60).round();
    if (minutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $minutes min';
  }

  /// Get traffic color based on traffic level
  int get trafficColor {
    switch (trafficLevel) {
      case TrafficLevel.free:
        return 0xFF4CAF50; // Green
      case TrafficLevel.moderate:
        return 0xFFFFC107; // Yellow/Amber
      case TrafficLevel.heavy:
        return 0xFFF44336; // Red
    }
  }
}

