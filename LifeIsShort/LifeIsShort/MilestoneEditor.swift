import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

private struct PickedPhoto: Transferable, Sendable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            let copy = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.copyItem(at: received.file, to: copy)
            return PickedPhoto(url: copy)
        }
    }
}

struct MilestoneEditor: View {
    let model: AppModel
    private let existing: Milestone?
    private let id: UUID
    private let zone: TimeZone
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var targetMode: TargetMode
    @State private var date: Date
    @State private var birthDate: Date
    @State private var age: String
    @State private var includesTime: Bool
    @State private var time: Date
    @State private var countdownMode: CountdownMode
    @State private var unit: CountdownUnit
    @State private var visible: Bool
    @State private var photoFilename: String?
    @State private var photoItem: PhotosPickerItem?
    @State private var importing = false
    @State private var errorMessage: String?
    @State private var pendingSave: Milestone?
    private enum InputField: Hashable { case title, age }
    @FocusState private var focusedField: InputField?

    init(model: AppModel, milestone: Milestone?) {
        self.model = model; existing = milestone; id = milestone?.id ?? UUID()
        let zone = TimeZone(identifier: milestone?.timeZoneID ?? TimeZone.current.identifier) ?? .current
        self.zone = zone
        let target = milestone?.targetDate ?? Date.now.addingTimeInterval(86_400)
        _title = State(initialValue: milestone?.title ?? "")
        _targetMode = State(initialValue: milestone?.targetMode ?? .date)
        _date = State(initialValue: target)
        let birth = milestone?.birthDate ?? CivilDate(year: 2000, month: 1, day: 1)
        _birthDate = State(initialValue: (try? TargetResolver.resolve(day: birth, timeZoneID: zone.identifier)) ?? .now)
        _age = State(initialValue: milestone?.targetAge.map(String.init) ?? "")
        _includesTime = State(initialValue: milestone?.includesTime ?? false)
        _time = State(initialValue: target)
        _countdownMode = State(initialValue: milestone?.countdownMode ?? .units)
        _unit = State(initialValue: milestone?.unit ?? .days)
        _visible = State(initialValue: milestone?.isVisibleInWidget ?? (model.library.selected.count < 3))
        _photoFilename = State(initialValue: milestone?.photoFilename)
    }

    private func makeMilestone() throws -> Milestone {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        let clock = calendar.dateComponents([.hour, .minute], from: time)
        let hour = includesTime ? clock.hour : nil
        let birth = CivilDate(birthDate, timeZone: zone)
        let target: Date
        let parsedAge: Int?
        if targetMode == .age {
            guard let value = Int(age.trimmingCharacters(in: .whitespaces)) else { throw MilestoneError.invalidAge }
            parsedAge = value
            target = try TargetResolver.birthday(birthDate: birth, targetAge: value, hour: hour,
                                                  minute: clock.minute ?? 0, timeZoneID: zone.identifier)
        } else {
            parsedAge = nil
            target = try TargetResolver.resolve(day: CivilDate(date, timeZone: zone), hour: hour,
                                                minute: clock.minute ?? 0, timeZoneID: zone.identifier)
        }
        let value = Milestone(id: id, title: title, targetDate: target, timeZoneID: zone.identifier,
                              targetMode: targetMode, birthDate: targetMode == .age ? birth : nil,
                              targetAge: parsedAge, includesTime: includesTime, photoFilename: photoFilename,
                              countdownMode: countdownMode, unit: unit, isVisibleInWidget: visible)
        try value.validate()
        return value
    }

    private var preview: Milestone {
        (try? makeMilestone()) ?? Milestone(title: title.isEmpty ? Localized.text("Your milestone") : title,
                                          targetDate: date, timeZoneID: zone.identifier, photoFilename: photoFilename,
                                          countdownMode: countdownMode, unit: unit)
    }

    var body: some View {
        let photoLabel = Localized.text(photoFilename == nil ? "Choose Photo" : "Change Photo")
        NavigationStack {
            Form {
                Section {
                    MilestoneCard(milestone: preview).frame(height: 190)
                        .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                    PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                        Label(photoLabel, systemImage: "photo")
                    }.accessibilityIdentifier("choosePhoto")
                    if importing { ProgressView("Preparing your photo…") }
                    if photoFilename != nil {
                        Button("Use Default Background", role: .destructive) { photoItem = nil; photoFilename = nil }
                            .accessibilityIdentifier("removePhoto")
                    }
                }
                Section {
                    TextField("Title", text: $title).focused($focusedField, equals: .title).accessibilityIdentifier("milestoneTitle")
                    Picker("Set Target By", selection: $targetMode) {
                        Text("Date").tag(TargetMode.date); Text("Age").tag(TargetMode.age)
                    }.accessibilityIdentifier("targetMode")
                    if targetMode == .date {
                        DatePicker("Target Date", selection: $date, displayedComponents: .date)
                    } else {
                        DatePicker("Birth Date", selection: $birthDate, in: ...Date.now, displayedComponents: .date)
                        TextField("Target Age", text: $age).keyboardType(.numberPad).focused($focusedField, equals: .age).accessibilityIdentifier("targetAge")
                    }
                    Toggle("Include a Time", isOn: $includesTime)
                    if includesTime { DatePicker("Target Time", selection: $time, displayedComponents: .hourAndMinute) }
                    LabeledContent("Time Zone", value: zone.identifier)
                    if let target = try? makeMilestone() {
                        LabeledContent("Countdown To") {
                            Text(target.targetDate, format: Date.FormatStyle(date: .abbreviated, time: .shortened, timeZone: zone))
                                .font(.caption)
                        }
                    }
                } header: { Text("Milestone") } footer: {
                    Text("Without a time, the countdown ends at the start of that date. The saved time zone stays the same when you travel.")
                }
                Section {
                    Picker("Display", selection: $countdownMode) {
                        Text("One Unit").tag(CountdownMode.units); Text("Days + Clock").tag(CountdownMode.clock)
                    }.accessibilityIdentifier("countdownMode")
                    if countdownMode == .units {
                        Picker("Unit", selection: $unit) {
                            Text("Days").tag(CountdownUnit.days); Text("Weeks").tag(CountdownUnit.weeks)
                            Text("Hours").tag(CountdownUnit.hours)
                        }
                    }
                    Toggle("Show in Widget", isOn: $visible).accessibilityIdentifier("editorVisibility")
                } header: { Text("Countdown") } footer: {
                    Text("This is a milestone you choose, not a prediction of death. Reached milestones stop at zero.")
                }
            }
            .environment(\.timeZone, zone)
            .navigationTitle(Localized.text(existing == nil ? "New Milestone" : "Edit Milestone"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }.accessibilityIdentifier("dismissKeyboard")
                }
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold).disabled(importing).accessibilityIdentifier("saveMilestone")
                }
            }
            .alert("Please check your milestone", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) { Button("OK", role: .cancel) { errorMessage = nil } }
            message: { Text(errorMessage ?? "") }
            .confirmationDialog("Choose a milestone to replace", isPresented: Binding(
                get: { pendingSave != nil }, set: { if !$0 { pendingSave = nil } }
            ), titleVisibility: .visible) {
                ForEach(model.library.selected.filter { $0.id != id }) { selected in
                    Button(selected.title) {
                        if let pendingSave { persist(pendingSave, replacing: selected.id) }
                    }
                }
                Button("Cancel", role: .cancel) { pendingSave = nil }
            } message: { Text("The milestone you replace stays saved. Only its widget display turns off.") }
            .task(id: photoItem) {
                guard let item = photoItem else { importing = false; return }
                importing = true
                defer { if photoItem == item { importing = false } }
                do {
                    guard let photo = try await item.loadTransferable(type: PickedPhoto.self) else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                    defer { try? FileManager.default.removeItem(at: photo.url) }
                    let filename = try await model.importPhoto(at: photo.url)
                    if !Task.isCancelled && photoItem == item { photoFilename = filename }
                } catch {
                    if !Task.isCancelled {
                        errorMessage = Localized.text("The photo could not be imported. Please try another photo or check your connection.")
                    }
                }
            }
        }
    }

    private func save() {
        do {
            let value = try makeMilestone()
            let alreadySelected = model.library.selected.contains { $0.id == value.id }
            if value.isVisibleInWidget && !alreadySelected && model.library.selected.count >= 3 { pendingSave = value }
            else { persist(value) }
        } catch { errorMessage = Localized.error(error) }
    }
    private func persist(_ value: Milestone, replacing replacement: UUID? = nil) {
        do { try model.save(value, replacing: replacement); dismiss() }
        catch { pendingSave = nil; errorMessage = Localized.error(error) }
    }
}
