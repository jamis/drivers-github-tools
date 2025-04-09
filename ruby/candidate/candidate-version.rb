require 'yaml'

VERSION_FILE = 'version.yml'
data = YAML.load_file(VERSION_FILE)

version_string = data['current']
major, minor, patch, suffix = version_string.split(/\./, 4)

# TODO: caller should indicate whether this is a:
#   - major release: any backwards-incompatible change
#   - minor release: new backwards-compatible functionality
#   - patch release: backwards-compatible bug fixes

case ARGV[0]
when 'major' then
  major = major.to_i + 1
  minor = patch = 0
when 'minor' then
  minor = minor.to_i + 1
  patch = 0
when 'patch' then
  patch = patch.to_i + 1
else
  raise ArgumentError, "invalid release type: #{ARGV[0].inspect}"
end

puts [ major, minor, patch ].join('.')
