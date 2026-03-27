# frozen_string_literal: true

require_relative 'geo_point/version'
require_relative 'geo_point/point'
require_relative 'geo_point/bounding_box'

module Philiprehberger
  module GeoPoint
    def self.point(lat, lon)
      Point.new(lat, lon)
    end
  end
end
