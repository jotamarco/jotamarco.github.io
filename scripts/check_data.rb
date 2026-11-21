#!/usr/bin/env ruby
# Checks the website data files (_data/*.yml) before publishing.
# Usage (from the repository folder):   ruby scripts/check_data.rb
# Works with the Ruby that ships with macOS; no gems needed.
require "yaml"

ROOT = File.expand_path("..", __dir__)
$errors = []
$warnings = []

def err(file, i, msg)
  $errors << "#{file}#{i ? " (entry #{i + 1})" : ""}: #{msg}"
end

def warn!(file, i, msg)
  $warnings << "#{file}#{i ? " (entry #{i + 1})" : ""}: #{msg}"
end

def load(name)
  path = File.join(ROOT, "_data", "#{name}.yml")
  YAML.load_file(path)
rescue Psych::SyntaxError => e
  $errors << "#{name}.yml: YAML syntax error — #{e.message.sub(/^\(.*?\): /, "")}"
  nil
end

def need(file, list, keys)
  unless list.is_a?(Array)
    err(file, nil, "should be a list of entries, each starting with '- ' (check the indentation and that no entry was pasted inside the # comment block)")
    return
  end
  list.each_with_index do |e, i|
    unless e.is_a?(Hash)
      err(file, i, "should be a block of 'key: value' lines")
      next
    end
    keys.each { |k| err(file, i, "missing '#{k}'") if e[k].nil? || e[k].to_s.strip.empty? }
  end
end

profile = load("profile") || {}
topics = (profile["topics"] || {}).keys

# Publications
pubs = load("publications")
if pubs
  need("publications.yml", pubs, %w[year type title authors venue topics])
  pubs.each_with_index do |p, i|
    next unless p.is_a?(Hash)
    t = p["type"]
    err("publications.yml", i, "type '#{t}' must be one of journal, conference, workshop, preprint, report") unless %w[journal conference workshop preprint report].include?(t)
    Array(p["topics"]).each { |k| err("publications.yml", i, "unknown topic '#{k}' (topics are defined in profile.yml: #{topics.join(", ")})") unless topics.include?(k.to_s) }
    if p["pdf"] && !File.exist?(File.join(ROOT, "Papers", p["pdf"].to_s))
      err("publications.yml", i, "PDF '#{p["pdf"]}' not found in the Papers/ folder")
    end
    warn!("publications.yml", i, "doi should not start with http — write only 10.xxxx/…") if p["doi"].to_s.start_with?("http")
    warn!("publications.yml", i, "'#{p["title"]}' has no PDF, DOI or link") unless p["pdf"] || p["doi"] || p["url"] || p["author_copy"] || p["preprint"]
    warn!("publications.yml", i, "author list does not contain '#{profile["author_name"]}', so your name won't be highlighted") if profile["author_name"] && !p["authors"].to_s.include?(profile["author_name"])
  end
end

need("news.yml", load("news"), %w[when kind text])
need("awards.yml", load("awards"), %w[year title])
need("teams.yml", load("teams"), %w[name full_name years])
software = load("software")
need("software.yml", software, %w[year name description])
Array(software).each_with_index do |sw, i|
  next unless sw.is_a?(Hash) && sw["paper"] && pubs.is_a?(Array)
  q = sw["paper"].to_s.downcase
  hit = pubs.any? { |p| p.is_a?(Hash) && [p["title"], p["authors"], p["venue"], p["year"]].join(" ").downcase.include?(q) }
  warn!("software.yml", i, "paper search term '#{sw["paper"]}' does not match any publication") unless hit
end

teaching = load("teaching")
if teaching
  need("teaching.yml → current", teaching["current"], %w[programme level courses])
  need("teaching.yml → previous", teaching["previous"], %w[course programme years])
  need("teaching.yml → training", teaching["training"], %w[year title])
end

sup = load("supervision")
if sup
  progs = (sup["programmes"] || {}).keys
  need("supervision.yml → phd", sup["phd"], %w[since name topic])
  need("supervision.yml → msc_ongoing", sup["msc_ongoing"], %w[since name title programme])
  need("supervision.yml → msc_concluded", sup["msc_concluded"], %w[year name title programme])
  %w[msc_ongoing msc_concluded].each do |k|
    Array(sup[k]).each_with_index do |m, i|
      next unless m.is_a?(Hash)
      warn!("supervision.yml → #{k}", i, "programme '#{m["programme"]}' is not one of the codes in 'programmes' (#{progs.join(", ")}); it will be shown as written") unless progs.include?(m["programme"].to_s)
      warn!("supervision.yml → #{k}", i, "role should be Advisor or Co-advisor") if m["role"] && !%w[Advisor Co-advisor].include?(m["role"])
    end
  end
end

proj = load("projects")
if proj
  need("projects.yml → ongoing", proj["ongoing"], %w[years name role funding summary])
  need("projects.yml → previous", proj["previous"], %w[years name role funding summary])
end

svc = load("service")
if svc
  need("service.yml → management", svc["management"], %w[years role])
  need("service.yml → events", svc["events"], %w[year title])
end

talks = load("talks")
need("talks.yml", talks, %w[year kind title venue scope])
Array(talks).each_with_index { |t, i| err("talks.yml", i, "scope must be abroad, national or uminho") if t.is_a?(Hash) && !%w[abroad national uminho].include?(t["scope"]) }

juries = load("juries")
need("juries.yml", juries, %w[year level role title candidate programme])
Array(juries).each_with_index { |j, i| err("juries.yml", i, "role must be examiner or president") if j.is_a?(Hash) && !%w[examiner president].include?(j["role"]) }

rev = load("reviewing")
if rev
  need("reviewing.yml → journals", rev["journals"], %w[name years])
  need("reviewing.yml → tpc", rev["tpc"], %w[acronym name])
end

puts "Checked _data/*.yml"
puts "  #{Array(pubs).size} publications, #{Array(talks).size} talks, #{Array(juries).size} juries" if pubs
$warnings.each { |w| puts "  warning: #{w}" }
if $errors.empty?
  puts "OK — no errors found."
else
  $errors.each { |e| puts "  ERROR: #{e}" }
  puts "#{$errors.size} error(s). Fix them before publishing."
  exit 1
end
