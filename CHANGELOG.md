# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-03-26

### Added

- Add GitHub funding configuration

### Fixed

- Use non-fragile version assertion in tests

## [0.1.0] - 2026-03-26

### Added

- Initial release
- Geographic point creation with coordinate validation
- Haversine distance calculation with km, mi, m, and nm units
- Initial bearing calculation between two points
- Midpoint calculation between two points
- Destination point from bearing and distance
- Bounding box generation around a point
- DMS (degrees, minutes, seconds) formatting
- Convenience `GeoPoint.point(lat, lon)` class method
