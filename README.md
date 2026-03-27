# philiprehberger-geo_point

[![Tests](https://github.com/philiprehberger/rb-geo-point/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-geo-point/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-geo_point.svg)](https://rubygems.org/gems/philiprehberger-geo_point)
[![License](https://img.shields.io/github/license/philiprehberger/rb-geo-point)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

Geographic coordinate operations with Haversine distance and bounding box

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

### `GeoPoint::Point`

| Method | Description |
|--------|-------------|
| `.new(lat, lon)` | Create point with coordinate validation (-90..90, -180..180) |
| `#distance_to(other, unit: :km)` | Haversine distance (:km, :mi, :m, :nm) |
| `#bearing_to(other)` | Initial bearing in degrees (0-360) |
| `#midpoint(other)` | Geographic midpoint between two points |
| `#destination(bearing, distance, unit: :km)` | Point at given bearing and distance |
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

## License

[MIT](LICENSE)
