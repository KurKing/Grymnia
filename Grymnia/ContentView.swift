import SwiftUI

struct ContentView: View {
    @StateObject private var store = GrymniaStore()
    @State private var path: [AppRoute] = []
    @State private var selectedTab: AppTab = .analytics

    var body: some View {
        NavigationStack(path: $path) {
            TabView(selection: $selectedTab) {
                AnalyticsView()
                    .tabItem {
                        Label(AppTab.analytics.title, systemImage: AppTab.analytics.systemImage)
                    }
                    .tag(AppTab.analytics)

                TransactionsView()
                    .tabItem {
                        Label(AppTab.transactions.title, systemImage: AppTab.transactions.systemImage)
                    }
                    .tag(AppTab.transactions)

                SettingsView()
                    .tabItem {
                        Label(AppTab.settings.title, systemImage: AppTab.settings.systemImage)
                    }
                    .tag(AppTab.settings)
            }
            .tint(GrymniaDesign.primary)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .importPreview:
                    ImportPreviewView()
                case .transferReview:
                    TransferReviewView()
                }
            }
        }
        .environmentObject(store)
        .task {
            store.load()
        }
        .onChange(of: store.pendingImport != nil) { _, hasPendingImport in
            if hasPendingImport {
                appendRouteIfNeeded(.importPreview)
            } else {
                path.removeAll { $0 == .importPreview }
            }
        }
        .onChange(of: store.ambiguousTransfers.isEmpty) { _, isEmpty in
            if !isEmpty {
                appendRouteIfNeeded(.transferReview)
            } else {
                path.removeAll { $0 == .transferReview }
            }
        }
        .alert("Grymnia", isPresented: alertBinding) {
            Button("OK", role: .cancel) {
                store.alertMessage = nil
            }
        } message: {
            Text(store.alertMessage ?? "")
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { store.alertMessage != nil },
            set: { if !$0 { store.alertMessage = nil } }
        )
    }

    private func appendRouteIfNeeded(_ route: AppRoute) {
        guard !path.contains(route) else { return }
        path.append(route)
    }
}

private enum AppTab: Hashable {
    case analytics
    case transactions
    case settings

    var title: String {
        switch self {
        case .analytics: "Overview"
        case .transactions: "Transactions"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .analytics: "chart.pie.fill"
        case .transactions: "list.bullet.rectangle.portrait.fill"
        case .settings: "slider.horizontal.3"
        }
    }
}

#Preview {
    ContentView()
}
