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
        TextInput(
            title: "Email",
            placeholder: "Enter your email",
            text: .constant(""),
            keyboardType: .emailAddress,
            autocapitalization: .never,
            icon: "at"
        )

        TextInput(
            title: "Password",
            placeholder: "Enter your password",
            text: .constant(""),
            isSecure: true,
            icon: "lock"
        )

        CustomButton(
            title: "Submit",
            action: {}
        )
    }
    .padding()
}
