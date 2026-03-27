# frozen_string_literal: true

module Philiprehberger
  module GeoPoint
    # Represents a geographic coordinate with latitude and longitude.
    # Provides Haversine distance, bearing, midpoint, and destination calculations.
    class Point
      EARTH_RADIUS_KM = 6371.0
      UNIT_MULTIPLIERS = {
        km: 1.0,
        mi: 0.621371,
        m: 1000.0,
        nm: 0.539957
      }.freeze

      attr_reader :lat, :lon

      def initialize(lat, lon)
        lat = Float(lat)
        lon = Float(lon)

        raise ArgumentError, "Latitude must be between -90 and 90, got #{lat}" unless lat.between?(-90, 90)
        raise ArgumentError, "Longitude must be between -180 and 180, got #{lon}" unless lon.between?(-180, 180)

        @lat = lat
        @lon = lon
      end

      def distance_to(other, unit: :km)
        validate_unit!(unit)

        lat1 = deg_to_rad(@lat)
        lat2 = deg_to_rad(other.lat)
        dlat = deg_to_rad(other.lat - @lat)
        dlon = deg_to_rad(other.lon - @lon)

        a = (Math.sin(dlat / 2)**2) +
            (Math.cos(lat1) * Math.cos(lat2) * (Math.sin(dlon / 2)**2))
        c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

        km_to_unit(EARTH_RADIUS_KM * c, unit)
      end

      def bearing_to(other)
        lat1 = deg_to_rad(@lat)
        lat2 = deg_to_rad(other.lat)
        dlon = deg_to_rad(other.lon - @lon)

        y = Math.sin(dlon) * Math.cos(lat2)
        x = (Math.cos(lat1) * Math.sin(lat2)) -
            (Math.sin(lat1) * Math.cos(lat2) * Math.cos(dlon))

        (rad_to_deg(Math.atan2(y, x)) + 360) % 360
      end

      def midpoint(other)
        lat1 = deg_to_rad(@lat)
        lat2 = deg_to_rad(other.lat)
        lon1 = deg_to_rad(@lon)
        dlon = deg_to_rad(other.lon - @lon)

        bx = Math.cos(lat2) * Math.cos(dlon)
        by = Math.cos(lat2) * Math.sin(dlon)

        mid_lat = Math.atan2(
          Math.sin(lat1) + Math.sin(lat2),
          Math.sqrt(((Math.cos(lat1) + bx)**2) + (by**2))
        )
        mid_lon = lon1 + Math.atan2(by, Math.cos(lat1) + bx)

        self.class.new(rad_to_deg(mid_lat), rad_to_deg(mid_lon))
      end

      def destination(bearing, distance, unit: :km)
        validate_unit!(unit)

        d = unit_to_km(distance, unit) / EARTH_RADIUS_KM
        brng = deg_to_rad(bearing)
        lat1 = deg_to_rad(@lat)
        lon1 = deg_to_rad(@lon)

        lat2 = Math.asin(
          (Math.sin(lat1) * Math.cos(d)) +
          (Math.cos(lat1) * Math.sin(d) * Math.cos(brng))
        )
        lon2 = lon1 + Math.atan2(
          Math.sin(brng) * Math.sin(d) * Math.cos(lat1),
          Math.cos(d) - (Math.sin(lat1) * Math.sin(lat2))
        )

        self.class.new(rad_to_deg(lat2), normalize_lon(rad_to_deg(lon2)))
      end

      def to_dms
        "#{format_dms(@lat, 'N', 'S')} #{format_dms(@lon, 'E', 'W')}"
      end

      def to_a
        [@lat, @lon]
      end

      def to_h
        { lat: @lat, lon: @lon }
      end

      def ==(other)
        other.is_a?(self.class) && @lat == other.lat && @lon == other.lon
      end

      def eql?(other)
        self == other
      end

      def hash
        [@lat, @lon].hash
      end

      def to_s
        "(#{@lat}, #{@lon})"
      end

      def inspect
        "#<#{self.class} lat=#{@lat} lon=#{@lon}>"
      end

      private

      def deg_to_rad(deg)
        deg * Math::PI / 180.0
      end

      def rad_to_deg(rad)
        rad * 180.0 / Math::PI
      end

      def km_to_unit(km, unit)
        km * UNIT_MULTIPLIERS.fetch(unit)
      end

      def unit_to_km(value, unit)
        value / UNIT_MULTIPLIERS.fetch(unit)
      end

      def normalize_lon(lon)
        ((lon + 540) % 360) - 180
      end

      def validate_unit!(unit)
        return if UNIT_MULTIPLIERS.key?(unit)

        raise ArgumentError, "Unknown unit :#{unit}. Valid units: #{UNIT_MULTIPLIERS.keys.join(', ')}"
      end

      def format_dms(decimal, pos, neg)
        direction = decimal >= 0 ? pos : neg
        decimal = decimal.abs
        degrees = decimal.floor
        minutes_decimal = (decimal - degrees) * 60
        minutes = minutes_decimal.floor
        seconds = ((minutes_decimal - minutes) * 60).round

        if seconds == 60
          seconds = 0
          minutes += 1
        end

        if minutes == 60
          minutes = 0
          degrees += 1
        end

        %(#{degrees}\u00B0#{minutes}'#{seconds}"#{direction})
      end
    end
  end
end
