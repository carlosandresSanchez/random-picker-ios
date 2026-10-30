import SwiftUI

/// The "How many participants?" control: − / + buttons and a number field.
struct CountInputView: View {
    @Binding var count: Int
    var isFocused: FocusState<Bool>.Binding

    /// What the field shows; it can be out of range while the user is typing.
    @State private var typedCount: Int

    init(count: Binding<Int>, isFocused: FocusState<Bool>.Binding) {
        _count = count
        self.isFocused = isFocused
        _typedCount = State(initialValue: count.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("How many participants?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                stepButton("minus", delta: -1)
                TextField("", value: $typedCount, format: .number)
                    .keyboardType(.numberPad)
                    .focused(isFocused)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .frame(width: 110)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
                stepButton("plus", delta: 1)
            }
            Text("Each person picks a number from 1 to \(count)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") { isFocused.wrappedValue = false }
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .onChange(of: typedCount) {
            // Clamp the top right away; the bottom waits until typing ends so "15" can pass through "1".
            if typedCount > DrawState.countRange.upperBound { typedCount = DrawState.countRange.upperBound }
            if DrawState.countRange.contains(typedCount) { count = typedCount }
        }
        .onChange(of: isFocused.wrappedValue) {
            guard !isFocused.wrappedValue else { return }
            count = DrawState.clamped(typedCount)
            typedCount = count
        }
        .onChange(of: count) { typedCount = count }
    }

    private func stepButton(_ symbol: String, delta: Int) -> some View {
        Button {
            count = DrawState.clamped(count + delta)
        } label: {
            Image(systemName: symbol)
                .font(.title2.bold())
                .frame(width: 52, height: 52)
                .background(Color(.secondarySystemGroupedBackground), in: .circle)
        }
        .buttonRepeatBehavior(.enabled)
        .disabled(!DrawState.countRange.contains(count + delta))
    }
}
