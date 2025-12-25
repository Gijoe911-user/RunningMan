#!/bin/bash

# Script pour remplacer toutes les occurrences de .authentication par .auth
# À exécuter dans le terminal

echo "🔧 Remplacement de .authentication par .auth..."

# Fichiers à modifier
files=(
    "AuthViewModel.swift"
    "BiometricAuthHelper.swift"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "📝 Modification de $file..."
        sed -i '' 's/category: \.authentication/category: .auth/g' "$file"
        echo "✅ $file modifié"
    else
        echo "⚠️  $file introuvable"
    fi
done

echo "🎉 Remplacement terminé !"
