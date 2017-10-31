# frozen_string_literal: true

require_relative 'geo_point/version'
require_relative 'geo_point/point'
require_relative 'geo_point/bounding_box'

module Philiprehberger
  module GeoPoint
    def self.point(lat, lon)
      Point.new(lat, lon)
    end

    def self.from_geohash(hash)
      raise ArgumentError, 'Geohash string cannot be empty' if hash.nil? || hash.empty?

      lat_range = [-90.0, 90.0]
      lon_range = [-180.0, 180.0]
      is_lon = true

      hash.each_char do |c|
        idx = Point::GEOHASH_BASE32.index(c)
        raise ArgumentError, "Invalid geohash character: #{c}" if idx.nil?

        4.downto(0) do |bit|
          if is_lon
            mid = (lon_range[0] + lon_range[1]) / 2.0
            if (idx >> bit) & 1 == 1
              lon_range[0] = mid
            else
              lon_range[1] = mid
            end
          else
            mid = (lat_range[0] + lat_range[1]) / 2.0
            if (idx >> bit) & 1 == 1
              lat_range[0] = mid
            else
              lat_range[1] = mid
            end
          end
          is_lon = !is_lon
        end
      end

      lat = (lat_range[0] + lat_range[1]) / 2.0
      lon = (lon_range[0] + lon_range[1]) / 2.0

      Point.new(lat, lon)
    end

    def self.inside_polygon?(point, vertices)
      raise ArgumentError, 'Polygon must have at least 3 vertices' if vertices.length < 3

      inside = false
      n = vertices.length
      j = n - 1

      n.times do |i|
        yi = vertices[i].lat
        xi = vertices[i].lon
        yj = vertices[j].lat
        xj = vertices[j].lon

        if ((yi > point.lat) != (yj > point.lat)) &&
           (point.lon < (((xj - xi) * (point.lat - yi)) / (yj - yi)) + xi)
          inside = !inside
        end

        j = i
      end

      inside
    end
  end
end
