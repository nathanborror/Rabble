import SwiftUI
import SharedKit
import RabbleKit

struct StickyView<Content: View>: View {
    let kind: Kind
    let title: String
    @State var expanded: Bool
    @ViewBuilder let content: Content

    enum Kind {
        case informative
        case error
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(title)
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        expanded.toggle()
                    } label: {
                        Image(systemName: "inset.filled.topthird.square")
                            .imageScale(.small)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(8)
                .background(titleBackgroundColor)
                .foregroundStyle(.black)

                if expanded {
                    VStack(alignment: .leading) {
                        content
                    }
                    .font(.system(.subheadline, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(backgroundColor)
                }
            }
            .clipShape(.rect)
            .shadow(color: .black.opacity(0.5), radius: 0.5, x: 0, y: 0)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
        }
        .frame(minWidth: 200, maxWidth: 500)
    }

    var backgroundColor: Color {
        switch kind {
        case .informative:
            Color(hex: "#FCF4A7")
        case .error:
            Color(hex: "#FFE4E3")
        }
    }

    var titleBackgroundColor: Color {
        switch kind {
        case .informative:
            Color(hex: "#FBEB61")
        case .error:
            Color(hex: "#FFCFCC")
        }
    }
}

#Preview {
    VStack {
        StickyView(kind: .informative, title: "Lorem Ipsum", expanded: false) {
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
        }
        StickyView(kind: .error, title: "Lorem Ipsum", expanded: true) {
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
            Button("Register") {}
        }
    }
    .padding()
}
