import json
import os

colors = {
    'beige': {
        'red': '0x1A', 'green': '0x15', 'blue': '0x14'
    },
    'lightBrown': {
        'red': '0x2A', 'green': '0x24', 'blue': '0x22'
    },
    'darkRed': {
        'red': '0xEE', 'green': '0xD9', 'blue': '0xC4'
    },
    'magenta': {
        'red': '0xA6', 'green': '0x2B', 'blue': '0x54'
    }
}

base_path = './RSMS/Assets.xcassets'

for color_name, dark_components in colors.items():
    json_path = os.path.join(base_path, f'{color_name}.colorset', 'Contents.json')
    if os.path.exists(json_path):
        with open(json_path, 'r') as f:
            data = json.load(f)
            
        for color_item in data.get('colors', []):
            if 'appearances' in color_item:
                for appearance in color_item['appearances']:
                    if appearance.get('appearance') == 'luminosity' and appearance.get('value') == 'dark':
                        # This is the dark mode variant
                        color_item['color']['components']['red'] = dark_components['red']
                        color_item['color']['components']['green'] = dark_components['green']
                        color_item['color']['components']['blue'] = dark_components['blue']
                        
        with open(json_path, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"Updated {color_name} for dark mode.")

