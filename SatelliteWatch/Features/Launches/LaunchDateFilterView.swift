import SwiftUI

struct LaunchDateFilterView: View {
    @Bindable var viewModel: LaunchesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Start",
                        selection: $viewModel.draftStartDate,
                        displayedComponents: .date
                    )
                    .disabled(isSubmitting)
                    .accessibilityIdentifier("filter-start-date")

                    DatePicker(
                        "End",
                        selection: $viewModel.draftEndDate,
                        displayedComponents: .date
                    )
                    .disabled(isSubmitting)
                    .accessibilityIdentifier("filter-end-date")
                } footer: {
                    if viewModel.canApplyDraftFilter {
                        Text("Dates use your local calendar and include the full end day.")
                            .foregroundStyle(AppColor.secondaryText)
                    } else {
                        Text("Start date must be on or before end date.")
                            .foregroundStyle(AppColor.danger)
                    }
                }
            }
            .navigationTitle("Filter launches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        submit {
                            await viewModel.applyFilter()
                        }
                    }
                    .disabled(!viewModel.canApplyDraftFilter || isSubmitting)
                    .accessibilityIdentifier("filter-apply")
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Clear filter") {
                        submit {
                            await viewModel.clearFilter()
                        }
                    }
                    .disabled(isSubmitting)
                    .accessibilityIdentifier("filter-clear")
                }
            }
        }
        .interactiveDismissDisabled(isSubmitting)
    }

    private func submit(_ action: @escaping @MainActor () async -> Void) {
        guard !isSubmitting else { return }
        isSubmitting = true
        dismiss()
        Task {
            await action()
        }
    }
}

#if DEBUG
#Preview {
    LaunchDateFilterView(
        viewModel: .preview(launches: MockSpaceXService.previewLaunches)
    )
}
#endif
