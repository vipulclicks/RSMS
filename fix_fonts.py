import os
import re

def fix_fonts(directory):
    # Regex to remove `design: .xxx` from `.font(.system(...))`
    pattern1 = re.compile(r',\s*design:\s*\.[a-zA-Z]+')
    
    # Regex to remove `.fontDesign(.xxx)` entirely
    pattern2 = re.compile(r'\.fontDesign\(\.[a-zA-Z]+\)')
    
    # Regex to fix `.font(.system(.subheadline, design: .serif))`
    pattern3 = re.compile(r'\(\.system\(\.(.+?),\s*design:\s*\.[a-zA-Z]+\)\)')
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".swift"):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = pattern1.sub('', content)
                new_content = pattern2.sub('', new_content)
                new_content = re.sub(r'\.font\(\.system\(\.(.+?),\s*design:\s*\.[a-zA-Z]+\)\)', r'.font(.\1)', new_content)

                if content != new_content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Fixed fonts in {path}")

fix_fonts('/Users/vipul/RSMS')
