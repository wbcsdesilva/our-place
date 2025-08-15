import SwiftUI

struct FormSectionView<Content: View>: View {
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 15, horizontalPadding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: spacing) {
            content
        }
        .padding(.horizontal, horizontalPadding)
    }
}

#Preview {
    FormSectionView(spacing: 20, horizontalPadding: 30) {
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
        
        CustomButton(
            title: "Submit",
            action: {}
        )
    }
    .padding()
}
