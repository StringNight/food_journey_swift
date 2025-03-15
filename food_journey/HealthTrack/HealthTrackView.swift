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
    
    // 饮食数据 - 从DietDetailView迁移
    @Published var breakfast: String = "鸡蛋、全麦面包、牛奶"
    @Published var lunch: String = "鸡肉沙拉、米饭"
    @Published var dinner: String = "鱼类、蔬菜"
    @Published var calories: String = "1500"
    @Published var protein: String = "100"
    @Published var fat: String = "50"
    @Published var carbs: String = "150"
    @Published var caloriesTarget: String = "2000"
    @Published var dietAdvice: String = "增加蛋白质摄入，可以加餐鸡胸肉或蛋白粉。"
    
    // 饮食数据状态
    @Published var isDietDataLoading: Bool = false
    @Published var isDietDataSaving: Bool = false
    @Published var showDietSaveSuccess: Bool = false
    @Published var dietLoadError: String? = nil
    
    // 身体数据 - 从BodyDataDetailView迁移
    @Published var bmr: String = "1800" // 基础代谢率
    
    // 身体数据状态
    @Published var isBodyDataSaving: Bool = false
    @Published var showBodyDataSaveSuccess: Bool = false
    @Published var bodyDataLoadError: String? = nil
    
    // 训练进度详细数据 - 从TrainingProgressDetailView迁移
    @Published var trainingSet: String = "3"
    @Published var trainingReps: String = "10"
    @Published var trainingWeight: String = "60"
    @Published var trainingDetail: String = "重点锻炼了股四头肌和腿后肌"
    @Published var restAdvice: String = "休息48小时，进行腿部拉伸"
    @Published var nextTraining: String = "背部训练"
    
    // 训练数据状态
    @Published var isTrainingDataSaving: Bool = false
    @Published var showTrainingDataSaveSuccess: Bool = false
    @Published var trainingDataLoadError: String? = nil
    
    // 恢复数据 - 从RecoveryDetailView迁移
    @Published var sleepHours: String = "7"
    @Published var deepSleepPercentage: String = "50"
    @Published var fatigueRating: Int = 4
    @Published var recoveryAdvice: String = "根据你的疲劳感，建议进行轻柔的瑜伽或拉伸。"
    
    // 恢复数据状态
    @Published var isRecoveryDataSaving: Bool = false
    @Published var showRecoveryDataSaveSuccess: Bool = false
    @Published var recoveryDataLoadError: String? = nil
    
    // 添加加载状态标志
    @Published var isLoading: Bool = false
    
    // 防抖动机制
    private var lastRefreshTime: Date = Date(timeIntervalSince1970: 0)
    private let minRefreshInterval: TimeInterval = 5.0 // 增加最小刷新间隔到30秒
    
    // 添加一个标志，跟踪是否已经加载过数据
    private var hasLoadedInitialData: Bool = false
    
    // 添加用于取消任务的ID
    private var refreshTask: Task<Void, Never>? = nil
    private var dietRefreshTask: Task<Void, Never>? = nil
    private var bodyDataRefreshTask: Task<Void, Never>? = nil
    private var trainingDataRefreshTask: Task<Void, Never>? = nil
    private var recoveryDataRefreshTask: Task<Void, Never>? = nil
    
    // 刷新数据 - 增加防抖动逻辑和错误处理
    func refreshData() async {
        // 取消任何正在进行的刷新任务
        refreshTask?.cancel()
        
        // 检查是否需要刷新 - 如果已经加载过初始数据且距离上次刷新时间不足最小间隔，则跳过
        let now = Date()
        if hasLoadedInitialData && now.timeIntervalSince(lastRefreshTime) < minRefreshInterval {
            print("跳过刷新：刷新间隔过短，上次刷新时间：\(lastRefreshTime)，当前时间：\(now)")
            return
        }
        
        // 更新UI状态以指示正在加载
        await MainActor.run {
            isLoading = true
        }
        
        // 创建新的刷新任务
        refreshTask = Task {
            // 更新最后刷新时间
            lastRefreshTime = now
            
            do {
                // 获取用户完整档案数据
                let profileResponse: FoodJourneyModels.CompleteProfile = try await NetworkService.shared.request(
                    endpoint: "/profile",
                    method: "GET",
                    requiresAuth: true
                )
                
                // 确保任务没有被取消
                if Task.isCancelled {
                    return
                }
                
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
                    if let bmr = profileResponse.health_profile.bmr {
                        self.bmr = String(bmr)
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
                    
                    // 更新睡眠和恢复数据
                    if let sleepDuration = profileResponse.fitness_profile.sleep_duration {
                        self.sleepHours = String(format: "%.1f", sleepDuration)
                    }
                    if let deepSleepPercentage = profileResponse.fitness_profile.deep_sleep_percentage {
                        self.deepSleepPercentage = String(format: "%.0f", deepSleepPercentage)
                    }
                    if let fatigueScore = profileResponse.fitness_profile.fatigue_score {
                        self.fatigueRating = fatigueScore
                    }
                    
                    // 如果有训练进度信息，更新组数信息
                    if let progress = profileResponse.fitness_profile.training_progress {
                        // 计算已完成组数 = 进度百分比 * 总组数 / 100
                        if progress > 0 {
                            if self.totalSets > 0 {
                                // 根据进度百分比计算已完成组数
                                self.completedSets = min(Int(Double(self.totalSets) * progress / 100.0), self.totalSets)
                            } else if let trainingType = profileResponse.fitness_profile.training_type, !trainingType.isEmpty {
                                // 如果有训练类型但无总组数，设置一个默认值
                                self.totalSets = 5
                                self.completedSets = min(Int(Double(self.totalSets) * progress / 100.0), self.totalSets)
                            }
                        }
                    }
                    
                    // 更新饮食数据
                    if let nutritionGoals = profileResponse.diet_profile.nutrition_goals {
                        if let protein = nutritionGoals["protein"] {
                            self.protein = String(format: "%.0f", protein)
                            print("已更新蛋白质值: \(self.protein)")
                        }
                        if let fat = nutritionGoals["fat"] {
                            self.fat = String(format: "%.0f", fat)
                            print("已更新脂肪值: \(self.fat)")
                        }
                        if let carbs = nutritionGoals["carbs"] {
                            self.carbs = String(format: "%.0f", carbs)
                            print("已更新碳水值: \(self.carbs)")
                        }
                    }
                    
                    // 更新卡路里目标
                    if let caloriePreference = profileResponse.diet_profile.calorie_preference {
                        self.caloriesTarget = String(caloriePreference)
                        print("已更新卡路里目标: \(self.caloriesTarget)")
                    }
                    
                    // 尝试从扩展属性中获取饮食建议
                    if let extendedAttributes = profileResponse.extended_attributes {
                        if let dietAdvice = extendedAttributes["diet_advice"] {
                            self.dietAdvice = dietAdvice
                            print("已更新饮食建议: \(self.dietAdvice)")
                        }
                        
                        if let trainingDetail = extendedAttributes["training_detail"] {
                            self.trainingDetail = trainingDetail
                        }
                        
                        if let restAdvice = extendedAttributes["rest_advice"] {
                            self.restAdvice = restAdvice
                        }
                        
                        if let nextTraining = extendedAttributes["next_training"] {
                            self.nextTraining = nextTraining
                        }
                        
                        if let recoveryAdvice = extendedAttributes["recovery_advice"] {
                            self.recoveryAdvice = recoveryAdvice
                        }
                    }
                    
                    // 标记已加载初始数据并结束加载状态
                    self.hasLoadedInitialData = true
                    self.isLoading = false
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
                
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                print("获取健身追踪数据失败: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // 主动强制刷新数据，忽略刷新间隔限制
    func forceRefreshData() async {
        // 重置上次刷新时间以确保能够刷新
        lastRefreshTime = Date(timeIntervalSince1970: 0)
        
        // 更新UI状态以指示正在加载
        await MainActor.run {
            isLoading = true
        }
        
        // 取消任何正在进行的刷新任务
        refreshTask?.cancel()
        
        // 创建新的刷新任务，使用强制刷新模式
        refreshTask = Task {
            do {
                // 获取用户完整档案数据 - 强制不使用缓存
                let profileResponse: FoodJourneyModels.CompleteProfile = try await NetworkService.shared.request(
                    endpoint: "/profile",
                    method: "GET",
                    requiresAuth: true,
                    cachePolicy: .reloadIgnoringLocalCacheData // 关键：强制不使用缓存
                )
                
                // 确保任务没有被取消
                if Task.isCancelled {
                    return
                }
                
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
                    if let bmr = profileResponse.health_profile.bmr {
                        self.bmr = String(bmr)
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
                    
                    // 更新睡眠和恢复数据
                    if let sleepDuration = profileResponse.fitness_profile.sleep_duration {
                        self.sleepHours = String(format: "%.1f", sleepDuration)
                    }
                    if let deepSleepPercentage = profileResponse.fitness_profile.deep_sleep_percentage {
                        self.deepSleepPercentage = String(format: "%.0f", deepSleepPercentage)
                    }
                    if let fatigueScore = profileResponse.fitness_profile.fatigue_score {
                        self.fatigueRating = fatigueScore
                    }
                    
                    // 如果有训练进度信息，更新组数信息
                    if let progress = profileResponse.fitness_profile.training_progress {
                        // 计算已完成组数 = 进度百分比 * 总组数 / 100
                        if progress > 0 {
                            if self.totalSets > 0 {
                                // 根据进度百分比计算已完成组数
                                self.completedSets = min(Int(Double(self.totalSets) * progress / 100.0), self.totalSets)
                            } else if let trainingType = profileResponse.fitness_profile.training_type, !trainingType.isEmpty {
                                // 如果有训练类型但无总组数，设置一个默认值
                                self.totalSets = 5
                                self.completedSets = min(Int(Double(self.totalSets) * progress / 100.0), self.totalSets)
                            }
                        }
                    }
                    
                    // 更新饮食数据
                    if let nutritionGoals = profileResponse.diet_profile.nutrition_goals {
                        if let protein = nutritionGoals["protein"] {
                            self.protein = String(format: "%.0f", protein)
                            print("已更新蛋白质值: \(self.protein)")
                        }
                        if let fat = nutritionGoals["fat"] {
                            self.fat = String(format: "%.0f", fat)
                            print("已更新脂肪值: \(self.fat)")
                        }
                        if let carbs = nutritionGoals["carbs"] {
                            self.carbs = String(format: "%.0f", carbs)
                            print("已更新碳水值: \(self.carbs)")
                        }
                    }
                    
                    // 更新卡路里目标
                    if let caloriePreference = profileResponse.diet_profile.calorie_preference {
                        self.caloriesTarget = String(caloriePreference)
                        print("已更新卡路里目标: \(self.caloriesTarget)")
                    }
                    
                    // 尝试从扩展属性中获取饮食建议
                    if let extendedAttributes = profileResponse.extended_attributes {
                        if let dietAdvice = extendedAttributes["diet_advice"] {
                            self.dietAdvice = dietAdvice
                            print("已更新饮食建议: \(self.dietAdvice)")
                        }
                        
                        if let trainingDetail = extendedAttributes["training_detail"] {
                            self.trainingDetail = trainingDetail
                        }
                        
                        if let restAdvice = extendedAttributes["rest_advice"] {
                            self.restAdvice = restAdvice
                        }
                        
                        if let nextTraining = extendedAttributes["next_training"] {
                            self.nextTraining = nextTraining
                        }
                        
                        if let recoveryAdvice = extendedAttributes["recovery_advice"] {
                            self.recoveryAdvice = recoveryAdvice
                        }
                    }
                    
                    // 标记已加载初始数据并结束加载状态
                    self.hasLoadedInitialData = true
                    self.isLoading = false
                }
                
                print("健身追踪数据强制刷新成功")
            } catch let NetworkError.serverError(message) {
                print("强制刷新获取健身追踪数据失败 - 服务器错误: \(message)")
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                print("强制刷新获取健身追踪数据失败: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // 当视图将要消失时调用，取消任何正在进行的刷新任务
    func cancelRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
        dietRefreshTask?.cancel()
        dietRefreshTask = nil
        bodyDataRefreshTask?.cancel()
        bodyDataRefreshTask = nil
        trainingDataRefreshTask?.cancel()
        trainingDataRefreshTask = nil
        recoveryDataRefreshTask?.cancel()
        recoveryDataRefreshTask = nil
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
    
    // 保存饮食数据
    func saveDietData() async {
        await MainActor.run {
            isDietDataSaving = true
            showDietSaveSuccess = false
        }
        
        do {
            // 1. 记录早餐
            let breakfastCalories = Int(calories) ?? 0 / 3
            let breakfastItems = createFoodItems(mealType: "早餐", description: breakfast, caloriesPortion: breakfastCalories)
            try await recordMeal(mealType: "早餐", foodItems: breakfastItems, totalCalories: Float(breakfastCalories))
            
            // 2. 记录午餐
            let lunchCalories = Int(calories) ?? 0 / 3
            let lunchItems = createFoodItems(mealType: "午餐", description: lunch, caloriesPortion: lunchCalories)
            try await recordMeal(mealType: "午餐", foodItems: lunchItems, totalCalories: Float(lunchCalories))
            
            // 3. 记录晚餐
            let dinnerCalories = Int(calories) ?? 0 / 3
            let dinnerItems = createFoodItems(mealType: "晚餐", description: dinner, caloriesPortion: dinnerCalories)
            try await recordMeal(mealType: "晚餐", foodItems: dinnerItems, totalCalories: Float(dinnerCalories))
            
            // 4. 更新饮食偏好
            let nutritionGoals: [String: Float] = [
                "protein": Float(protein) ?? 0.0,
                "fat": Float(fat) ?? 0.0,
                "carbs": Float(carbs) ?? 0.0
            ]
            try await updateDietPreferences(calorieTarget: Int(caloriesTarget) ?? 2000, nutritionGoals: nutritionGoals, advice: dietAdvice)
            
            // 5. 强制刷新数据
            await forceRefreshData()
            
            // 6. 显示成功消息
            await MainActor.run {
                isDietDataSaving = false
                showDietSaveSuccess = true
                
                // 3秒后自动隐藏成功消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showDietSaveSuccess = false
                }
            }
            
            print("饮食数据保存成功")
        } catch {
            print("保存饮食数据失败: \(error.localizedDescription)")
            await MainActor.run {
                isDietDataSaving = false
                dietLoadError = error.localizedDescription
                
                // 3秒后自动隐藏错误消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.dietLoadError = nil
                }
            }
        }
    }
    
    // 创建食物项目数据
    private func createFoodItems(mealType: String, description: String, caloriesPortion: Int) -> [[String: Any]] {
        // 从描述中解析食物项目
        let foodDescriptions = description.components(separatedBy: "、")
        var items: [[String: Any]] = []
        
        // 为每个食物创建简单的数据结构
        for (_, food) in foodDescriptions.enumerated() {
            if !food.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let calories = foodDescriptions.count > 0 ? caloriesPortion / foodDescriptions.count : 0 // 平均分配卡路里
                let item: [String: Any] = [
                    "food_name": food,
                    "portion": 100.0, // 默认100克
                    "calories": Float(calories),
                    "protein": Float(Int(protein) ?? 0) / Float(max(1, foodDescriptions.count)),
                    "carbs": Float(Int(carbs) ?? 0) / Float(max(1, foodDescriptions.count)),
                    "fat": Float(Int(fat) ?? 0) / Float(max(1, foodDescriptions.count)),
                    "fiber": Float(1.0) // 设置默认膳食纤维值
                ]
                items.append(item)
            }
        }
        
        return items
    }
    
    // 记录一餐的方法
    private func recordMeal(mealType: String, foodItems: [[String: Any]], totalCalories: Float) async throws {
        // 准备请求数据
        let requestData: [String: Any] = [
            "meal_type": mealType,
            "food_items": foodItems,
            "total_calories": totalCalories,
            "notes": "用户记录的\(mealType)",
            "recorded_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        // 将字典转为JSON数据
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            print("饮食数据序列化失败")
            throw NSError(domain: "FoodJourney", code: 1001, userInfo: [NSLocalizedDescriptionKey: "饮食数据序列化失败"])
        }
        
        // 使用async/await方式调用NetworkService
        let response: FoodJourneyModels.MealResponse = try await NetworkService.shared.request(
            endpoint: "/profile/meal",
            method: "POST",
            body: jsonData,
            requiresAuth: true,
            cachePolicy: .reloadIgnoringLocalCacheData // 关键：强制不使用缓存
        )
        
        print("\(mealType)记录成功: \(response.id)")
    }
    
    // 更新饮食偏好
    private func updateDietPreferences(calorieTarget: Int, nutritionGoals: [String: Float], advice: String) async throws {
        // 准备请求数据
        let requestData: [String: Any] = [
            "calorie_preference": calorieTarget,
            "nutrition_goals": nutritionGoals,
            "extended_attributes": [
                "diet_advice": advice
            ]
        ]
        
        // 将字典转为JSON数据
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            print("饮食偏好数据序列化失败")
            throw NSError(domain: "FoodJourney", code: 1002, userInfo: [NSLocalizedDescriptionKey: "饮食偏好数据序列化失败"])
        }
        
        // 使用async/await方式调用NetworkService，强制不使用缓存
        let response: FoodJourneyModels.UpdateResponse = try await NetworkService.shared.request(
            endpoint: "/profile/diet",
            method: "PUT",
            body: jsonData,
            requiresAuth: true,
            cachePolicy: .reloadIgnoringLocalCacheData // 关键：强制不使用缓存
        )
        
        print("饮食偏好更新成功: \(response.message)")
    }
    
    // 保存身体数据
    func saveBodyData() async {
        await MainActor.run {
            isBodyDataSaving = true
            showBodyDataSaveSuccess = false
        }
        
        do {
            // 准备身体数据
            let bodyData: [String: Any] = [
                "weight": Double(currentWeight),
                "body_fat_percentage": Double(currentBodyFat),
                "muscle_mass": Double(currentMuscleWeight),
                "bmr": Int(bmr) ?? 0
            ]
            
            // 将字典转为JSON数据
            guard let jsonData = try? JSONSerialization.data(withJSONObject: bodyData) else {
                print("身体数据序列化失败")
                throw NSError(domain: "FoodJourney", code: 1003, userInfo: [NSLocalizedDescriptionKey: "身体数据序列化失败"])
            }
            
            // 使用async/await方式调用NetworkService，强制不使用缓存
            let response: FoodJourneyModels.UpdateResponse = try await NetworkService.shared.request(
                endpoint: "/profile/basic",
                method: "PUT",
                body: jsonData,
                requiresAuth: true,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            
            // 强制刷新数据
            await forceRefreshData()
            
            // 显示成功消息
            await MainActor.run {
                isBodyDataSaving = false
                showBodyDataSaveSuccess = true
                
                // 3秒后自动隐藏成功消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showBodyDataSaveSuccess = false
                }
            }
            
            print("身体数据保存成功: \(response.message)")
        } catch {
            print("保存身体数据失败: \(error.localizedDescription)")
            await MainActor.run {
                isBodyDataSaving = false
                bodyDataLoadError = error.localizedDescription
                
                // 3秒后自动隐藏错误消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.bodyDataLoadError = nil
                }
            }
        }
    }
    
    // 保存训练数据
    func saveTrainingData() async {
        await MainActor.run {
            isTrainingDataSaving = true
            showTrainingDataSaveSuccess = false
        }
        
        do {
            // 准备训练数据
            let trainingData: [String: Any] = [
                "training_type": trainingType,
                "training_progress": Double(completedSets) / Double(max(1, totalSets)) * 100.0,
                "muscle_group_analysis": [
                    muscleGroup: "主要肌群"
                ],
                "extended_attributes": [
                    "training_detail": trainingDetail,
                    "rest_advice": restAdvice,
                    "next_training": nextTraining
                ]
            ]
            
            // 将字典转为JSON数据
            guard let jsonData = try? JSONSerialization.data(withJSONObject: trainingData) else {
                print("训练数据序列化失败")
                throw NSError(domain: "FoodJourney", code: 1004, userInfo: [NSLocalizedDescriptionKey: "训练数据序列化失败"])
            }
            
            // 使用async/await方式调用NetworkService，强制不使用缓存
            let response: FoodJourneyModels.UpdateResponse = try await NetworkService.shared.request(
                endpoint: "/profile/fitness",
                method: "PUT",
                body: jsonData,
                requiresAuth: true,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            
            // 强制刷新数据
            await forceRefreshData()
            
            // 显示成功消息
            await MainActor.run {
                isTrainingDataSaving = false
                showTrainingDataSaveSuccess = true
                
                // 3秒后自动隐藏成功消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showTrainingDataSaveSuccess = false
                }
            }
            
            print("训练数据保存成功: \(response.message)")
        } catch {
            print("保存训练数据失败: \(error.localizedDescription)")
            await MainActor.run {
                isTrainingDataSaving = false
                trainingDataLoadError = error.localizedDescription
                
                // 3秒后自动隐藏错误消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.trainingDataLoadError = nil
                }
            }
        }
    }
    
    // 保存恢复数据
    func saveRecoveryData() async {
        await MainActor.run {
            isRecoveryDataSaving = true
            showRecoveryDataSaveSuccess = false
        }
        
        do {
            // 准备恢复数据
            let recoveryData: [String: Any] = [
                "sleep_duration": Double(sleepHours) ?? 0.0,
                "deep_sleep_percentage": Double(deepSleepPercentage) ?? 0.0,
                "fatigue_score": fatigueRating,
                "extended_attributes": [
                    "recovery_advice": recoveryAdvice
                ]
            ]
            
            // 将字典转为JSON数据
            guard let jsonData = try? JSONSerialization.data(withJSONObject: recoveryData) else {
                print("恢复数据序列化失败")
                throw NSError(domain: "FoodJourney", code: 1005, userInfo: [NSLocalizedDescriptionKey: "恢复数据序列化失败"])
            }
            
            // 使用async/await方式调用NetworkService，强制不使用缓存
            let response: FoodJourneyModels.UpdateResponse = try await NetworkService.shared.request(
                endpoint: "/profile/fitness",
                method: "PUT",
                body: jsonData,
                requiresAuth: true,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            
            // 强制刷新数据
            await forceRefreshData()
            
            // 显示成功消息
            await MainActor.run {
                isRecoveryDataSaving = false
                showRecoveryDataSaveSuccess = true
                
                // 3秒后自动隐藏成功消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showRecoveryDataSaveSuccess = false
                }
            }
            
            print("恢复数据保存成功: \(response.message)")
        } catch {
            print("保存恢复数据失败: \(error.localizedDescription)")
            await MainActor.run {
                isRecoveryDataSaving = false
                recoveryDataLoadError = error.localizedDescription
                
                // 3秒后自动隐藏错误消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.recoveryDataLoadError = nil
                }
            }
        }
    }
}

// 主视图，显示健身追踪功能的入口页面
struct HealthTrackView: View {
    // 使用视图模型管理数据
    @StateObject private var viewModel = HealthTrackViewModel()
    @StateObject private var authService = AuthService.shared
    
    // 控制目标编辑模式
    @State private var isEditingGoals = false
    
    // 添加一个状态变量用于跟踪页面是否正在出现
    @State private var isAppearing = false
    
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
            VStack() {
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        
                        // 顶部区域：用户头像、昵称
                        HStack(alignment: .center) {
                            NavigationLink(destination: ProfileView()) {
                                // 显示头像或默认图片
                                if let user = authService.currentUser, let avatarUrl = user.avatar_url, !avatarUrl.isEmpty {
                                    // 显示已上传的头像
                                    let fullUrl = getFullAvatarUrl(avatarUrl)
                                    
                                    // 先检查缓存中是否有头像
                                    if let cachedImage = authService.getCachedAvatar(for: fullUrl) {
                                        Image(uiImage: cachedImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    } else {
                                        // 如果缓存中没有，则从网络加载
                                        AsyncImage(url: URL(string: fullUrl)) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .onAppear {
                                                        print("正在加载头像: \(fullUrl)")
                                                    }
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .onAppear {
                                                        print("头像加载成功")
                                                        // 将加载成功的图像转换为UIImage并缓存
                                                        if let uiImage = imageToUIImage(image) {
                                                            authService.cacheAvatar(uiImage, for: fullUrl)
                                                        }
                                                    }
                                            case .failure(let error):
                                                // 加载失败时显示默认头像
                                                Image(systemName: "person.crop.circle")
                                                    .resizable()
                                                    .foregroundColor(.gray)
                                                    .onAppear {
                                                        print("头像加载失败: \(error.localizedDescription), URL: \(fullUrl)")
                                                    }
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                    }
                                } else {
                                    // 没有头像时显示默认头像
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.gray)
                                        .onAppear {
                                            if let user = authService.currentUser {
                                                print("用户没有头像URL: \(String(describing: user.avatar_url))")
                                            } else {
                                                print("当前用户为空")
                                            }
                                        }
                                }
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if let user = authService.currentUser {
                                    Text(user.username)
                                        .font(.title2)
                                        .bold()
                                } else {
                                    Text("用户")
                                        .font(.title2)
                                        .bold()
                                }
                            }
                            Spacer()
                            
                            // 添加编辑目标按钮
                            Button(action: {
                                isEditingGoals.toggle()
                            }) {
                                Text(isEditingGoals ? "完成" : "编辑目标")
                                    .foregroundColor(.blue)
                            }
                        }.padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        
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
                        .padding(.horizontal, 15)
                        .padding(.bottom, 20)
                        
                        // 卡片区域
                        VStack(spacing: 20) {
                            NavigationLink(destination: BodyDataDetailView().environmentObject(viewModel)) {
                                CardView(title: "身体数据",
                                         subtitle: "体重: \(String(format: "%.1f", viewModel.currentWeight))kg, 体脂率: \(String(format: "%.1f", viewModel.currentBodyFat))%",
                                         icon: "heart.fill",
                                         iconColor: .red) // 红色 - 身体数据
                            }
                            NavigationLink(destination: TrainingProgressDetailView().environmentObject(viewModel)) {
                                CardView(title: "训练进度",
                                         subtitle: viewModel.trainingType.isEmpty ? "尚未记录训练" : "今日: \(viewModel.trainingType)训练，完成\(viewModel.completedSets)/\(viewModel.totalSets)组",
                                         icon: "figure.walk",
                                         iconColor: .blue) // 蓝色 - 训练进度
                            }
                            NavigationLink(destination: DietDetailView().environmentObject(viewModel)) {
                                CardView(title: "饮食情况",
                                         subtitle: "摄入: \(viewModel.calories) kcal, 蛋白质: \(viewModel.protein)g",
                                         icon: "leaf.fill",
                                         iconColor: .green) // 绿色 - 饮食情况
                            }
                            NavigationLink(destination: RecoveryDetailView().environmentObject(viewModel)) {
                                CardView(title: "恢复状态",
                                         subtitle: "睡眠: \(viewModel.sleepHours)小时, 疲劳感: \(viewModel.fatigueRating)/5",
                                         icon: "bed.double.fill",
                                         iconColor: .purple) // 紫色 - 恢复状态
                            }
                            .onAppear {
                                print("恢复状态卡片显示 - 睡眠: \(viewModel.sleepHours)小时, 疲劳感: \(viewModel.fatigueRating)/5")
                            }
                            NavigationLink(destination: RecipeListView()) {
                                CardView(title: "菜谱",
                                         subtitle: "查看和管理菜谱",
                                         icon: "book.fill",
                                         iconColor: .orange) // 橙色 - 菜谱
                            }
                        }
                        .padding(.horizontal, 15)
                        
                        Spacer()
                    }
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
                    // 标记页面正在出现
                    isAppearing = true
                    // 当视图出现时，刷新数据
                    Task {
                        await viewModel.refreshData()
                        isAppearing = false
                    }
                }
                .onDisappear {
                    // 当视图消失时，取消任何正在进行的刷新任务
                    viewModel.cancelRefresh()
                }
                .refreshable {
                    // 使用强制刷新方法，忽略刷新间隔限制
                    await viewModel.forceRefreshData()
                }
                
                // 加载指示器
                if isAppearing || viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
            }
        }
    }


struct CardView: View {
    var title: String
    var subtitle: String
    var icon: String
    var iconColor: Color // 添加图标颜色属性
    
    // 提供默认颜色的初始化方法，保持向后兼容性
    init(title: String, subtitle: String, icon: String) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = .blue // 默认蓝色
    }
    
    // 添加支持自定义颜色的初始化方法
    init(title: String, subtitle: String, icon: String, iconColor: Color) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // 固定宽高的图标容器，使用传入的颜色
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(iconColor) // 使用自定义颜色
                .cornerRadius(10)
            
            // 固定宽度的文字容器
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .padding(.trailing, 5)
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

// 在 HealthTrackView 外部添加这个辅助函数
@MainActor func imageToUIImage(_ image: Image) -> UIImage? {
    let renderer = ImageRenderer(content: image)
    return renderer.uiImage
}
