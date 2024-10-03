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
                Text("No items copied yet")
                    .padding()
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(clipboardManager.clipboardItems) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.text)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .padding(.bottom, 2)
                                    
                                    Text("Copied at \(dateFormatter.string(from: item.timestamp))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                // Copy button with modern design
                                Button(action: {
                                    copyToClipboard(item.text)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                }
                                
                                // Delete button with modern design
                                Button(action: {
                                    deleteItem(item)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black)
                                    .shadow(radius: 3)
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 600, height: 400)
        .background(Color.white.opacity(0.5).edgesIgnoringSafeArea(.all))
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

#Preview {
    ContentView()
}
