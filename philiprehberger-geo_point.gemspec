# frozen_string_literal: true

require_relative 'lib/philiprehberger/geo_point/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-geo_point'
  spec.version       = Philiprehberger::GeoPoint::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']
  spec.summary       = 'Geographic coordinate operations with Haversine/Vincenty distance, geohash, rhumb lines, and bounding box'
  spec.description   = 'Geographic point calculations including Haversine/Vincenty distance, bearing, midpoint, ' \
                       'destination point, geohash encoding/decoding, cross-track distance, polygon containment, ' \
                       'rhumb line navigation, bounding box, and DMS formatting. Zero dependencies.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-geo-point'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'
  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
