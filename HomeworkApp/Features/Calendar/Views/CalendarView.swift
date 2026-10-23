import SwiftUI
import HomeworkDomain

struct CalendarView: View {
    let store: AssignmentStore
    @State private var model = CalendarViewModel()
    @State private var adding = false
    @State private var selectingMonth = false
    @State private var detailsHidden = false
    @State private var revealTask: Task<Void, Never>?
    @State private var openedID: UUID?
    @State private var preview = AttachmentPreviewModel()
    @Environment(\.appReduceMotion) private var reduceMotion
    @Environment(\.attachmentService) private var attachmentService
    @Environment(\.workspaceToolbar) private var toolbar

    var body: some View {
        TimelineView(.periodic(from: Date(timeIntervalSince1970: 0), by: 60)) { context in
            ScrollView {
                calendarContent(now: context.date)
            }
            .accessibilityIdentifier("calendar.scroll")
            .onChange(of: context.date, initial: true) { _, date in model.rebuild(store.assignments, now: date) }
            .onChange(of: store.assignments) { _, values in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.26)) { model.rebuild(values, now: context.date) }
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.large)
        .environment(\.calendar, model.calendar)
        .toolbar {
            if let toolbar { WorkspaceToolbar(model: toolbar, mode: .calendar) }
        }
        .onChange(of: toolbar?.request) { _, request in
            guard let request, request.mode == .calendar else { return }
            switch request.action {
            case .today: showDetails(); withAnimation(detailAnimation) { model.today() }
            case .add: adding = true
            case .ai: break
            }
        }
        .navigationDestination(isPresented: Binding(get: { openedID != nil }, set: { if !$0 { openedID = nil } })) {
            if let openedID, let assignment = store.assignment(openedID) {
                AssignmentDetailView(assignment: assignment, store: store).id(openedID)
            }
        }
        .navigationDestination(isPresented: $adding) {
            AssignmentDetailView(assignment: store.makeDraft(on: model.selectedDate), isNew: true, store: store)
        }
        .sheet(isPresented: $selectingMonth) {
            MonthYearPicker(calendar: model.calendar, selected: model.month) { selectedMonth in
                showDetails(); withAnimation(detailAnimation) { model.selectMonth(selectedMonth) }
            }
        }
        .onAppear { showDetails() }
        .onDisappear { revealTask?.cancel() }
        .attachmentPreview(preview)
    }

    private func calendarContent(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            CalendarMonthPager(model: model, onPickMonth: { showDetails(); selectingMonth = true },
                               onPagingChanged: pagingChanged, onNavigate: showDetails)
            Divider()
            detailPresentation(now: now)
        }
        .padding().frame(maxWidth: 900).frame(maxWidth: .infinity)
    }

    private func detailPresentation(now: Date) -> some View {
        ZStack(alignment: .topLeading) {
            dayDetails(now: now)
                .id(model.detailRevision)
                .transition(detailTransition)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(detailAnimation, value: model.detailRevision)
        .opacity(detailsHidden ? 0 : 1)
        .blur(radius: detailsHidden && !reduceMotion ? 10 : 0)
        .allowsHitTesting(!detailsHidden).accessibilityHidden(detailsHidden)
    }

    private func dayDetails(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(model.selectedDate, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                .font(.headline).accessibilityIdentifier("calendar.selectedDate")
            let values = model.index.day(model.selectedDate).assignments
            if values.isEmpty {
                ContentUnavailableView("No assignments this day", systemImage: "calendar.badge.checkmark",
                                       description: Text("Add an assignment for the selected date."))
                    .frame(maxWidth: .infinity).accessibilityIdentifier("calendar.empty")
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(values) { assignment in
                        HStack(alignment: .center, spacing: 12) {
                            AssignmentCompletionButton(assignment: assignment) {
                                withAnimation(detailAnimation) { store.toggleCompletion(assignment.id) }
                            }
                            .accessibilityIdentifier("calendar.complete.\(assignment.id)")
                            AssignmentRow(assignment: assignment, now: now, onOpen: { openedID = assignment.id }, onPreview: { reference in
                                Task { await preview.open(reference, service: attachmentService) }
                            })
                        }
                        Divider()
                    }
                }
            }
        }
    }

    private var detailAnimation: Animation { reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.38, dampingFraction: 0.9) }
    private var detailTransition: AnyTransition { reduceMotion ? .opacity : AnyTransition(BlurReplaceTransition(configuration: .downUp)) }

    private func showDetails() {
        revealTask?.cancel(); revealTask = nil
        withAnimation(detailAnimation) { detailsHidden = false }
    }

    private func pagingChanged(_ dragging: Bool) {
        revealTask?.cancel(); revealTask = nil
        if dragging {
            withAnimation(detailAnimation) { detailsHidden = true }
        } else {
            revealTask = Task { @MainActor in
                do { try await Task.sleep(for: .milliseconds(200)) } catch { return }
                guard !Task.isCancelled else { return }
                withAnimation(detailAnimation) { detailsHidden = false }
            }
        }
    }
}
