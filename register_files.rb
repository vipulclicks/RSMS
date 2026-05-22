require 'xcodeproj'

project_path = '/Users/kushagra/Library/Mobile Documents/com~apple~CloudDocs/RSMS/RSMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'RSMS' } || project.targets.first

rsms_group = project.main_group.children.find do |c|
  (c.respond_to?(:name) && c.name == 'RSMS') || (c.respond_to?(:path) && c.path == 'RSMS')
end

if rsms_group.nil?
  puts "Could not find RSMS group"
  exit 1
end

# Find or create Features group
features_group = rsms_group.children.find do |c|
  (c.respond_to?(:name) && c.name == 'Features') || (c.respond_to?(:path) && c.path == 'Features')
end
if features_group.nil?
  features_group = rsms_group.new_group('Features', 'Features')
end

# Find or create Client group under Features
client_group = features_group.children.find do |c|
  (c.respond_to?(:name) && c.name == 'Client') || (c.respond_to?(:path) && c.path == 'Client')
end
if client_group.nil?
  client_group = features_group.new_group('Client', 'Client')
end

# Add our new files
files = [
  '/Users/kushagra/Library/Mobile Documents/com~apple~CloudDocs/RSMS/RSMS/Features/Client/ClientPortalView.swift',
  '/Users/kushagra/Library/Mobile Documents/com~apple~CloudDocs/RSMS/RSMS/Features/Client/ClientVideoConsultationSheet.swift'
]

files.each do |file_path|
  existing_ref = client_group.files.find { |f| f.real_path.to_s == file_path }
  if existing_ref.nil?
    file_ref = client_group.new_file(file_path)
    target.source_build_phase.add_file_reference(file_ref)
    puts "Added #{File.basename(file_path)} successfully."
  else
    puts "#{File.basename(file_path)} already exists in target."
  end
end

project.save
puts "Project saved successfully."
