import SwiftUI
import SharedKit
import RabbleKit

struct StickyView: View {
    let title: String
    let text: String

    @State var expanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(title)
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.semibold)
                    Spacer()
                    Button {
                        expanded.toggle()
                    } label: {
                        Image(systemName: "inset.filled.topthird.square")
                            .imageScale(.small)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(8)
                .background(Color(hex: "#FBEB61"))

                if expanded {
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text(text)
                        }
                        .font(.system(.subheadline, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(hex: "#FCF4A7"))
                }
            }
            .cornerRadius(4)
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 0)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)

            Spacer(minLength: 0)
        }
        .frame(minWidth: 200, maxWidth: 500, maxHeight: 400)
    }
}

#Preview {
    VStack {
        StickyView(
            title: "Lorem Ipsum",
            text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            expanded: true
        )

        Spacer()
    }
    .padding()
}
