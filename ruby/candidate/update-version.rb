require 'yaml'

VERSION_FILE = 'version.yml'
data = YAML.load_file(VERSION_FILE)

new_version = ARGV[0] or abort 'new version number must be provided'

data['current'] = new_version
File.write(VERSION_FILE, data.to_yaml)

version_module = File.read(data['location'])
new_module = version_module.sub(/^(\s*)(VERSION\s*=\s*).*$/) { "#{$1}#{$2}#{new_version.inspect}" }

File.write(data['location'], new_module)
