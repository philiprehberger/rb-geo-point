# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.2.0] - 2026-03-28

### Added

- Vincenty formula for ellipsoid-accurate distance via `method: :vincenty` option on `Point#distance_to`
- Geohash encoding with `Point#to_geohash(precision: 12)` using standard base32 encoding
- Geohash decoding with `GeoPoint.from_geohash(hash)` returning a Point at the center of the cell
- Cross-track distance with `Point#cross_track_distance(path_start, path_end, unit: :km)`
- Polygon containment check with `GeoPoint.inside_polygon?(point, vertices)` using ray-casting algorithm
- Rhumb line distance with `Point#rhumb_distance_to(other, unit: :km)`
- Rhumb line bearing with `Point#rhumb_bearing_to(other)`
- GitHub issue templates (bug report, feature request)
- Dependabot configuration for bundler and GitHub Actions
- Pull request template

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
