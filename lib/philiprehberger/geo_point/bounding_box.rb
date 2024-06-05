# frozen_string_literal: true

module Philiprehberger
  module GeoPoint
    # Represents a geographic bounding box defined by min/max latitude and longitude.
    class BoundingBox
      attr_reader :min_lat, :max_lat, :min_lon, :max_lon

      def initialize(min_lat, max_lat, min_lon, max_lon)
        @min_lat = Float(min_lat)
        @max_lat = Float(max_lat)
        @min_lon = Float(min_lon)
        @max_lon = Float(max_lon)
      end

      def self.around(point, radius, unit: :km)
        km_radius = radius / Point::UNIT_MULTIPLIERS.fetch(unit)

        lat_delta = km_radius / Point::EARTH_RADIUS_KM * (180.0 / Math::PI)
        lon_delta = km_radius / (Point::EARTH_RADIUS_KM * Math.cos(point.lat * Math::PI / 180.0)) *
                    (180.0 / Math::PI)

        new(
          point.lat - lat_delta,
          point.lat + lat_delta,
          point.lon - lon_delta,
          point.lon + lon_delta
        )
      end

      def contains?(point)
        point.lat.between?(@min_lat, @max_lat) && point.lon.between?(@min_lon, @max_lon)
      end

      # Approximate surface area of the bounding box in square kilometers
      #
      # @return [Float] area in km²
      def area_km2
        lat_dist = Point::EARTH_RADIUS_KM * ((@max_lat - @min_lat) * Math::PI / 180.0)
        mid_lat = (@min_lat + @max_lat) / 2.0
        lon_dist = Point::EARTH_RADIUS_KM * Math.cos(mid_lat * Math::PI / 180.0) *
                   ((@max_lon - @min_lon) * Math::PI / 180.0)
        lat_dist.abs * lon_dist.abs
      end

      def to_a
        [@min_lat, @max_lat, @min_lon, @max_lon]
      end

      def to_h
        { min_lat: @min_lat, max_lat: @max_lat, min_lon: @min_lon, max_lon: @max_lon }
      end

      def ==(other)
        other.is_a?(self.class) &&
          @min_lat == other.min_lat && @max_lat == other.max_lat &&
          @min_lon == other.min_lon && @max_lon == other.max_lon
      end

      def eql?(other)
        self == other
      end

      def hash
        [@min_lat, @max_lat, @min_lon, @max_lon].hash
      end

      def to_s
        "(#{@min_lat}..#{@max_lat}, #{@min_lon}..#{@max_lon})"
      end

      def inspect
        "#<#{self.class} min_lat=#{@min_lat} max_lat=#{@max_lat} min_lon=#{@min_lon} max_lon=#{@max_lon}>"
      end
    end
  end
end
