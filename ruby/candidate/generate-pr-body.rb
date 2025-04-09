# frozen_string_literal: true

require 'yaml'
require 'json'

BCBREAK = 'bcbreak'
ENHANCEMENT = 'enhancement'
BUG = 'bug'

VERSION_FILE = 'version.yml'
PR_FILE = '.prs.json'

SECTION_TITLE = {
  bcbreak: "Breaking Changes",
  feature: "New Features",
  bug: "Bug Fixes",
}

def pr_type(pr)
  if pr['labels'].include?(BCBREAK)
    :bcbreak
  elsif pr['labels'].include?(ENHANCEMENT)
    :feature
  elsif pr['labels'].include?(BUG)
    :bug
  else
    nil
  end
end

def jira_url(issue)
  "https://jira.mongodb.org/browse/#{issue}"
end

def release_type(version)
  if version.end_with?('0.0')
    'major'
  elsif version.end_with?('.0')
    'minor'
  else
    'patch'
  end
end

# returns [ jira-issue, pr title ], assuming an original pr
# title of the format "JIRA-12345 PR Title (#1234)"
def title(pr)
  title = pr['title'].gsub(/\(#\d+\)/, '').strip

  if title =~ /^(\w+-\d+) (.*)$/
    [ $1, $2 ]
  else
    [ nil, title ]
  end
end

def extract_summary(pr)
  summary = []
  accumulating = false
  level = nil

  pr['body'].lines.each do |line|
    # a header of any level titled "summary" will begin the summary
    if !accumulating && line =~ /^(\#+)\s+summary\s+$/i
      accumulating = true
      level = $1.length

    # a header of any level less than or equal to the summary header's
    # level will end the summary
    elsif accumulating && line =~ /^\#{1,#{level}}\s+/
      break

    # otherwise, the line is part of the summary
    elsif accumulating
      summary << line
    end
  end

  summary.any? ? summary.join.strip : nil
end

# 1. read current version. The version.yml file should reflect the
#    _new_ current version by this point.
data = YAML.load_file(VERSION_FILE)
product = data['product']
package = data['package']
version = data['current']

# 2. read saved pr data
prs = JSON.load_file(PR_FILE)

# 3. extract and organize information from the prs
decorated = prs.map do |pr|
  jira_issue, pr_title = title(pr)
  summary = extract_summary(pr)

  pr.merge('jira' => jira_issue,
           'short-title' => pr_title,
           'summary' => summary)
end

# 4. organize them by type
grouped = decorated.group_by { |pr| pr_type(pr) }

# 5. format them all as release notes
puts <<INTRO
#{product} #{version} is a new #{release_type(version)} release.

Install it via RubyGems at a command-line:

~~~
gem install -v #{version} #{package}
~~~

Or by adding it to your Gemfile:

~~~
gem '#{package}', '#{version}'
~~~

Notable changes in this release are:

INTRO

%i[ bcbreak feature bug ].each do |type|
  next unless grouped[type]

  puts "\## #{SECTION_TITLE[type]}"
  puts

  summarized, unsummarized = grouped[type].partition { |pr| pr['summary'] }

  summarized.each do |pr|
    print '### '
    print "[#{pr['jira']}](#{jira_url(pr['jira'])}) " if pr['jira']
    puts "#{pr['short-title']} ([PR](#{pr['url']}))"
    puts
    puts pr['summary']
  end

  if summarized.any? && unsummarized.any?
    puts
    puts "### Other #{SECTION_TITLE[type]}"
    puts
  end

  unsummarized.each do |pr|
    print '* '
    print "[#{pr['jira']}](#{jira_url(pr['jira'])}) " if pr['jira']
    puts "#{pr['short-title']} ([PR](#{pr['url']}))"
  end

  puts
end
