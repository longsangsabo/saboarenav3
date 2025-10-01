import os
import re

def fix_format_to_bracket_format():
    """Fix all 'format': 'value' to 'bracket_format': 'value' in service files"""
    
    print('🔧 FIXING FORMAT → BRACKET_FORMAT IN ALL FILES')
    print('=' * 55)
    
    # Files to fix
    files_to_fix = [
        'lib/services/complete_double_elimination_service.dart',
        'lib/services/complete_sabo_de16_service.dart',
        'lib/services/proper_bracket_service.dart',
        'lib/services/correct_bracket_logic_service.dart',
        'lib/services/bracket_progression_service.dart',
    ]
    
    total_replacements = 0
    
    for file_path in files_to_fix:
        if not os.path.exists(file_path):
            print(f'   ❌ File not found: {file_path}')
            continue
            
        print(f'\n📝 Processing {file_path}...')
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # Count existing patterns
            format_count = len(re.findall(r"'format':\s*'[^']*'", content))
            bracket_format_count = len(re.findall(r"'bracket_format':\s*'[^']*'", content))
            
            print(f'   📊 Found: {format_count} format, {bracket_format_count} bracket_format')
            
            # Replace 'format': 'value' with 'bracket_format': 'value' for match data only
            # Keep other uses of 'format' unchanged
            replacements = 0
            
            # Pattern for match data format field
            patterns_to_replace = [
                (r"'format':\s*'double_elimination'", "'bracket_format': 'double_elimination'"),
                (r"'format':\s*'single_elimination'", "'bracket_format': 'single_elimination'"),
                (r"'format':\s*'sabo_de16'", "'bracket_format': 'sabo_de16'"),
                (r"'format':\s*'round_robin'", "'bracket_format': 'round_robin'"),
                (r"'format':\s*'swiss'", "'bracket_format': 'swiss'"),
            ]
            
            for pattern, replacement in patterns_to_replace:
                new_content, count = re.subn(pattern, replacement, content)
                if count > 0:
                    content = new_content
                    replacements += count
                    print(f'   ✅ Replaced {count} instances: {pattern} → {replacement}')
            
            if replacements > 0:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f'   💾 File updated: {replacements} replacements')
                total_replacements += replacements
            else:
                print(f'   ✅ File already correct or no match data found')
                
        except Exception as e:
            print(f'   ❌ Error processing {file_path}: {e}')
    
    print(f'\n🎉 COMPLETED!')
    print(f'   Total replacements: {total_replacements}')
    print(f'   All match data now uses bracket_format column')
    
if __name__ == '__main__':
    fix_format_to_bracket_format()