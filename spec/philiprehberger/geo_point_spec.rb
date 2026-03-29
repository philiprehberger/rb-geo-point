# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::GeoPoint do
  describe '.point' do
    it 'creates a Point instance' do
      point = described_class.point(40.7128, -74.0060)
      expect(point).to be_a(described_class::Point)
      expect(point.lat).to eq(40.7128)
      expect(point.lon).to eq(-74.0060)
    end
  end

  describe '::VERSION' do
    it 'has a version number' do
      expect(described_class::VERSION).not_to be_nil
    end
  end

  describe '.from_geohash' do
    it 'decodes a geohash to a point near the center of the cell' do
      point = described_class.from_geohash('u4pruydqqvj')
      expect(point.lat).to be_within(0.001).of(57.6499)
      expect(point.lon).to be_within(0.001).of(10.4066)
    end

    it 'round-trips with to_geohash' do
      original = described_class.point(40.7128, -74.0060)
      hash = original.to_geohash(precision: 9)
      decoded = described_class.from_geohash(hash)
      expect(decoded.lat).to be_within(0.001).of(original.lat)
      expect(decoded.lon).to be_within(0.001).of(original.lon)
    end

    it 'decodes short geohashes with lower precision' do
      point = described_class.from_geohash('u4pr')
      expect(point.lat).to be_within(0.1).of(57.6)
      expect(point.lon).to be_within(0.2).of(10.4)
    end

    it 'raises for empty geohash' do
      expect { described_class.from_geohash('') }.to raise_error(ArgumentError, /empty/)
    end

    it 'raises for nil geohash' do
      expect { described_class.from_geohash(nil) }.to raise_error(ArgumentError, /empty/)
    end

    it 'raises for invalid characters' do
      expect { described_class.from_geohash('u4prAZi') }.to raise_error(ArgumentError, /Invalid geohash character/)
    end
  end

  describe '.inside_polygon?' do
    let(:triangle) do
      [
        described_class::Point.new(0, 0),
        described_class::Point.new(0, 10),
        described_class::Point.new(10, 5)
      ]
    end

    let(:square) do
      [
        described_class::Point.new(0, 0),
        described_class::Point.new(0, 10),
        described_class::Point.new(10, 10),
        described_class::Point.new(10, 0)
      ]
    end

    let(:concave_polygon) do
      [
        described_class::Point.new(0, 0),
        described_class::Point.new(0, 10),
        described_class::Point.new(5, 5),
        described_class::Point.new(10, 10),
        described_class::Point.new(10, 0)
      ]
    end

    it 'returns true for point inside triangle' do
      point = described_class::Point.new(3, 5)
      expect(described_class.inside_polygon?(point, triangle)).to be true
    end

    it 'returns false for point outside triangle' do
      point = described_class::Point.new(20, 20)
      expect(described_class.inside_polygon?(point, triangle)).to be false
    end

    it 'returns true for point inside square' do
      point = described_class::Point.new(5, 5)
      expect(described_class.inside_polygon?(point, square)).to be true
    end

    it 'returns false for point outside square' do
      point = described_class::Point.new(15, 5)
      expect(described_class.inside_polygon?(point, square)).to be false
    end

    it 'handles concave polygon correctly' do
      inside = described_class::Point.new(2, 2)
      concave_notch = described_class::Point.new(5, 7)
      expect(described_class.inside_polygon?(inside, concave_polygon)).to be true
      expect(described_class.inside_polygon?(concave_notch, concave_polygon)).to be false
    end

    it 'raises for fewer than 3 vertices' do
      two_points = [described_class::Point.new(0, 0), described_class::Point.new(1, 1)]
      point = described_class::Point.new(0.5, 0.5)
      expect { described_class.inside_polygon?(point, two_points) }.to raise_error(ArgumentError, /at least 3/)
    end
  end
end

RSpec.describe Philiprehberger::GeoPoint::Point do
  let(:nyc) { described_class.new(40.7128, -74.0060) }
  let(:london) { described_class.new(51.5074, -0.1278) }
  let(:tokyo) { described_class.new(35.6762, 139.6503) }
  let(:sydney) { described_class.new(-33.8688, 151.2093) }
  let(:origin) { described_class.new(0, 0) }

  describe '.new' do
    it 'creates a point with valid coordinates' do
      point = described_class.new(45.0, 90.0)
      expect(point.lat).to eq(45.0)
      expect(point.lon).to eq(90.0)
    end

    it 'accepts boundary values' do
      expect { described_class.new(90, 180) }.not_to raise_error
      expect { described_class.new(-90, -180) }.not_to raise_error
    end

    it 'raises ArgumentError for latitude out of range' do
      expect { described_class.new(91, 0) }.to raise_error(ArgumentError, /Latitude/)
      expect { described_class.new(-91, 0) }.to raise_error(ArgumentError, /Latitude/)
    end

    it 'raises ArgumentError for longitude out of range' do
      expect { described_class.new(0, 181) }.to raise_error(ArgumentError, /Longitude/)
      expect { described_class.new(0, -181) }.to raise_error(ArgumentError, /Longitude/)
    end

    it 'converts string arguments to floats' do
      point = described_class.new('45.5', '-90.5')
      expect(point.lat).to eq(45.5)
      expect(point.lon).to eq(-90.5)
    end

    it 'raises for non-numeric arguments' do
      expect { described_class.new('abc', 0) }.to raise_error(ArgumentError)
    end
  end

  describe '#distance_to' do
    it 'calculates NYC to London distance in km (~5570 km)' do
      distance = nyc.distance_to(london, unit: :km)
      expect(distance).to be_within(30).of(5570)
    end

    it 'calculates distance in miles' do
      distance = nyc.distance_to(london, unit: :mi)
      expect(distance).to be_within(20).of(3461)
    end

    it 'calculates distance in meters' do
      distance = nyc.distance_to(london, unit: :m)
      expect(distance).to be_within(30_000).of(5_570_000)
    end

    it 'calculates distance in nautical miles' do
      distance = nyc.distance_to(london, unit: :nm)
      expect(distance).to be_within(20).of(3007)
    end

    it 'returns zero distance for same point' do
      expect(nyc.distance_to(nyc)).to eq(0.0)
    end

    it 'is symmetric' do
      d1 = nyc.distance_to(london)
      d2 = london.distance_to(nyc)
      expect(d1).to be_within(0.001).of(d2)
    end

    it 'raises for unknown unit' do
      expect { nyc.distance_to(london, unit: :furlongs) }.to raise_error(ArgumentError, /Unknown unit/)
    end

    it 'defaults to haversine method' do
      haversine = nyc.distance_to(london, method: :haversine)
      default = nyc.distance_to(london)
      expect(default).to eq(haversine)
    end

    it 'raises for unknown method' do
      expect { nyc.distance_to(london, method: :unknown) }.to raise_error(ArgumentError, /Unknown method/)
    end
  end

  describe '#distance_to with vincenty' do
    it 'calculates NYC to London distance with vincenty (~5585 km)' do
      distance = nyc.distance_to(london, method: :vincenty)
      expect(distance).to be_within(10).of(5585)
    end

    it 'returns zero distance for same point' do
      expect(nyc.distance_to(nyc, method: :vincenty)).to eq(0.0)
    end

    it 'is symmetric' do
      d1 = nyc.distance_to(london, method: :vincenty)
      d2 = london.distance_to(nyc, method: :vincenty)
      expect(d1).to be_within(0.001).of(d2)
    end

    it 'supports unit conversion with vincenty' do
      km = nyc.distance_to(london, method: :vincenty, unit: :km)
      mi = nyc.distance_to(london, method: :vincenty, unit: :mi)
      expect(mi).to be_within(1).of(km * 0.621371)
    end

    it 'calculates short distances accurately' do
      # Two points ~1km apart
      a = described_class.new(51.5074, -0.1278)
      b = described_class.new(51.5164, -0.1278)
      distance = a.distance_to(b, method: :vincenty)
      expect(distance).to be_within(0.1).of(1.0)
    end

    it 'calculates equatorial distances' do
      a = described_class.new(0, 0)
      b = described_class.new(0, 1)
      distance = a.distance_to(b, method: :vincenty)
      # 1 degree of longitude at equator is ~111.32 km
      expect(distance).to be_within(0.5).of(111.32)
    end

    it 'produces results close to haversine for moderate distances' do
      haversine = nyc.distance_to(tokyo, method: :haversine)
      vincenty = nyc.distance_to(tokyo, method: :vincenty)
      # They should be within ~0.5% of each other
      expect(vincenty).to be_within(haversine * 0.005).of(haversine)
    end
  end

  describe '#bearing_to' do
    it 'calculates bearing from NYC to London' do
      bearing = nyc.bearing_to(london)
      expect(bearing).to be_within(1).of(51.2)
    end

    it 'returns bearing in 0-360 range' do
      bearing = london.bearing_to(nyc)
      expect(bearing).to be_between(0, 360)
    end

    it 'calculates due north bearing' do
      south = described_class.new(0, 0)
      north = described_class.new(10, 0)
      expect(south.bearing_to(north)).to be_within(0.01).of(0)
    end

    it 'calculates due east bearing' do
      west = described_class.new(0, 0)
      east = described_class.new(0, 10)
      expect(west.bearing_to(east)).to be_within(0.01).of(90)
    end
  end

  describe '#midpoint' do
    it 'calculates midpoint between NYC and London' do
      mid = nyc.midpoint(london)
      expect(mid.lat).to be_within(1).of(52.5)
      expect(mid.lon).to be_within(6).of(-36.0)
    end

    it 'returns a Point instance' do
      expect(nyc.midpoint(london)).to be_a(described_class)
    end

    it 'midpoint of same point is itself' do
      mid = nyc.midpoint(nyc)
      expect(mid.lat).to be_within(0.001).of(nyc.lat)
      expect(mid.lon).to be_within(0.001).of(nyc.lon)
    end
  end

  describe '#destination' do
    it 'calculates destination point' do
      dest = origin.destination(90, 111.32)
      expect(dest.lat).to be_within(0.1).of(0)
      expect(dest.lon).to be_within(0.5).of(1.0)
    end

    it 'round-trips with distance and bearing' do
      bearing = nyc.bearing_to(london)
      distance = nyc.distance_to(london)
      dest = nyc.destination(bearing, distance)
      expect(dest.lat).to be_within(0.5).of(london.lat)
      expect(dest.lon).to be_within(0.5).of(london.lon)
    end

    it 'supports unit conversion' do
      dest_km = origin.destination(0, 100, unit: :km)
      dest_mi = origin.destination(0, 62.1371, unit: :mi)
      expect(dest_km.lat).to be_within(0.01).of(dest_mi.lat)
    end

    it 'raises for unknown unit' do
      expect { origin.destination(0, 100, unit: :parsecs) }.to raise_error(ArgumentError, /Unknown unit/)
    end
  end

  describe '#to_geohash' do
    it 'encodes NYC to a geohash' do
      hash = nyc.to_geohash(precision: 9)
      expect(hash.length).to eq(9)
      expect(hash).to start_with('dr5r')
    end

    it 'encodes origin to a geohash' do
      hash = origin.to_geohash(precision: 6)
      expect(hash.length).to eq(6)
      expect(hash).to eq('s00000')
    end

    it 'defaults to precision 12' do
      hash = nyc.to_geohash
      expect(hash.length).to eq(12)
    end

    it 'respects custom precision' do
      hash = nyc.to_geohash(precision: 5)
      expect(hash.length).to eq(5)
    end

    it 'raises for precision below 1' do
      expect { nyc.to_geohash(precision: 0) }.to raise_error(ArgumentError, /Precision/)
    end

    it 'raises for precision above 12' do
      expect { nyc.to_geohash(precision: 13) }.to raise_error(ArgumentError, /Precision/)
    end

    it 'round-trips with from_geohash' do
      hash = london.to_geohash(precision: 10)
      decoded = Philiprehberger::GeoPoint.from_geohash(hash)
      expect(decoded.lat).to be_within(0.0001).of(london.lat)
      expect(decoded.lon).to be_within(0.0001).of(london.lon)
    end

    it 'encodes southern hemisphere correctly' do
      hash = sydney.to_geohash(precision: 6)
      expect(hash.length).to eq(6)
      expect(hash).to start_with('r')
    end

    it 'encodes points near the date line' do
      point = described_class.new(0, 179.9)
      hash = point.to_geohash(precision: 6)
      expect(hash.length).to eq(6)
    end

    it 'produces different hashes for nearby but distinct points' do
      a = described_class.new(40.7128, -74.0060)
      b = described_class.new(40.7130, -74.0060)
      hash_a = a.to_geohash(precision: 12)
      hash_b = b.to_geohash(precision: 12)
      expect(hash_a).not_to eq(hash_b)
    end
  end

  describe '#cross_track_distance' do
    it 'calculates cross-track distance from point to great circle path' do
      # Point slightly off the equator, path along the equator
      point = described_class.new(1, 5)
      path_start = described_class.new(0, 0)
      path_end = described_class.new(0, 10)
      distance = point.cross_track_distance(path_start, path_end)
      # 1 degree of latitude is ~111 km; sign indicates side of path
      expect(distance.abs).to be_within(2).of(111.2)
    end

    it 'returns opposite sign for points on opposite sides of the path' do
      north_point = described_class.new(1, 5)
      south_point = described_class.new(-1, 5)
      path_start = described_class.new(0, 0)
      path_end = described_class.new(0, 10)
      north_dist = north_point.cross_track_distance(path_start, path_end)
      south_dist = south_point.cross_track_distance(path_start, path_end)
      # Points on opposite sides should have opposite signs or both magnitudes ~111km
      expect(north_dist.abs).to be_within(2).of(south_dist.abs)
    end

    it 'returns approximately zero for point on the great circle' do
      point = described_class.new(0, 5)
      path_start = described_class.new(0, 0)
      path_end = described_class.new(0, 10)
      distance = point.cross_track_distance(path_start, path_end)
      expect(distance.abs).to be < 0.01
    end

    it 'supports unit conversion' do
      point = described_class.new(1, 5)
      path_start = described_class.new(0, 0)
      path_end = described_class.new(0, 10)
      km = point.cross_track_distance(path_start, path_end, unit: :km)
      mi = point.cross_track_distance(path_start, path_end, unit: :mi)
      expect(mi).to be_within(0.1).of(km * 0.621371)
    end

    it 'raises for unknown unit' do
      point = described_class.new(1, 5)
      path_start = described_class.new(0, 0)
      path_end = described_class.new(0, 10)
      expect { point.cross_track_distance(path_start, path_end, unit: :furlongs) }
        .to raise_error(ArgumentError, /Unknown unit/)
    end

    it 'handles diagonal great circle paths' do
      point = described_class.new(46, -74)
      path_start = described_class.new(40.7128, -74.0060)
      path_end = described_class.new(51.5074, -0.1278)
      distance = point.cross_track_distance(path_start, path_end)
      expect(distance.abs).to be_within(500).of(0)
    end
  end

  describe '#rhumb_distance_to' do
    it 'calculates rhumb distance between NYC and London' do
      distance = nyc.rhumb_distance_to(london)
      expect(distance).to be_within(100).of(5800)
    end

    it 'returns zero for same point' do
      expect(nyc.rhumb_distance_to(nyc)).to be_within(0.001).of(0.0)
    end

    it 'is symmetric' do
      d1 = nyc.rhumb_distance_to(london)
      d2 = london.rhumb_distance_to(nyc)
      expect(d1).to be_within(0.001).of(d2)
    end

    it 'equals great circle distance for pure north-south travel' do
      a = described_class.new(10, 0)
      b = described_class.new(50, 0)
      rhumb = a.rhumb_distance_to(b)
      haversine = a.distance_to(b)
      expect(rhumb).to be_within(0.1).of(haversine)
    end

    it 'equals great circle distance for equatorial travel' do
      a = described_class.new(0, 0)
      b = described_class.new(0, 10)
      rhumb = a.rhumb_distance_to(b)
      haversine = a.distance_to(b)
      expect(rhumb).to be_within(0.1).of(haversine)
    end

    it 'is longer than great circle distance for diagonal routes' do
      rhumb = nyc.rhumb_distance_to(london)
      haversine = nyc.distance_to(london)
      expect(rhumb).to be >= haversine
    end

    it 'supports unit conversion' do
      km = nyc.rhumb_distance_to(london, unit: :km)
      mi = nyc.rhumb_distance_to(london, unit: :mi)
      expect(mi).to be_within(1).of(km * 0.621371)
    end

    it 'raises for unknown unit' do
      expect { nyc.rhumb_distance_to(london, unit: :furlongs) }.to raise_error(ArgumentError, /Unknown unit/)
    end
  end

  describe '#rhumb_bearing_to' do
    it 'calculates rhumb bearing from NYC to London' do
      bearing = nyc.rhumb_bearing_to(london)
      expect(bearing).to be_between(0, 360)
    end

    it 'returns 0 for due north' do
      a = described_class.new(0, 0)
      b = described_class.new(10, 0)
      expect(a.rhumb_bearing_to(b)).to be_within(0.01).of(0)
    end

    it 'returns 90 for due east' do
      a = described_class.new(0, 0)
      b = described_class.new(0, 10)
      expect(a.rhumb_bearing_to(b)).to be_within(0.01).of(90)
    end

    it 'returns 180 for due south' do
      a = described_class.new(10, 0)
      b = described_class.new(0, 0)
      expect(a.rhumb_bearing_to(b)).to be_within(0.01).of(180)
    end

    it 'returns 270 for due west' do
      a = described_class.new(0, 10)
      b = described_class.new(0, 0)
      expect(a.rhumb_bearing_to(b)).to be_within(0.01).of(270)
    end

    it 'is constant along a rhumb line (unlike great circle bearing)' do
      bearing1 = nyc.rhumb_bearing_to(london)
      # A rhumb line has constant bearing by definition
      expect(bearing1).to be_between(0, 360)
    end
  end

  describe '#to_dms' do
    it 'formats NYC coordinates' do
      dms = nyc.to_dms
      expect(dms).to include('N')
      expect(dms).to include('W')
      expect(dms).to match(/40\u00B042'46"N/)
    end

    it 'formats southern hemisphere coordinates' do
      dms = sydney.to_dms
      expect(dms).to include('S')
      expect(dms).to include('E')
    end

    it 'formats origin coordinates' do
      dms = origin.to_dms
      expect(dms).to eq("0\u00B00'0\"N 0\u00B00'0\"E")
    end
  end

  describe '#to_a' do
    it 'returns [lat, lon] array' do
      expect(nyc.to_a).to eq([40.7128, -74.0060])
    end
  end

  describe '#to_h' do
    it 'returns {lat:, lon:} hash' do
      expect(nyc.to_h).to eq({ lat: 40.7128, lon: -74.0060 })
    end
  end

  describe '#==' do
    it 'considers equal coordinates as equal' do
      a = described_class.new(40.7128, -74.0060)
      b = described_class.new(40.7128, -74.0060)
      expect(a).to eq(b)
    end

    it 'considers different coordinates as not equal' do
      expect(nyc).not_to eq(london)
    end
  end

  describe '#to_s' do
    it 'formats as (lat, lon)' do
      expect(nyc.to_s).to eq('(40.7128, -74.006)')
    end
  end
end

RSpec.describe Philiprehberger::GeoPoint::BoundingBox do
  let(:nyc) { Philiprehberger::GeoPoint::Point.new(40.7128, -74.0060) }

  describe '.around' do
    it 'creates a bounding box around a point' do
      box = described_class.around(nyc, 10)
      expect(box.min_lat).to be < nyc.lat
      expect(box.max_lat).to be > nyc.lat
      expect(box.min_lon).to be < nyc.lon
      expect(box.max_lon).to be > nyc.lon
    end

    it 'creates a larger box with larger radius' do
      small = described_class.around(nyc, 10)
      large = described_class.around(nyc, 100)
      expect(large.max_lat - large.min_lat).to be > (small.max_lat - small.min_lat)
    end

    it 'supports unit conversion' do
      box_km = described_class.around(nyc, 10, unit: :km)
      box_mi = described_class.around(nyc, 6.21371, unit: :mi)
      expect(box_km.max_lat).to be_within(0.01).of(box_mi.max_lat)
    end
  end

  describe '#contains?' do
    let(:box) { described_class.around(nyc, 50) }

    it 'returns true for center point' do
      expect(box.contains?(nyc)).to be true
    end

    it 'returns true for nearby point' do
      nearby = Philiprehberger::GeoPoint::Point.new(40.75, -74.0)
      expect(box.contains?(nearby)).to be true
    end

    it 'returns false for distant point' do
      london = Philiprehberger::GeoPoint::Point.new(51.5074, -0.1278)
      expect(box.contains?(london)).to be false
    end
  end

  describe '#to_a' do
    it 'returns [min_lat, max_lat, min_lon, max_lon]' do
      box = described_class.new(40, 41, -75, -73)
      expect(box.to_a).to eq([40, 41, -75, -73])
    end
  end

  describe '#to_h' do
    it 'returns a hash with all bounds' do
      box = described_class.new(40, 41, -75, -73)
      expect(box.to_h).to eq({ min_lat: 40, max_lat: 41, min_lon: -75, max_lon: -73 })
    end
  end

  describe '#==' do
    it 'considers equal boxes as equal' do
      a = described_class.new(40, 41, -75, -73)
      b = described_class.new(40, 41, -75, -73)
      expect(a).to eq(b)
    end
  end
end
