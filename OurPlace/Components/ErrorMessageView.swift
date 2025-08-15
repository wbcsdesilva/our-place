import SwiftUI

struct ErrorMessageView: View {
    let message: String
    var alignment: Alignment = .center
    var padding: EdgeInsets = EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
    
    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
            .multilineTextAlignment(alignment == .center ? .center : .leading)
            .frame(maxWidth: .infinity, alignment: alignment)
            .padding(padding)
    }
}

#Preview {
    VStack(spacing: 20) {
        ErrorMessageView(
            message: "This is a centered error message",
            alignment: .center
        )
        
        ErrorMessageView(
            message: "This is a left-aligned error message that might be longer and wrap to multiple lines",
            alignment: .leading
        )
        
        ErrorMessageView(
            message: "Custom padding error message",
            alignment: .center,
            padding: EdgeInsets(top: 10, leading: 30, bottom: 10, trailing: 30)
        )
    }
    .padding()
}
