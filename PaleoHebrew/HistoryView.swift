import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("quizHistory") private var quizHistoryData: Data = Data()
    @State private var quizHistory: [QuizResult] = []
    @State private var showingClearConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if quizHistory.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("Quiz History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if !quizHistory.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showingClearConfirmation = true
                        }) {
                            Text("Clear")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .onAppear {
                loadHistory()
            }
            .alert("Clear History", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearHistory()
                }
            } message: {
                Text("Are you sure you want to clear all quiz history? This action cannot be undone.")
            }
        }
    }
    
    // Beautiful empty state view
    var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Large icon with soft background
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
            }
            
            // Header and subheader
            VStack(spacing: 8) {
                Text("No Quiz History")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Complete a quiz to see your history and track your progress over time.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Action button
            Button(action: {
                dismiss() // Close history view to go back to quiz
            }) {
                Text("Start a Quiz")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
    
    // List view for when we have history
    var historyListView: some View {
        List {
            ForEach(quizHistory.sorted(by: { $0.date > $1.date })) { result in
                NavigationLink(destination: QuizDetailView(quiz: result)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(formattedDate(result.date))
                                .font(.headline)
                            
                            Text("\(result.score) out of \(result.total) correct")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Score percentage
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                                .frame(width: 44, height: 44)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(result.score) / CGFloat(result.total))
                                .stroke(
                                    scoreColor(percentage: Double(result.score) / Double(result.total)),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int((Double(result.score) / Double(result.total)) * 100))%")
                                .font(.caption)
                                .bold()
                        }
                    }
                }
            }
        }
    }
    
    private func loadHistory() {
        if let savedData = try? JSONDecoder().decode([QuizResult].self, from: quizHistoryData) {
            quizHistory = savedData
        }
    }
    
    private func clearHistory() {
        quizHistory = []
        quizHistoryData = Data() // Clear the stored data
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func scoreColor(percentage: Double) -> Color {
        switch percentage {
        case 0..<0.4:
            return .red
        case 0.4..<0.7:
            return .orange
        case 0.7..<0.9:
            return .blue
        default:
            return .green
        }
    }
}

struct QuizDetailView: View {
    let quiz: QuizResult
    
    var body: some View {
        List {
            Section(header: Text("Quiz Summary")) {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(formattedDate(quiz.date))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Score")
                    Spacer()
                    Text("\(quiz.score) / \(quiz.total) (\(Int((Double(quiz.score) / Double(quiz.total)) * 100))%)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Letter Results")) {
                ForEach(Array(quiz.letterResults.keys.sorted()), id: \.self) { key in
                    let isCorrect = quiz.letterResults[key] ?? false
                    let parts = key.split(separator: "_")
                    
                    if parts.count == 2 {
                        HStack {
                            Text("\(parts[0]) → \(parts[1])")
                                .font(.system(size: 18))
                            
                            Spacer()
                            
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isCorrect ? .green : .red)
                        }
                    }
                }
            }
        }
        .navigationTitle("Quiz Details")
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView()
}
