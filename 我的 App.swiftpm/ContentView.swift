import SwiftUI
import UserNotifications

// --- 資料模型 ---
struct SavedGoal: Identifiable, Codable {
    var id = UUID()
    var title: String
    var totalAmount: Int
    var days: Int
    var iconName: String
    var date: Date
}

class AppState: ObservableObject {
    @AppStorage("goalTitle") var goalTitle: String = ""
    @AppStorage("dailyAmount") var dailyAmount: Int = 100
    @AppStorage("totalSaved") var totalSaved: Int = 0
    @AppStorage("savedDays") var savedDays: Int = 0
    @AppStorage("selectedIcon") var selectedIcon: String = "my_icon1"
    @AppStorage("isGoalSet") var isGoalSet: Bool = false
    @AppStorage("lastSaveDate") var lastSaveDate: String = ""
    
    // 歷史紀錄儲存r
    @Published var history: [SavedGoal] = [] {
        didSet { saveHistory() }
    }
    
    init() {
        loadHistory()
    }
    
    func triggerHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "HistoryData")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "HistoryData"),
           let decoded = try? JSONDecoder().decode([SavedGoal].self, from: data) {
            history = decoded
        }
    }
}

struct ContentView: View {
    @StateObject var state = AppState()
    @State private var currentPath: String = "Welcome"
    @State private var showHistory = false
    
    var body: some View {
        ZStack {
            Color(red: 28/255, green: 28/255, blue: 30/255).ignoresSafeArea()
            
            VStack {
                if !state.isGoalSet {
                    if currentPath == "Welcome" {
                        WelcomeView(currentPath: $currentPath, showHistory: $showHistory)
                    } else {
                        SetupView(state: state)
                    }
                } else {
                    if currentPath == "Success" {
                        SuccessView(state: state, currentPath: $currentPath)
                    } else {
                        MainSavingView(state: state, currentPath: $currentPath)
                    }
                }
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryListView(state: state)
        }
    }
}

// --- 1. 歡迎頁 (標題+圖+按鈕在下) ---
struct WelcomeView: View {
    @Binding var currentPath: String
    @Binding var showHistory: Bool
    
    var body: some View {
        VStack {
            Text("功德基金")
                .font(.system(size: 50, weight: .black))
                .foregroundColor(.yellow)
                .padding(.top, 60)
            
            Spacer()
            
            Image("my_icon1") // 歡迎頁圖示
                .resizable().scaledToFit().frame(width: 250)
            
            Spacer()
            
            VStack(spacing: 15) {
                Button(action: { currentPath = "Setup" }) {
                    Text("開始我的存錢計畫")
                        .font(.title3.bold()).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 20)
                        .background(Color.yellow).cornerRadius(40)
                }
                
                Button(action: { showHistory = true }) {
                    Text("查看完成基金").font(.headline).foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 30).padding(.bottom, 40)
        }
    }
}

// --- 2. 設定頁 (選擇主圖功能) ---
struct SetupView: View {
    @ObservedObject var state: AppState
    @State private var titleInput: String = ""
    @State private var amountInput: String = "100"
    @State private var iconSelection: String = "my_icon1"
    
    let icons = ["my_icon1", "my_icon2", "my_icon3"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("設定目標").font(.system(size: 40, weight: .bold)).foregroundColor(.yellow).padding(.top, 40)
            
            VStack(spacing: 15) {
                TextField("輸入項目名稱", text: $titleInput)
                    .padding().background(Color.white.opacity(0.1)).cornerRadius(15).foregroundColor(.white)
                TextField("輸入每日金額", text: $amountInput).keyboardType(.numberPad)
                    .padding().background(Color.white.opacity(0.1)).cornerRadius(15).foregroundColor(.white)
            }.padding(.horizontal, 30)
            
            Text("選擇樣式").foregroundColor(.white).font(.headline)
            
            HStack(spacing: 20) {
                ForEach(icons, id: \.self) { icon in
                    Image(icon)
                        .resizable().scaledToFit().frame(width: 80)
                        .padding(5)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.yellow, lineWidth: iconSelection == icon ? 3 : 0))
                        .onTapGesture { iconSelection = icon }
                }
            }
            
            Spacer()
            
            VStack(spacing: 15) {
                Button(action: {
                    state.goalTitle = titleInput
                    state.dailyAmount = Int(amountInput) ?? 100
                    state.selectedIcon = iconSelection
                    state.isGoalSet = true
                }) {
                    Text("確定").font(.title3.bold()).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                        .background(Color.yellow).cornerRadius(40)
                }
                
                Button("取消") { state.isGoalSet = false }.foregroundColor(.gray)
            }
            .padding(.horizontal, 30).padding(.bottom, 40)
        }
    }
}

// --- 3. 存錢主頁 ---
struct MainSavingView: View {
    @ObservedObject var state: AppState
    @Binding var currentPath: String
    @State private var animations: [Int] = []
    
    var body: some View {
        VStack {
            VStack(spacing: 10) {
                Text(state.goalTitle).font(.system(size: 55, weight: .black)).foregroundColor(.yellow)
                Text("已累積 \(state.totalSaved)，共 \(state.savedDays) 天").font(.title2).foregroundColor(.white)
                Button(action: { currentPath = "Success" }) {
                    Text("完成目標").font(.headline).padding(.horizontal, 25).padding(.vertical, 8)
                        .background(Capsule().stroke(Color.yellow, lineWidth: 2)).foregroundColor(.yellow)
                }
            }.padding(.top, 50)
            
            Spacer()
            
            ZStack {
                Image(state.selectedIcon).resizable().scaledToFit().frame(width: 250)
                ForEach(animations, id: \.self) { _ in
                    Text("+\(state.dailyAmount)").font(.system(size: 45, weight: .heavy)).foregroundColor(.yellow)
                        .offset(y: -120).transition(.asymmetric(insertion: .identity, removal: .move(edge: .top).combined(with: .opacity)))
                }
            }
            
            Spacer()
            
            Button(action: {
                state.triggerHaptic()
                withAnimation {
                    state.totalSaved += state.dailyAmount
                    animations.append(UUID().hashValue)
                    let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
                    if state.lastSaveDate != today { state.savedDays += 1; state.lastSaveDate = today }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { animations.removeAll() }
            }) {
                Text("存入").font(.title.bold()).foregroundColor(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 25)
                    .background(Color.yellow).cornerRadius(45)
            }.padding(.horizontal, 30).padding(.bottom, 50)
        }
    }
}

// --- 4. 歷史專案列表 (包含刪除功能) ---
struct HistoryListView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) var dismiss
    
    var totalAmount: Int { state.history.reduce(0) { $0 + $1.totalAmount } }
    var totalDays: Int { state.history.reduce(0) { $0 + $1.days } }
    
    var body: some View {
        ZStack {
            Color(red: 28/255, green: 28/255, blue: 30/255).ignoresSafeArea()
            VStack {
                HStack {
                    Button(action: { dismiss() }) { Image(systemName: "chevron.left").font(.title).foregroundColor(.yellow) }
                    Spacer()
                    Text("歷史目標").font(.largeTitle.bold()).foregroundColor(.yellow)
                    Spacer()
                }.padding()
                
                Text("總共 \(state.history.count) 個專案，共 \(totalAmount)元，歷時 \(totalDays) 天")
                    .font(.subheadline).foregroundColor(.white).opacity(0.8)
                
                ScrollView {
                    ForEach(state.history) { goal in
                        HStack {
                            Image(goal.iconName).resizable().scaledToFit().frame(width: 60)
                            VStack(alignment: .leading) {
                                Text(goal.title).font(.headline).foregroundColor(.white)
                                Text("總金額 \(goal.totalAmount)，\(goal.days)天").font(.subheadline).foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: { state.history.removeAll(where: { $0.id == goal.id }) }) {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                        }
                        .padding().background(Color.white.opacity(0.05)).cornerRadius(15).padding(.horizontal)
                    }
                }
            }
        }
    }
}

// --- 5. 完成頁 ---
struct SuccessView: View {
    @ObservedObject var state: AppState
    @Binding var currentPath: String
    
    var body: some View {
        VStack {
            Spacer()
            Text("🎊").font(.system(size: 100))
            Text("恭喜完成").font(.title).foregroundColor(.white)
            Text(state.goalTitle).font(.system(size: 50, weight: .black)).foregroundColor(.yellow)
            Spacer()
            Button(action: {
                let newRecord = SavedGoal(title: state.goalTitle, totalAmount: state.totalSaved, days: state.savedDays, iconName: state.selectedIcon, date: Date())
                state.history.append(newRecord)
                
                state.isGoalSet = false
                state.totalSaved = 0
                state.savedDays = 0
                currentPath = "Welcome"
            }) {
                Text("我好棒").font(.title3.bold()).foregroundColor(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
                    .background(Color.yellow).cornerRadius(40)
            }.padding(.horizontal, 30).padding(.bottom, 50)
        }
    }
}
