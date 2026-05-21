require 'xcodeproj'

project_path = '/Users/sidmoon/Desktop/RSMS/RSMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'RSMS' } || project.targets.first

rsms_group = project.main_group.children.find { |c| c.name == 'RSMS' || c.path == 'RSMS' }
if rsms_group.nil?
  puts "Could not find RSMS group"
  exit 1
end

ui_group = rsms_group.new_group('UI', 'UI')
modifiers_group = ui_group.new_group('Modifiers', 'Modifiers')
components_group = ui_group.new_group('Components', 'Components')
styles_group = ui_group.new_group('Styles', 'Styles')

files = [
  { path: '/Users/sidmoon/Desktop/RSMS/RSMS/UI/Modifiers/RSMSCardModifier.swift', group: modifiers_group },
  { path: '/Users/sidmoon/Desktop/RSMS/RSMS/UI/Components/StatusBadge.swift', group: components_group },
  { path: '/Users/sidmoon/Desktop/RSMS/RSMS/UI/Components/KPICard.swift', group: components_group },
  { path: '/Users/sidmoon/Desktop/RSMS/RSMS/UI/Components/SectionHeader.swift', group: components_group },
  { path: '/Users/sidmoon/Desktop/RSMS/RSMS/UI/Components/CircularProgressView.swift', group: components_group },
  { path: '/Users/sidmoon/Desktop/RSMS/RSMS/UI/Styles/ScaleButtonStyle.swift', group: styles_group }
]

files.each do |f|
  file_ref = f[:group].new_file(f[:path])
  target.source_build_phase.add_file_reference(file_ref)
end

project.save
puts "Added files to Xcode project successfully."
