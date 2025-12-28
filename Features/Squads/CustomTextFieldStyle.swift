//
//  CustomTextFieldStyle.swift
//  RunningMan
//
//  Style réutilisable pour les TextFields
//

import SwiftUI

/// Style personnalisé pour les TextFields avec fond glassmorphism
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundColor(.white)
    }
}

// Extension pour faciliter l'usage
extension View {
    func customTextFieldStyle() -> some View {
        self.textFieldStyle(CustomTextFieldStyle())
    }
}
