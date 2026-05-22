require 'xcodeproj'

project_path = '/Users/nitinsingh/Desktop/RSMS/RSMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'RSMS' } || project.targets.first

rsms_group = project.main_group.children.find { |c| c.name == 'RSMS' || c.path == 'RSMS' }
boutique_manager_group = rsms_group.children.find { |c| c.name == 'Boutiqe Manager' || c.path == 'Boutiqe Manager' }

if boutique_manager_group.nil?
  puts "Could not find Boutique Manager group"
  exit 1
end

file_path = '/Users/nitinsingh/Desktop/RSMS/RSMS/Boutiqe Manager/CreateAssociateView.swift'
file_ref = boutique_manager_group.new_file(file_path)
target.source_build_phase.add_file_reference(file_ref)

project.save
puts "Added CreateAssociateView.swift to Xcode project successfully."
