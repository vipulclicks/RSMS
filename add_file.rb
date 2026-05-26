require 'xcodeproj'
project_path = 'RSMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first
group = project.main_group.find_subpath(File.join('RSMS', 'Features', 'BoutiqueManager'), true)
file_ref = group.new_reference('PlanogramGeneratorView.swift')
target.source_build_phase.add_file_reference(file_ref)
project.save
