import SwiftUI

// Model to hold both text and the time it was copied
struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let text: String
    let timestamp: Date
}

class ClipboardManager: ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private let maxItems = 50  // Maximum items to store
    
    // File path for saving data
    private let filePath: URL
    
    init() {
        // Set up the file path in the app's document directory
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        filePath = documentDirectory.appendingPathComponent("clipboardItems.json")
        
        loadClipboardItems()
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkForClipboardChanges()
        }
    }
    
    func checkForClipboardChanges() {
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            if let copiedText = pasteboard.string(forType: .string) {
                let newItem = ClipboardItem(id: UUID(), text: copiedText, timestamp: Date())
                if !clipboardItems.contains(where: { $0.text == copiedText }) {
                    clipboardItems.insert(newItem, at: 0)
                    if clipboardItems.count > maxItems {
                        clipboardItems.removeLast()
                    }
                    saveClipboardItems()
                }
            }
        }
    }
    
    func removeItem(_ item: ClipboardItem) {
        clipboardItems.removeAll { $0.id == item.id }
        saveClipboardItems()
    }
    
    private func saveClipboardItems() {
        // Save clipboard items to the file
        do {
            let data = try JSONEncoder().encode(clipboardItems)
            try data.write(to: filePath)
        } catch {
            print("Failed to save clipboard items: \(error)")
        }
    }
    
    private func loadClipboardItems() {
        // Load clipboard items from the file
        do {
            let data = try Data(contentsOf: filePath)
            clipboardItems = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to load clipboard items: \(error)")
        }
    }
    
    func clearAll() {
        clipboardItems.removeAll()
        saveClipboardItems()
    }
}

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var searchText = ""
    @State private var selectedItem: ClipboardItem?
    @State private var showingDetail = false
    private let dateFormatter: DateFormatter
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
    }
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.clipboardItems
        }
        return clipboardManager.clipboardItems.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar and controls
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search clips", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if !clipboardManager.clipboardItems.isEmpty {
                    Button(action: {
                        clipboardManager.clearAll()
                    }) {
                        Text("Clear All")
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            // Main content
            if filteredItems.isEmpty {
                VStack {
                    Image(systemName: "clipboard")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .padding()
                    Text(searchText.isEmpty ? "No items copied yet" : "No matches found")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredItems) { item in
                            ClipboardItemView(item: item, dateFormatter: dateFormatter, onCopy: {
                                copyToClipboard(item.text)
                            }, onDelete: {
                                deleteItem(item)
                            })
                            .contextMenu {
                                Button("Copy") {
                                    copyToClipboard(item.text)
                                }
                                Button("Delete") {
                                    deleteItem(item)
                                }
                                Button("Show Details") {
                                    selectedItem = item
                                    showingDetail = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 600, height: 400)
        .sheet(isPresented: $showingDetail) {
            if let item = selectedItem {
                DetailView(item: item, dateFormatter: dateFormatter)
            }
        }
    }
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func deleteItem(_ item: ClipboardItem) {
        clipboardManager.removeItem(item)
    }
}

struct ClipboardItemView: View {
    let item: ClipboardItem
    let dateFormatter: DateFormatter
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text("Copied at \(dateFormatter.string(from: item.timestamp))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 3)
        )
    }
}

struct DetailView: View {
    let item: ClipboardItem
    let dateFormatter: DateFormatter
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Clipboard Details")
                    .font(.title)
                    .bold()
                Spacer()
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Content:")
                    .font(.headline)
                ScrollView {
                    Text(item.text)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                }
                
                Text("Copied at:")
                    .font(.headline)
                Text(dateFormatter.string(from: item.timestamp))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
}
