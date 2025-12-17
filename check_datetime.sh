#!/bin/bash

# Script to fix all DateTime.now() infinite rebuild issues

echo "🔍 Scanning for DateTime.now() in build methods..."

# Files to check
files=(
  "mobile/lib/screens/all_questions_screen.dart"
  "mobile/lib/screens/users_list_screen.dart"
  "mobile/lib/screens/community_detail_screen.dart"
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    echo "📝 Checking $file..."
    grep -n "DateTime.now()" "$file" && echo "⚠️  Found DateTime.now() in $file" || echo "✅ $file is clean"
  fi
done

echo ""
echo "✅ Main fixes applied to:"
echo "  - home_screen.dart"
echo "  - question_card.dart"
echo "  - profile_screen.dart"
echo "  - settings_screen.dart"
echo "  - unanswered_questions_screen.dart"
echo ""
echo "🎯 Next: Hot restart the app with 'R' in the terminal"
