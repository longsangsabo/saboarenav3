#!/usr/bin/env python3
"""
SABO ARENA - Code Cleanup Analysis
=================================

Analyze duplicate/obsolete bracket services after introducing
precise DoubleElimination16Service.
"""

def analyze_bracket_services():
    """Analyze bracket-related services for cleanup opportunities"""
    
    services = {
        "double_elimination_16_service.dart": {
            "purpose": "NEW - Precise Double Elimination 16 player logic",
            "status": "✅ ACTIVE - Just created",
            "used_by": ["match_management_tab.dart"],
            "conflicts": None,
            "recommendation": "KEEP - This is our new precise logic"
        },
        
        "universal_match_progression_service.dart": {
            "purpose": "Main progression service for all formats",
            "status": "✅ ACTIVE - Currently used",
            "used_by": ["Multiple tournament widgets", "Match progression"],
            "conflicts": None,
            "recommendation": "KEEP - Core progression service"
        },
        
        "bracket_progression_service.dart": {
            "purpose": "Enhanced bracket progression (old approach)",
            "status": "⚠️ DUPLICATE - Similar to universal service",
            "used_by": None,  # No imports found
            "conflicts": "Overlaps with universal_match_progression_service",
            "recommendation": "🗑️ REMOVE - Not used and duplicates functionality"
        },
        
        "correct_bracket_logic_service.dart": {
            "purpose": "Fix for single elimination logic",
            "status": "⚠️ PARTIAL - Only single elimination",
            "used_by": ["tournament_progress_service.dart", "bracket_management_tab.dart"],
            "conflicts": "Limited to single elimination, DE logic should use new service",
            "recommendation": "🔄 REFACTOR - Keep SE logic, remove DE logic"
        },
        
        "bracket_service.dart": {
            "purpose": "Unknown - need to check",
            "status": "❓ UNKNOWN",
            "used_by": "Need to check",
            "conflicts": "Potential overlap",
            "recommendation": "🔍 INVESTIGATE"
        },
        
        "production_bracket_service.dart": {
            "purpose": "Production bracket logic",
            "status": "❓ UNKNOWN - name suggests it's main service",
            "used_by": "Need to check",
            "conflicts": "Potential overlap with new precise logic",
            "recommendation": "🔍 INVESTIGATE - May conflict with new DE16 service"
        },
        
        "proper_bracket_service.dart": {
            "purpose": "Another bracket service",
            "status": "❓ UNKNOWN",
            "used_by": "Need to check",
            "conflicts": "Name suggests it was meant to be the 'proper' one",
            "recommendation": "🔍 INVESTIGATE"
        }
    }
    
    print("BRACKET SERVICES CLEANUP ANALYSIS")
    print("=" * 50)
    
    for service, info in services.items():
        print(f"\n📁 {service}")
        print(f"   Purpose: {info['purpose']}")
        print(f"   Status: {info['status']}")
        print(f"   Used by: {info['used_by']}")
        if info['conflicts']:
            print(f"   ⚠️ Conflicts: {info['conflicts']}")
        print(f"   💡 Recommendation: {info['recommendation']}")
    
    print("\n" + "=" * 50)
    print("CLEANUP RECOMMENDATIONS:")
    print("-" * 30)
    
    print("🗑️ SAFE TO REMOVE:")
    print("   - bracket_progression_service.dart (not used, duplicates functionality)")
    
    print("\n🔍 NEEDS INVESTIGATION:")
    print("   - bracket_service.dart")
    print("   - production_bracket_service.dart") 
    print("   - proper_bracket_service.dart")
    
    print("\n🔄 NEEDS REFACTORING:")
    print("   - correct_bracket_logic_service.dart")
    print("     * Keep single elimination logic") 
    print("     * Remove/update double elimination logic to use new DE16 service")
    
    print("\n✅ KEEP AS IS:")
    print("   - double_elimination_16_service.dart (new precise logic)")
    print("   - universal_match_progression_service.dart (core progression)")
    
    print("\n📋 NEXT STEPS:")
    print("   1. Check which services are actually imported/used")
    print("   2. Remove unused bracket_progression_service.dart")
    print("   3. Investigate production_bracket_service.dart usage")
    print("   4. Update correct_bracket_logic_service to use DE16 service for DE logic")

if __name__ == "__main__":
    analyze_bracket_services()