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
      expect(described_class::VERSION).to eq('0.1.0')
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
