import os

def replace_in_file(filepath):
    with open(filepath, 'r') as file:
        content = file.read()
    
    new_content = content.replace('RSMSTheme.goldGradient', 'RSMSTheme.primaryGradient')
    new_content = new_content.replace('RSMSTheme.goldLight', 'RSMSTheme.primaryLight')
    new_content = new_content.replace('RSMSTheme.gold', 'RSMSTheme.primary')
    
    if content != new_content:
        with open(filepath, 'w') as file:
            file.write(new_content)
        print(f'Updated {filepath}')

for root, dirs, files in os.walk('/Users/sidmoon/Desktop/RSMS/RSMS'):
    for file in files:
        if file.endswith('.swift'):
            replace_in_file(os.path.join(root, file))
