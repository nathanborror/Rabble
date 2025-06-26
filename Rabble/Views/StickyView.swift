import SwiftUI
import SharedKit
import RabbleKit

struct StickyView: View {
    let title: String
    let text: String
    let kind: Kind

    enum Kind {
        case informative
        case error
    }

    @State var expanded: Bool

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
                        Text(text)
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
        StickyView(
            title: "Lorem Ipsum",
            text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            kind: .informative,
            expanded: false
        )
        StickyView(
            title: "Lorem Ipsum",
            text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            kind: .error,
            expanded: true
        )
    }
    .padding()
}
