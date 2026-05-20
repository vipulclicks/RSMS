import os

filepath = '/Users/sidmoon/Desktop/RSMS/RSMS/Features/SalesAssociate/ClientSizePreferencesView.swift'
with open(filepath, 'r') as file:
    content = file.read()

new_content = content.replace('bgCharcoal', 'RSMSTheme.background')
new_content = new_content.replace('cardCharcoal', 'RSMSTheme.surfacePrimary')
new_content = new_content.replace('textIvory', 'RSMSTheme.textPrimary')
new_content = new_content.replace('textSubtle', 'RSMSTheme.textSecondary')
new_content = new_content.replace('Color.white.opacity(0.05)', 'RSMSTheme.border')
new_content = new_content.replace('.environment(\\.colorScheme, .dark)\n', '')

if content != new_content:
    with open(filepath, 'w') as file:
        file.write(new_content)
    print(f'Updated {filepath}')
