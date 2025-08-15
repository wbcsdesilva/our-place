import SwiftUI

struct CustomButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var backgroundColor: Color = .blue
    var disabledColor: Color = .gray
    var textColor: Color = .white
    var cornerRadius: CGFloat = 12
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                        .font(.body)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? backgroundColor : disabledColor)
            .foregroundColor(textColor)
            .cornerRadius(cornerRadius)
        }
        .disabled(!isEnabled || isLoading)
    }
}

struct CustomSecondaryButton: View {
    let title: String
    let action: () -> Void
    var textColor: Color = .blue
    var fontSize: Font = .body
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(fontSize)
                .foregroundColor(textColor)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomButton(
            title: "Primary Button",
            action: {},
            isEnabled: true
        )
        
        CustomButton(
            title: "Loading Button",
            action: {},
            isLoading: true,
            isEnabled: true
        )
        
        CustomButton(
            title: "Disabled Button",
            action: {},
            isEnabled: false
        )
        
        CustomButton(
            title: "Green Button",
            action: {},
            backgroundColor: .green
        )
        
        CustomSecondaryButton(
            title: "Secondary Button",
            action: {}
        )
    }
    .padding()
}
