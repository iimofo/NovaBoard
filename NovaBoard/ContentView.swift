import SwiftUI

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let text: String
}

class ClipboardManager: ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private let filePath: URL
    private let maxItems = 50
    
    init() {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        filePath = documentDirectory.appendingPathComponent("clipboardItems.json")
        
        loadClipboardItems()
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.checkForClipboardChanges()
        }
    }
    
    func checkForClipboardChanges() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        if let copiedText = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !copiedText.isEmpty {
            if !clipboardItems.contains(where: { $0.text == copiedText }) {
                addNewItem(ClipboardItem(
                    id: UUID(),
                    timestamp: Date(),
                    text: copiedText
                ))
            }
        }
    }
    
    private func addNewItem(_ item: ClipboardItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            clipboardItems.insert(item, at: 0)
            if clipboardItems.count > maxItems {
                clipboardItems.removeLast()
            }
            saveClipboardItems()
        }
    }
    
    func removeItem(_ item: ClipboardItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            clipboardItems.removeAll { $0.id == item.id }
            saveClipboardItems()
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
    }
    
    private func saveClipboardItems() {
        do {
            let data = try JSONEncoder().encode(clipboardItems)
            try data.write(to: filePath)
        } catch {
            print("Failed to save clipboard items: \(error)")
        }
    }
    
    private func loadClipboardItems() {
        do {
            let data = try Data(contentsOf: filePath)
            clipboardItems = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to load clipboard items: \(error)")
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    private let dateFormatter: DateFormatter
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
    }
    
    var body: some View {
        VStack {
            if clipboardManager.clipboardItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No items copied yet")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(clipboardManager.clipboardItems) { item in
                            ClipboardItemView(item: item, dateFormatter: dateFormatter)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 400, idealWidth: 600, maxWidth: .infinity,
               minHeight: 300, idealHeight: 400, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct ClipboardItemView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var isCopied = false
    @State private var isDeleting = false
    @State private var shakeOffset: CGFloat = 0
    let item: ClipboardItem
    let dateFormatter: DateFormatter
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.text)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundColor(.white)
                
                Text("Copied at \(dateFormatter.string(from: item.timestamp))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    clipboardManager.copyToClipboard(item)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation {
                            isCopied = false
                        }
                    }
                }) {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(isCopied ? Color.green : Color.blue)
                        .clipShape(Circle())
                        .scaleEffect(isCopied ? 1.2 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Copy to clipboard")
                
                Button(action: {
                    // Stronger shake sequence
                    withAnimation(.interpolatingSpring(stiffness: 4000, damping: 4)) {
                        shakeOffset = 15
                    }
                    
                    // More intense shaking sequence
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.interpolatingSpring(stiffness: 4000, damping: 4)) {
                            shakeOffset = -15
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.interpolatingSpring(stiffness: 4000, damping: 4)) {
                            shakeOffset = 12
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.interpolatingSpring(stiffness: 4000, damping: 4)) {
                            shakeOffset = -12
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.interpolatingSpring(stiffness: 4000, damping: 4)) {
                            shakeOffset = 8
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.interpolatingSpring(stiffness: 4000, damping: 4)) {
                            shakeOffset = -8
                        }
                    }
                    
                    // Final shake and deletion
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.interpolatingSpring(stiffness: 4000, damping: 4)) {
                            shakeOffset = 0
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isDeleting = true
                        }
                        // Delete after shake animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            clipboardManager.removeItem(item)
                        }
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .help("Delete item")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.darkGray))
                .shadow(radius: 3)
        )
        .offset(x: shakeOffset)
        .scaleEffect(isDeleting ? 0.8 : 1.0)
        .opacity(isDeleting ? 0 : 1)
    }
}

@main
struct ClipboardManagerApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(clipboardManager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
}
