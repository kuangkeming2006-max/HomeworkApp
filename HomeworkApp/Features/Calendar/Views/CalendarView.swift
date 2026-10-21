import SwiftUI
import HomeworkDomain

struct CalendarView: View {
    let store: AssignmentStore
    @State private var model = CalendarViewModel()
    @State private var adding = false
    @State private var selectingMonth = false
    @State private var actionTarget: Assignment?
    @State private var openedID: UUID?
    @State private var preview = AttachmentPreviewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.attachmentService) private var attachmentService
    @Environment(\.workspaceToolbar) private var toolbar

    var body: some View {
        TimelineView(.periodic(from: Date(timeIntervalSince1970: 0), by: 60)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CalendarMonthPager(model: model, onPickMonth: { selectingMonth = true })
                    Divider()
                    ZStack(alignment: .topLeading) {
                        dayDetails(now: context.date)
                            .id(model.selectedDate)
                            .transition(.opacity)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.26), value: model.selectedDate)
                }
                .padding().frame(maxWidth: 900).frame(maxWidth: .infinity)
            }
            .onChange(of: context.date, initial: true) { _, date in model.rebuild(store.assignments, now: date) }
            .onChange(of: store.assignments) { _, values in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.26)) { model.rebuild(values, now: context.date) }
            }
        }
        .modifier(WorkspacePageFade())
        .navigationTitle("Calendar")
        .environment(\.calendar, model.calendar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let toolbar { WorkspaceToolbar(model: toolbar) }
            }.sharedBackgroundVisibility(.hidden)
        }
        .onChange(of: toolbar?.request) { _, request in
            guard let request, request.mode == .calendar else { return }
            switch request.action {
            case .today: model.today()
            case .add: adding = true
            case .ai: break
            }
        }
        .navigationDestination(isPresented: Binding(get: { openedID != nil }, set: { if !$0 { openedID = nil } })) {
            if let openedID, let assignment = store.assignment(openedID) {
                AssignmentDetailView(assignment: assignment, store: store).id(openedID)
            }
        }
        .sheet(isPresented: $adding) {
            NavigationStack { AssignmentDetailView(assignment: store.makeDraft(on: model.selectedDate), isNew: true, store: store) }
        }
        .sheet(isPresented: $selectingMonth) {
            MonthYearPicker(calendar: model.calendar, selected: model.month) { model.selectMonth($0) }
        }
        .fullScreenCover(item: $actionTarget) { AssignmentStatusSheet(assignment: $0, store: store) }
        .attachmentPreview(preview)
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
                            Button { AppHaptics.selection(); actionTarget = assignment } label: {
                                Image(systemName: assignment.status == .abandoned ? "minus.circle.fill" : assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title2).frame(minWidth: 32, minHeight: 44)
                            }
                            .accessibilityLabel("Change assignment status").accessibilityValue(assignment.status.label)
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
}
