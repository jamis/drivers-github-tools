# frozen_string_literal: true

require 'yaml'
require 'json'

BCBREAK = 'bcbreak'
ENHANCEMENT = 'enhancement'
BUG = 'bug'

RELEASE_TYPES = %w[ patch minor major ]

# 1. read current version
VERSION_FILE = 'version.yml'
data = YAML.load_file(VERSION_FILE)

# 2. assume most recent tagName == v#{VERSION}
tag_name = "v#{data['current']}"

# 3. Find all changes since the given tagName
changes = `git log --pretty=format:"%s" #{tag_name}..`

# 4. Grab the PR number from the end of each of those lines
pr_numbers = changes.lines.map { |line| line.match(/\(#(\d+)\)$/)[1] }

# 5. Query the list of PRs and create a json file locally
pr_data = `gh pr list --state all --json number,title,labels,url,body --jq 'map(select([.number] | inside([#{pr_numbers.join(',')}])))'`

File.write('.prs.json', pr_data)
prs = JSON.parse(pr_data)

# 6. Set variable indicating predicted 'major', 'minor', or 'patch' release (based on labels)
level = 0 # patch = 0, minor = 1, major = 2
prs.each do |pr|
  if pr['labels'].include?(BCBREAK)
    level = 2
    break
  end

  if pr['labels'].include?(ENHANCEMENT)
    level = 1
  end
end

# print the recommended release type as the sole output, to be consumed
# by the release process and turned into a variable.
puts RELEASE_TYPES[level]
