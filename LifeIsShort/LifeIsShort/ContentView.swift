import SwiftUI

private struct EditorRequest: Identifiable {
    let id = UUID()
    var milestone: Milestone?
}

struct ContentView: View {
    @State private var model = AppModel()
    @State private var editor: EditorRequest?
    @State private var pendingVisibility: Milestone?
    @State private var pendingDeletion: Milestone?
    @State private var showingHelp = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Make today count.").font(.title3.weight(.medium)).foregroundStyle(.secondary)
                        MilestoneCard(milestone: model.library.selected.first).frame(height: 205)
                            .accessibilityIdentifier("widgetPreview")
                    }.padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 8, trailing: 20))
                .listRowSeparator(.hidden)
                Section {
                    HStack {
                        Label("Show in Widget", systemImage: "square.stack.3d.up").font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(model.library.selected.count)/3").font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.tint).accessibilityIdentifier("selectionCount")
                    }
                    Button { showingHelp = true } label: {
                        Label("Add a Home Screen widget", systemImage: "plus.square.dashed").font(.subheadline)
                    }
                } footer: { Text("Up to three milestones rotate automatically. Hidden milestones stay saved.") }
                Section {
                    if !model.storageAvailable {
                        ContentUnavailableView {
                            Label("Unable to open milestones", systemImage: "exclamationmark.icloud")
                        } description: { Text("Your saved data is preserved. Please try again.") }
                        actions: { Button("Try Again") { model.reload() } }
                    } else if model.library.milestones.isEmpty {
                        ContentUnavailableView {
                            Label("What are you looking forward to?", systemImage: "sun.horizon")
                        } description: { Text("Save a date, choose a photo, and keep a meaningful moment close.") }
                        actions: {
                            Button("Add a Milestone") { editor = EditorRequest() }
                                .buttonStyle(.borderedProminent).accessibilityIdentifier("emptyAddMilestone")
                        }
                    } else {
                        ForEach(model.library.milestones) { milestoneRow($0) }
                            .onMove { offsets, destination in
                                do { try model.move(from: offsets, to: destination) } catch { model.report(error) }
                            }
                    }
                } header: { Text("Your Milestones") }
            }
            .listStyle(.insetGrouped).navigationTitle("Life Is Short")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !model.library.milestones.isEmpty { EditButton().accessibilityIdentifier("reorderMilestones") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editor = EditorRequest() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add a Milestone").accessibilityIdentifier("addMilestone")
                        .disabled(!model.storageAvailable)
                }
            }
            .sheet(item: $editor) { MilestoneEditor(model: model, milestone: $0.milestone) }
            .confirmationDialog(Localized.text(pendingVisibility != nil ? "Choose a milestone to replace" : "Delete this milestone?"), isPresented: Binding(
                get: { pendingVisibility != nil || pendingDeletion != nil },
                set: { if !$0 { pendingVisibility = nil; pendingDeletion = nil } }
            ), titleVisibility: .visible) {
                if pendingVisibility != nil {
                    ForEach(model.library.selected) { selected in
                        Button(selected.title) {
                            if let pendingVisibility {
                                do { try model.setVisibility(pendingVisibility.id, visible: true, replacing: selected.id) }
                                catch { model.report(error) }
                            }
                            pendingVisibility = nil
                        }
                    }
                } else {
                    Button("Delete Milestone", role: .destructive) {
                        if let pendingDeletion {
                            do { try model.delete(pendingDeletion.id) } catch { model.report(error) }
                        }
                        pendingDeletion = nil
                    }
                }
                Button("Cancel", role: .cancel) { pendingVisibility = nil; pendingDeletion = nil }
            } message: {
                Text(Localized.text(pendingVisibility != nil
                    ? "The milestone you replace stays saved. Only its widget display turns off."
                    : "This removes the milestone from your library and widgets."))
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }
            )) { Button("OK", role: .cancel) { model.errorMessage = nil } }
            message: { Text(model.errorMessage ?? "") }
            .sheet(isPresented: $showingHelp) { widgetHelp }
            .onChange(of: scenePhase) { _, phase in if phase == .active { model.reload() } }
            .onOpenURL { _ in editor = nil; showingHelp = false }
        }
        .tint(Color(red: 0.12, green: 0.43, blue: 0.43))
    }

    private func milestoneRow(_ milestone: Milestone) -> some View {
        HStack(spacing: 12) {
            Button { editor = EditorRequest(milestone: milestone) } label: {
                HStack(spacing: 12) {
                    MilestoneBackground(milestone: milestone).frame(width: 48, height: 58).clipShape(.rect(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(verbatim: milestone.title).font(.body.weight(.medium)).foregroundStyle(.primary).lineLimit(2)
                        Text(milestone.targetDate, format: Date.FormatStyle(date: .abbreviated, time: .omitted,
                            timeZone: TimeZone(identifier: milestone.timeZoneID) ?? .current))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }.contentShape(.rect)
            }
            .buttonStyle(.plain).accessibilityIdentifier("milestone-\(milestone.id.uuidString)")
            Toggle("Show in Widget", isOn: Binding(
                get: { milestone.isVisibleInWidget },
                set: { visible in
                    if visible && model.library.selected.count >= MilestoneLibrary.selectionLimit { pendingVisibility = milestone }
                    else {
                        do { try model.setVisibility(milestone.id, visible: visible) } catch { model.report(error) }
                    }
                }
            ))
            .labelsHidden().accessibilityLabel(Localized.text("Show in Widget") + ": " + milestone.title)
            .accessibilityIdentifier("visibility-\(milestone.id.uuidString)")
        }
        .padding(.vertical, 5)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) { pendingDeletion = milestone }
        }
        .contextMenu {
            Button("Edit Milestone", systemImage: "pencil") { editor = EditorRequest(milestone: milestone) }
            Button("Delete Milestone", systemImage: "trash", role: .destructive) { pendingDeletion = milestone }
        }
    }

    private var widgetHelp: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "square.stack.3d.up.fill").font(.system(size: 44)).foregroundStyle(.tint)
                Text("Keep your milestones close.").font(.largeTitle.bold())
                Text("Touch and hold your Home Screen, tap Edit, then Add Widget. Search for Life Is Short and choose the small or medium widget.")
                    .foregroundStyle(.secondary)
                Text("Your selected milestones rotate about every ten minutes. iOS manages the exact timing.")
                    .font(.callout).foregroundStyle(.secondary)
                Spacer()
            }.padding(28)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingHelp = false } } }
        }
    }
}
