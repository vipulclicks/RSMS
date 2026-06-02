require 'xcodeproj'
project_path = 'RSMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)

def remove_file(group, file_name)
  group.files.each do |file|
    if file.path == file_name || file.name == file_name
      file.remove_from_project
      puts "Removed #{file_name} from project"
      return true
    end
  end
  group.groups.each do |subgroup|
    return true if remove_file(subgroup, file_name)
  end
  return false
end

remove_file(project.main_group, 'BoutiqueEventModels.swift')
project.save
