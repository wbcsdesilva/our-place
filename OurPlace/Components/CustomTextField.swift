import SwiftUI

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var isSecure: Bool = false
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20)
            }
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(CustomTextFieldStyle())
            .autocapitalization(autocapitalization)
            .keyboardType(keyboardType)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .foregroundColor(.primary)
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextField(
            placeholder: "Email",
            text: .constant(""),
            keyboardType: .emailAddress,
            autocapitalization: .none,
            icon: "at"
        )
        
        CustomTextField(
            placeholder: "Password",
            text: .constant(""),
            isSecure: true,
            icon: "key"
        )
        
        CustomTextField(
            placeholder: "Regular text",
            text: .constant(""),
            icon: "textformat"
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
