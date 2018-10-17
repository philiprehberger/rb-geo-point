# philiprehberger-geo_point

[![Tests](https://github.com/philiprehberger/rb-geo-point/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-geo-point/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-geo_point.svg)](https://rubygems.org/gems/philiprehberger-geo_point)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-geo-point)](https://github.com/philiprehberger/rb-geo-point/commits/main)

Geographic coordinate operations with Haversine/Vincenty distance, geohash, rhumb lines, and bounding box

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-geo_point"
```

Or install directly:

```bash
gem install philiprehberger-geo_point
```

## Usage

```ruby
require "philiprehberger/geo_point"

nyc = Philiprehberger::GeoPoint.point(40.7128, -74.0060)
london = Philiprehberger::GeoPoint.point(51.5074, -0.1278)

nyc.distance_to(london)  # => ~5570.0 (km)
```

### Distance Units

```ruby
nyc.distance_to(london, unit: :km)  # => ~5570.0
nyc.distance_to(london, unit: :mi)  # => ~3461.0
nyc.distance_to(london, unit: :m)   # => ~5570000.0
nyc.distance_to(london, unit: :nm)  # => ~3007.0
```

### Vincenty Distance

```ruby
nyc.distance_to(london, method: :vincenty)  # => ~5585.0 (ellipsoid-accurate)
nyc.distance_to(london, method: :haversine) # => ~5570.0 (spherical, default)
```

### Bearing

```ruby
nyc.bearing_to(london)  # => ~51.2 (degrees, 0-360)
```

### Midpoint

```ruby
mid = nyc.midpoint(london)
mid.lat  # => ~52.5
mid.lon  # => ~-36.0
```

### Destination Point

```ruby
dest = nyc.destination(51.2, 5570)  # bearing, distance in km
dest.lat  # => ~51.5
dest.lon  # => ~-0.1
```

### Geohash

```ruby
nyc.to_geohash                    # => "dr5ru6j2c62g" (precision 12)
nyc.to_geohash(precision: 6)     # => "dr5ru6"

point = Philiprehberger::GeoPoint.from_geohash("dr5ru6j2c62g")
point.lat  # => ~40.7128
point.lon  # => ~-74.0060
```

### Cross-Track Distance

```ruby
point = Philiprehberger::GeoPoint.point(1, 5)
path_start = Philiprehberger::GeoPoint.point(0, 0)
path_end = Philiprehberger::GeoPoint.point(0, 10)

point.cross_track_distance(path_start, path_end)  # => ~111.2 (km, positive = right of path)
```

### Rhumb Lines

```ruby
nyc.rhumb_distance_to(london)  # => ~5800.0 (km, constant-bearing route)
nyc.rhumb_bearing_to(london)   # => ~79.3 (degrees, constant bearing)
```

### Polygon Containment

```ruby
triangle = [
  Philiprehberger::GeoPoint.point(0, 0),
  Philiprehberger::GeoPoint.point(0, 10),
  Philiprehberger::GeoPoint.point(10, 5)
]

inside = Philiprehberger::GeoPoint.point(3, 5)
outside = Philiprehberger::GeoPoint.point(20, 20)

Philiprehberger::GeoPoint.inside_polygon?(inside, triangle)   # => true
Philiprehberger::GeoPoint.inside_polygon?(outside, triangle)  # => false
```

### Bounding Box

```ruby
box = Philiprehberger::GeoPoint::BoundingBox.around(nyc, 50)
box.contains?(nyc)     # => true
box.contains?(london)  # => false
```

### DMS Formatting

```ruby
nyc.to_dms  # => "40°42'46\"N 74°0'22\"W"
nyc.to_a    # => [40.7128, -74.0060]
nyc.to_h    # => {lat: 40.7128, lon: -74.0060}
```

## API

### `GeoPoint`

| Method | Description |
|--------|-------------|
| `.point(lat, lon)` | Create a new Point instance |
| `.from_geohash(hash)` | Decode a geohash string to a Point at the center of the cell |
| `.inside_polygon?(point, vertices)` | Check if a point is inside a polygon using ray-casting |

### `GeoPoint::Point`

| Method | Description |
|--------|-------------|
| `.new(lat, lon)` | Create point with coordinate validation (-90..90, -180..180) |
| `#distance_to(other, unit: :km, method: :haversine)` | Distance via Haversine or Vincenty (:km, :mi, :m, :nm) |
| `#bearing_to(other)` | Initial bearing in degrees (0-360) |
| `#midpoint(other)` | Geographic midpoint between two points |
| `#destination(bearing, distance, unit: :km)` | Point at given bearing and distance |
| `#to_geohash(precision: 12)` | Encode point as a geohash string (precision 1-12) |
| `#cross_track_distance(path_start, path_end, unit: :km)` | Perpendicular distance to great circle path |
| `#rhumb_distance_to(other, unit: :km)` | Rhumb line (constant-bearing) distance |
| `#rhumb_bearing_to(other)` | Rhumb line bearing in degrees (0-360) |
| `#to_dms` | Format as degrees, minutes, seconds string |
| `#to_a` | Return [lat, lon] array |
| `#to_h` | Return {lat:, lon:} hash |

### `GeoPoint::BoundingBox`

| Method | Description |
|--------|-------------|
| `.around(point, radius, unit: :km)` | Create bounding box around a point |
| `#contains?(point)` | Check if point is within the box |
| `#to_a` | Return [min_lat, max_lat, min_lon, max_lon] array |
| `#to_h` | Return hash with all bounds |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-geo-point)

🐛 [Report issues](https://github.com/philiprehberger/rb-geo-point/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-geo-point/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
