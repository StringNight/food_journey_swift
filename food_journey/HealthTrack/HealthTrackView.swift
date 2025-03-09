import SwiftUI

// 添加CompleteProfile模型来匹配后端的响应结构
extension FoodJourneyModels {
    struct CompleteProfile: Codable {
        let schema_version: String
        let user_profile: UserProfileData
        let health_profile: HealthProfile
        let diet_profile: DietProfile
        let fitness_profile: FitnessProfile
        let extended_attributes: [String: String]?
        
        struct UserProfileData: Codable {
            let id: String
            let username: String
            let nickname: String?
            let avatar_url: String?
            let birth_date: String?
            let age: Int?
            let gender: String?
            let created_at: String
            let updated_at: String
        }
        
        struct HealthProfile: Codable {
            let height: Double?
            let weight: Double?
            let body_fat_percentage: Double?
            let muscle_mass: Double?
            let bmr: Int?
            let tdee: Int?
            let health_conditions: [String]?
            let bmi: Double?
            let water_ratio: Double?
        }
        
        struct DietProfile: Codable {
            let cooking_skill_level: String?
            let favorite_cuisines: [String]?
            let dietary_restrictions: [String]?
            let allergies: [String]?
            let nutrition_goals: [String: Double]?
            let calorie_preference: Int?
            let eating_habits: String?
            let diet_goal: String?
        }
        
        struct FitnessProfile: Codable {
            let fitness_level: String?
            let exercise_frequency: Int?
            let preferred_exercises: [String]?
            let fitness_goals: [String]?
            let short_term_goals: [String]?
            let long_term_goals: [String]?
            let goal_progress: Double?
            let training_type: String?
            let training_progress: Double?
            let muscle_group_analysis: [String: String]?
            let sleep_duration: Double?
            let deep_sleep_percentage: Double?
            let fatigue_score: Int?
            let recovery_activities: [String]?
            let performance_metrics: [String: Double]?
            let exercise_history: [[String: String]]?
            let training_time_preference: String?
            let equipment_preferences: [String]?
        }
    }
}

// 添加视图模型来管理健身追踪器数据
class HealthTrackViewModel: ObservableObject {
    // 目标相关状态
    @Published var shortTermGoal: String = "增加5kg肌肉"
    @Published var longTermGoal: String = "体脂降至15%"
    
    // 目标数值
    @Published var targetMuscleGain: Double = 5.0 // 目标增肌量(kg)
    @Published var initialMuscleWeight: Double = 35.0 // 初始肌肉重量(kg)
    @Published var targetBodyFat: Double = 15.0 // 目标体脂率(%)
    @Published var initialBodyFat: Double = 22.0 // 初始体脂率(%)
    
    // 当前身体数据
    @Published var currentMuscleWeight: Double = 39.0 // 当前肌肉重量(kg)
    @Published var currentBodyFat: Double = 20.0 // 当前体脂率(%)
    @Published var currentWeight: Double = 72.0 // 当前体重(kg)
    
    // 训练数据
    @Published var trainingType: String = "深蹲"
    @Published var completedSets: Int = 3
    @Published var totalSets: Int = 5
    @Published var muscleGroup: String = "腿部"
    
    // 添加防抖动机制
    private var lastRefreshTime: Date = Date(timeIntervalSince1970: 0)
    private let minRefreshInterval: TimeInterval = 5.0 // 最小刷新间隔5秒
    
    // 添加一个标志，跟踪是否已经加载过数据
    private var hasLoadedInitialData: Bool = false
    
    // 刷新数据
    func refreshData() async {
        // 检查是否需要刷新 - 如果已经加载过初始数据且距离上次刷新时间不足最小间隔，则跳过
        let now = Date()
        if hasLoadedInitialData && now.timeIntervalSince(lastRefreshTime) < minRefreshInterval {
            print("跳过刷新：刷新间隔过短")
            return
        }
        
        // 更新最后刷新时间
        lastRefreshTime = now
        
        do {
            // 获取用户完整档案数据
            let profileResponse: FoodJourneyModels.CompleteProfile = try await NetworkService.shared.request(
                endpoint: "/profile",
                method: "GET",
                requiresAuth: true
            )
            
            // 更新用户身体数据
            await MainActor.run {
                // 更新身体数据
                if let weight = profileResponse.health_profile.weight {
                    self.currentWeight = weight
                }
                if let bodyFat = profileResponse.health_profile.body_fat_percentage {
                    self.currentBodyFat = bodyFat
                }
                if let muscleMass = profileResponse.health_profile.muscle_mass {
                    self.currentMuscleWeight = muscleMass
                }
                
                // 更新训练相关数据
                if let trainingType = profileResponse.fitness_profile.training_type {
                    self.trainingType = trainingType
                }
                
                // 从肌肉群分析中获取第一个肌肉群
                if let muscleGroupAnalysis = profileResponse.fitness_profile.muscle_group_analysis,
                   let firstKey = muscleGroupAnalysis.keys.first {
                    self.muscleGroup = firstKey
                }
                
                // 如果有训练进度信息，更新组数信息
                if let progress = profileResponse.fitness_profile.training_progress {
                    // 这里假设训练进度是完成组数占总组数的百分比
                    if progress > 0 && self.totalSets > 0 {
                        self.completedSets = Int(Double(self.totalSets) * progress / 100.0)
                    }
                }
                
                // 标记已加载初始数据
                self.hasLoadedInitialData = true
            }
            
            print("健身追踪数据刷新成功")
        } catch let NetworkError.serverError(message) {
            print("获取健身追踪数据失败 - 服务器错误: \(message)")
            
            // 如果是特定错误，比如用户档案不存在，我们可以创建一个
            if message.contains("获取用户档案失败") {
                do {
                    // 尝试通过更新基本信息来创建用户档案
                    try await initializeUserProfile()
                } catch {
                    print("初始化用户配置文件失败: \(error.localizedDescription)")
                }
            }
        } catch {
            print("获取健身追踪数据失败: \(error.localizedDescription)")
        }
    }
    
    // 初始化用户配置文件
    private func initializeUserProfile() async throws {
        // 准备基本用户资料数据
        let basicData: [String: Any] = [
            "height": 175.0,  // 默认身高(cm)
            "weight": self.currentWeight,
            "body_fat_percentage": self.currentBodyFat,
            "muscle_mass": self.currentMuscleWeight
        ]
        
        // 发送请求初始化用户配置文件
        guard let jsonData = try? JSONSerialization.data(withJSONObject: basicData) else {
            print("初始化用户配置文件数据序列化失败")
            return
        }
        
        // 调用API创建基本用户资料
        let response: FoodJourneyModels.UpdateResponse = try await NetworkService.shared.request(
            endpoint: "/profile/basic",
            method: "PUT",
            body: jsonData,
            requiresAuth: true
        )
        
        print("成功初始化用户配置文件: \(response.message)")
    }
}

// 主视图，显示健身追踪功能的入口页面
struct HealthTrackView: View {
    // 使用视图模型管理数据
    @StateObject private var viewModel = HealthTrackViewModel()
    
    // 控制目标编辑模式
    @State private var isEditingGoals = false
    
    // 计算短期目标进度（增肌）
    private var shortTermProgress: Double {
        let gainedMuscle = viewModel.currentMuscleWeight - viewModel.initialMuscleWeight
        let progress = min(gainedMuscle / viewModel.targetMuscleGain, 1.0)
        return max(0.0, progress) // 确保不为负数
    }
    
    // 计算长期目标进度（减脂）
    private var longTermProgress: Double {
        let totalReduction = viewModel.initialBodyFat - viewModel.targetBodyFat
        let currentReduction = viewModel.initialBodyFat - viewModel.currentBodyFat
        let progress = min(currentReduction / totalReduction, 1.0)
        return max(0.0, progress) // 确保不为负数
    }
    
    // 格式化进度为百分比字符串
    private var shortTermPercentage: String {
        return "\(Int(shortTermProgress * 100))%"
    }
    
    private var longTermPercentage: String {
        return "\(Int(longTermProgress * 100))%"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    
                    // 顶部区域：用户头像、昵称
                    HStack(alignment: .center) {
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .padding()
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tianxin")
                                .font(.title2)
                                .bold()
                        }
                        Spacer()
                        
                        // 添加编辑目标按钮
                        Button(action: {
                            isEditingGoals.toggle()
                        }) {
                            Text(isEditingGoals ? "完成" : "编辑目标")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 目标描述
                    VStack(alignment: .leading, spacing: isEditingGoals ? 12 : 4) {
                        if isEditingGoals {
                            // 编辑模式下的目标编辑字段
                            VStack(alignment: .leading, spacing: 12) {
                                Text("目标设置")
                                    .font(.headline)
                                
                                // 短期目标输入
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("短期目标:")
                                        .font(.subheadline)
                                    TextField("输入短期目标", text: $viewModel.shortTermGoal)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(maxWidth: .infinity)
                                }
                                
                                // 长期目标输入
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("长期目标:")
                                        .font(.subheadline)
                                    TextField("输入长期目标", text: $viewModel.longTermGoal)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(maxWidth: .infinity)
                                }
                                
                                // 目标基础数据
                                Text("目标基础数据")
                                    .font(.headline)
                                    .padding(.top, 8)
                                
                                // 目标肌肉增长输入
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("目标增肌量(kg):")
                                        .font(.subheadline)
                                    HStack {
                                        TextField("", value: $viewModel.targetMuscleGain, formatter: NumberFormatter())
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                        Text("kg")
                                    }
                                }
                                
                                // 初始肌肉重量
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("初始肌肉重量(kg):")
                                        .font(.subheadline)
                                    HStack {
                                        TextField("", value: $viewModel.initialMuscleWeight, formatter: NumberFormatter())
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                        Text("kg")
                                    }
                                }
                                
                                // 目标体脂率输入
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("目标体脂率(%):")
                                        .font(.subheadline)
                                    HStack {
                                        TextField("", value: $viewModel.targetBodyFat, formatter: NumberFormatter())
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                        Text("%")
                                    }
                                }
                                
                                // 初始体脂率
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("初始体脂率(%):")
                                        .font(.subheadline)
                                    HStack {
                                        TextField("", value: $viewModel.initialBodyFat, formatter: NumberFormatter())
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                        Text("%")
                                    }
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                        } else {
                            // 查看模式下的目标显示
                            VStack(spacing: 16) {
                                // 短期目标卡片
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("短期目标")
                                            .font(.headline)
                                        Spacer()
                                        Text(shortTermPercentage)
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    }
                                    Text(viewModel.shortTermGoal)
                                        .font(.subheadline)
                                    ProgressView(value: shortTermProgress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                        .padding(.vertical, 4)
                                    Text("增肌进度: \(String(format: "%.1f", viewModel.currentMuscleWeight - viewModel.initialMuscleWeight))/\(String(format: "%.1f", viewModel.targetMuscleGain))kg")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                
                                // 长期目标卡片
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("长期目标")
                                            .font(.headline)
                                        Spacer()
                                        Text(longTermPercentage)
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    }
                                    Text(viewModel.longTermGoal)
                                        .font(.subheadline)
                                    ProgressView(value: longTermProgress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                        .padding(.vertical, 4)
                                    Text("减脂进度: 从\(String(format: "%.1f", viewModel.initialBodyFat))%降至\(String(format: "%.1f", viewModel.currentBodyFat))%，目标\(String(format: "%.1f", viewModel.targetBodyFat))%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                    // 卡片区域
                    VStack(spacing: 20) {
                        NavigationLink(destination: BodyDataDetailView().environmentObject(viewModel)) {
                            CardView(title: "身体数据",
                                     subtitle: "体重: \(String(format: "%.1f", viewModel.currentWeight))kg, 体脂率: \(String(format: "%.1f", viewModel.currentBodyFat))%",
                                     icon: "heart.fill")
                        }
                        NavigationLink(destination: TrainingProgressDetailView().environmentObject(viewModel)) {
                            CardView(title: "训练进度",
                                     subtitle: "今日: \(viewModel.muscleGroup)训练，完成\(viewModel.completedSets)/\(viewModel.totalSets)组\(viewModel.trainingType)",
                                     icon: "figure.walk")
                        }
                        NavigationLink(destination: DietDetailView()) {
                            CardView(title: "饮食情况",
                                     subtitle: "摄入: 1500 kcal, 蛋白质: 100g",
                                     icon: "leaf.fill")
                        }
                        NavigationLink(destination: RecoveryDetailView()) {
                            CardView(title: "恢复状态",
                                     subtitle: "睡眠: 7小时, 疲劳感: 4/5",
                                     icon: "bed.double.fill")
                        }
                        NavigationLink(destination: RecipeListView()) {
                            CardView(title: "菜谱",
                                     subtitle: "查看和管理菜谱",
                                     icon: "book.fill")
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .navigationTitle("健身追踪器")
                // 点击空白处收起键盘
                .onTapGesture {
                    if isEditingGoals {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                // 添加刷新数据的生命周期函数
                .onAppear {
                    // 仅在首次出现时刷新数据，后续的更新依赖用户通过下拉刷新触发
                    Task {
                        await viewModel.refreshData()
                    }
                }
                // 添加下拉刷新功能，但使用更易读的方式
                .refreshable {
                    print("用户手动触发刷新")
                    await viewModel.refreshData()
                }
            }
        }
    }
}

struct CardView: View {
    var title: String
    var subtitle: String
    var icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// 预览视图
struct HealthTrackView_Previews: PreviewProvider {
    static var previews: some View {
        HealthTrackView()
    }
}
