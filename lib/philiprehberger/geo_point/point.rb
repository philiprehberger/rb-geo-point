# frozen_string_literal: true

module Philiprehberger
  module GeoPoint
    # Represents a geographic coordinate with latitude and longitude.
    # Provides Haversine/Vincenty distance, bearing, midpoint, destination,
    # geohash, cross-track distance, polygon containment, and rhumb line calculations.
    class Point
      EARTH_RADIUS_KM = 6371.0
      UNIT_MULTIPLIERS = {
        km: 1.0,
        mi: 0.621371,
        m: 1000.0,
        nm: 0.539957
      }.freeze

      # WGS84 ellipsoid parameters
      WGS84_A = 6_378_137.0
      WGS84_F = 1.0 / 298.257223563
      WGS84_B = WGS84_A * (1 - WGS84_F)

      GEOHASH_BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz'

      attr_reader :lat, :lon

      def initialize(lat, lon)
        lat = Float(lat)
        lon = Float(lon)

        raise ArgumentError, "Latitude must be between -90 and 90, got #{lat}" unless lat.between?(-90, 90)
        raise ArgumentError, "Longitude must be between -180 and 180, got #{lon}" unless lon.between?(-180, 180)

        @lat = lat
        @lon = lon
      end

      def distance_to(other, unit: :km, method: :haversine)
        validate_unit!(unit)

        case method
        when :haversine
          haversine_distance(other, unit)
        when :vincenty
          vincenty_distance(other, unit)
        else
          raise ArgumentError, "Unknown method :#{method}. Valid methods: haversine, vincenty"
        end
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

      def destination(*args, distance: nil, bearing: nil, unit: :km)
        # Keyword-only form: destination(distance: meters, bearing: degrees).
        # When both kwargs are provided (and no positional args), distance is in meters.
        if args.empty? && !distance.nil? && !bearing.nil?
          return destination_meters_kw(distance, bearing)
        end

        raise ArgumentError, 'wrong number of arguments (given 0, expected 2)' if args.length < 2

        bearing_arg, distance_arg = args
        validate_unit!(unit)

        d = unit_to_km(distance_arg, unit) / EARTH_RADIUS_KM
        brng = deg_to_rad(bearing_arg)
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

      def to_geohash(precision: 12)
        raise ArgumentError, "Precision must be between 1 and 12, got #{precision}" unless precision.between?(1, 12)

        lat_range = [-90.0, 90.0]
        lon_range = [-180.0, 180.0]
        is_lon = true
        bit = 0
        ch = 0
        hash = +''

        (precision * 5).times do
          if is_lon
            mid = (lon_range[0] + lon_range[1]) / 2.0
            if @lon >= mid
              ch |= (1 << (4 - bit))
              lon_range[0] = mid
            else
              lon_range[1] = mid
            end
          else
            mid = (lat_range[0] + lat_range[1]) / 2.0
            if @lat >= mid
              ch |= (1 << (4 - bit))
              lat_range[0] = mid
            else
              lat_range[1] = mid
            end
          end

          is_lon = !is_lon
          bit += 1

          next unless bit == 5

          hash << GEOHASH_BASE32[ch]
          bit = 0
          ch = 0
        end

        hash
      end

      def cross_track_distance(path_start, path_end, unit: :km)
        validate_unit!(unit)

        d_start_to_self = path_start.distance_to(self, unit: :km) / EARTH_RADIUS_KM
        bearing_start_to_self = deg_to_rad(path_start.bearing_to(self))
        bearing_start_to_end = deg_to_rad(path_start.bearing_to(path_end))

        cross_track_rad = Math.asin(
          Math.sin(d_start_to_self) * Math.sin(bearing_start_to_self - bearing_start_to_end)
        )

        km_to_unit(cross_track_rad * EARTH_RADIUS_KM, unit)
      end

      def rhumb_distance_to(other, unit: :km)
        validate_unit!(unit)

        lat1 = deg_to_rad(@lat)
        lat2 = deg_to_rad(other.lat)
        dlat = lat2 - lat1
        dlon = deg_to_rad(other.lon - @lon)

        d_psi = Math.log(Math.tan((Math::PI / 4) + (lat2 / 2.0)) / Math.tan((Math::PI / 4) + (lat1 / 2.0)))

        q = if d_psi.abs > 1e-12
              dlat / d_psi
            else
              Math.cos(lat1)
            end

        dlon -= (2 * Math::PI) * (dlon <=> 0) if dlon.abs > Math::PI

        dist = Math.sqrt((dlat**2) + ((q**2) * (dlon**2))) * EARTH_RADIUS_KM

        km_to_unit(dist, unit)
      end

      def rhumb_bearing_to(other)
        lat1 = deg_to_rad(@lat)
        lat2 = deg_to_rad(other.lat)
        dlon = deg_to_rad(other.lon - @lon)

        d_psi = Math.log(Math.tan((Math::PI / 4) + (lat2 / 2.0)) / Math.tan((Math::PI / 4) + (lat1 / 2.0)))

        dlon -= (2 * Math::PI) * (dlon <=> 0) if dlon.abs > Math::PI

        (rad_to_deg(Math.atan2(dlon, d_psi)) + 360) % 360
      end

      def to_dms
        "#{format_dms(@lat, 'N', 'S')} #{format_dms(@lon, 'E', 'W')}"
      end

      # Parse degrees-minutes-seconds strings into a Point.
      #
      # Accepted forms (case-insensitive):
      #   - `"40°45'30\"N"`, `"40 45 30 N"` (with hemisphere suffix N/S/E/W)
      #   - `"40°45'30.5\"N"` (decimal seconds)
      #   - `"40.7583"` / `"-40.7583"` (plain decimal-degree, returned as-is)
      #
      # @param lat [String] latitude string
      # @param lon [String] longitude string
      # @return [Point]
      # @raise [ArgumentError] on malformed input or out-of-range values
      def self.from_dms(lat, lon)
        new(parse_dms(lat, hemisphere: %w[N S]), parse_dms(lon, hemisphere: %w[E W]))
      end

      # @api private
      def self.parse_dms(input, hemisphere:)
        raise ArgumentError, 'DMS input cannot be nil or empty' if input.nil? || input.to_s.strip.empty?

        str = input.to_s.strip
        if str.match?(/\A-?\d+(?:\.\d+)?\z/)
          return Float(str)
        end

        match = str.match(
          /\A
            (?<deg>\d+(?:\.\d+)?)
            \s*[°\s]?\s*
            (?:(?<min>\d+(?:\.\d+)?)\s*['′\s]?\s*)?
            (?:(?<sec>\d+(?:\.\d+)?)\s*["″\s]?\s*)?
            (?<hem>[#{hemisphere.join}#{hemisphere.join.downcase}])?
          \z/x
        )
        raise ArgumentError, "Invalid DMS string: #{input.inspect}" unless match

        decimal = match[:deg].to_f + (match[:min].to_f / 60.0) + (match[:sec].to_f / 3600.0)
        decimal = -decimal if match[:hem] && match[:hem].upcase == hemisphere[1]
        decimal
      end
      private_class_method :parse_dms

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

      def destination_meters_kw(distance, bearing)
        raise ArgumentError, 'distance must be Numeric' unless distance.is_a?(Numeric)
        raise ArgumentError, 'bearing must be Numeric' unless bearing.is_a?(Numeric)
        raise ArgumentError, "distance must be non-negative, got #{distance}" if distance.negative?

        bearing_norm = bearing.to_f % 360.0
        earth_radius_m = EARTH_RADIUS_KM * 1000.0

        ad = distance.to_f / earth_radius_m
        brng = deg_to_rad(bearing_norm)
        lat1 = deg_to_rad(@lat)
        lon1 = deg_to_rad(@lon)

        lat2 = Math.asin(
          (Math.sin(lat1) * Math.cos(ad)) +
          (Math.cos(lat1) * Math.sin(ad) * Math.cos(brng))
        )
        lon2 = lon1 + Math.atan2(
          Math.sin(brng) * Math.sin(ad) * Math.cos(lat1),
          Math.cos(ad) - (Math.sin(lat1) * Math.sin(lat2))
        )

        self.class.new(rad_to_deg(lat2), normalize_lon(rad_to_deg(lon2)))
      end

      def haversine_distance(other, unit)
        lat1 = deg_to_rad(@lat)
        lat2 = deg_to_rad(other.lat)
        dlat = deg_to_rad(other.lat - @lat)
        dlon = deg_to_rad(other.lon - @lon)

        a = (Math.sin(dlat / 2)**2) +
            (Math.cos(lat1) * Math.cos(lat2) * (Math.sin(dlon / 2)**2))
        c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

        km_to_unit(EARTH_RADIUS_KM * c, unit)
      end

      def vincenty_distance(other, unit) # rubocop:disable Metrics/AbcSize
        lat1 = deg_to_rad(@lat)
        lat2 = deg_to_rad(other.lat)
        lon1 = deg_to_rad(@lon)
        lon2 = deg_to_rad(other.lon)

        u1 = Math.atan((1 - WGS84_F) * Math.tan(lat1))
        u2 = Math.atan((1 - WGS84_F) * Math.tan(lat2))
        l = lon2 - lon1

        sin_u1 = Math.sin(u1)
        cos_u1 = Math.cos(u1)
        sin_u2 = Math.sin(u2)
        cos_u2 = Math.cos(u2)

        lambda_val = l
        iterations = 0

        loop do
          sin_lambda = Math.sin(lambda_val)
          cos_lambda = Math.cos(lambda_val)

          sin_sigma = Math.sqrt(
            ((cos_u2 * sin_lambda)**2) +
            (((cos_u1 * sin_u2) - (sin_u1 * cos_u2 * cos_lambda))**2)
          )

          return 0.0 if sin_sigma.zero?

          cos_sigma = (sin_u1 * sin_u2) + (cos_u1 * cos_u2 * cos_lambda)
          sigma = Math.atan2(sin_sigma, cos_sigma)

          sin_alpha = (cos_u1 * cos_u2 * sin_lambda) / sin_sigma
          cos_sq_alpha = 1 - (sin_alpha**2)

          cos_2sigma_m = if cos_sq_alpha.zero?
                           0.0
                         else
                           cos_sigma - ((2 * sin_u1 * sin_u2) / cos_sq_alpha)
                         end

          c = (WGS84_F / 16.0) * cos_sq_alpha * (4 + (WGS84_F * (4 - (3 * cos_sq_alpha))))

          lambda_prev = lambda_val
          lambda_val = l + ((1 - c) * WGS84_F * sin_alpha *
            (sigma + (c * sin_sigma * (cos_2sigma_m + (c * cos_sigma * (-1 + (2 * (cos_2sigma_m**2))))))))

          iterations += 1
          break if (lambda_val - lambda_prev).abs < 1e-12 || iterations >= 200
        end

        (((WGS84_A**2)
          (WGS84_B**2))
         (WGS84_B**2))

        ((Math.sin(Math.atan2(
                     Math.sqrt(((cos_u2 * Math.sin(lambda_val))**2) +
                       (((cos_u1 * sin_u2) - (sin_u1 * cos_u2 * Math.cos(lambda_val)))**2)),
                     (sin_u1 * sin_u2) + (cos_u1 * cos_u2 * Math.cos(lambda_val))
                   ))**2)
         (Math.sin(Math.asin((cos_u1 * cos_u2 * Math.sin(lambda_val)) /
                           Math.sqrt(((cos_u2 * Math.sin(lambda_val))**2) +
                             (((cos_u1 * sin_u2) - (sin_u1 * cos_u2 * Math.cos(lambda_val)))**2))))**2))

        # Recalculate cleanly for final result
        sin_lambda = Math.sin(lambda_val)
        cos_lambda = Math.cos(lambda_val)

        sin_sigma = Math.sqrt(
          ((cos_u2 * sin_lambda)**2) +
          (((cos_u1 * sin_u2) - (sin_u1 * cos_u2 * cos_lambda))**2)
        )
        cos_sigma = (sin_u1 * sin_u2) + (cos_u1 * cos_u2 * cos_lambda)
        sigma = Math.atan2(sin_sigma, cos_sigma)

        sin_alpha = (cos_u1 * cos_u2 * sin_lambda) / sin_sigma
        cos_sq_alpha = 1 - (sin_alpha**2)

        cos_2sigma_m = if cos_sq_alpha.zero?
                         0.0
                       else
                         cos_sigma - ((2 * sin_u1 * sin_u2) / cos_sq_alpha)
                       end

        u_sq = (cos_sq_alpha * ((WGS84_A**2) - (WGS84_B**2))) / (WGS84_B**2)
        a_coeff = 1 + ((u_sq / 16_384.0) * (4096 + (u_sq * (-768 + (u_sq * (320 - (175 * u_sq)))))))
        b_coeff = (u_sq / 1024.0) * (256 + (u_sq * (-128 + (u_sq * (74 - (47 * u_sq))))))

        delta_sigma = b_coeff * sin_sigma * (
          cos_2sigma_m + ((b_coeff / 4.0) * (
            (cos_sigma * (-1 + (2 * (cos_2sigma_m**2)))) -
            ((b_coeff / 6.0) * cos_2sigma_m * (-3 + (4 * (sin_sigma**2))) * (-3 + (4 * (cos_2sigma_m**2))))
          ))
        )

        distance_m = WGS84_B * a_coeff * (sigma - delta_sigma)
        distance_km = distance_m / 1000.0

        km_to_unit(distance_km, unit)
      end

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
