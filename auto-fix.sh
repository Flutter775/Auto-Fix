#!/bin/bash

# Auto Fix Script for Flutter Projects
# Usage: ./auto_fix.sh [path-to-zip]

ZIP_PATH=${1:-"project.zip"}
GROQ_API_KEY=${GROQ_API_KEY:-"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"}

echo "🚀 Starting auto-fix process..."

# Extract ZIP
mkdir -p extracted
unzip -q "$ZIP_PATH" -d extracted
cd extracted

# Fix pubspec.yaml
if [ -f "pubspec.yaml" ]; then
    echo "🔧 Fixing pubspec.yaml..."
    sed -i 's/\t/  /g' pubspec.yaml
    sed -i '/^[[:space:]]*$/d' pubspec.yaml
fi

# Fix build.gradle
if [ -f "android/app/build.gradle" ]; then
    echo "🔧 Fixing app/build.gradle..."
    sed -i 's/compileSdkVersion [0-9]*/compileSdkVersion 34/g' android/app/build.gradle
    sed -i 's/minSdkVersion [0-9]*/minSdkVersion 21/g' android/app/build.gradle
    sed -i 's/targetSdkVersion [0-9]*/targetSdkVersion 34/g' android/app/build.gradle
fi

# Fix gradle-wrapper
if [ -f "android/gradle/wrapper/gradle-wrapper.properties" ]; then
    echo "🔧 Fixing gradle-wrapper.properties..."
    sed -i 's/distributionUrl=.*/distributionUrl=https\\:\\/\\/services.gradle.org\\/distributions\\/gradle-7.6.3-all.zip/g' android/gradle/wrapper/gradle-wrapper.properties
fi

# Run Flutter commands
echo "📦 Running flutter pub get..."
flutter pub get || true

echo "🔨 Building APK..."
flutter build apk --debug 2>&1 | tee build.log || true

# AI Analysis
if [ -n "$GROQ_API_KEY" ]; then
    echo "🤖 Running Groq AI analysis..."
    cat build.log | jq -sR '{"role": "user", "content": .}' > prompt.json
    
    curl -X POST "https://api.groq.com/openai/v1/chat/completions" \
        -H "Authorization: Bearer $GROQ_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "mixtral-8x7b-32768",
            "messages": [
                {"role": "system", "content": "You are a Flutter build expert. Provide specific fixes for errors."},
                '"$(cat prompt.json)"'
            ],
            "temperature": 0.3
        }' > analysis_result.json
    
    echo "✅ AI analysis complete. Check analysis_result.json"
fi

cd ..
zip -r fixed_project.zip extracted/*

echo "✅ Done! Fixed project saved as fixed_project.zip"
