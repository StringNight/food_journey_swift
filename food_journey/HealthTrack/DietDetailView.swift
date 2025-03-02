import SwiftUI

struct DietDetailView: View {
    // 状态变量用于控制编辑模式
    @State private var isEditing = false
    
    // 用于存储用户输入的饮食数据
    @State private var breakfast: String = "鸡蛋、全麦面包、牛奶"
    @State private var lunch: String = "鸡肉沙拉、米饭"
    @State private var dinner: String = "鱼类、蔬菜"
    @State private var calories: String = "1500"
    @State private var protein: String = "100"
    @State private var fat: String = "50"
    @State private var carbs: String = "150"
    @State private var caloriesTarget: String = "2000"
    @State private var dietAdvice: String = "增加蛋白质摄入，可以加餐鸡胸肉或蛋白粉。"
    @State private var foodAlternative: String = "可以用豆腐替代鸡胸肉。"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("饮食详情")
                        .font(.title)
                        .bold()
                    
                    Spacer()
                    
                    // 添加编辑按钮
                    Button(action: {
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "取消" : "编辑")
                            .foregroundColor(.blue)
                    }
                    
                    if isEditing {
                        // 保存按钮
                        Button(action: {
                            // 这里添加保存数据的逻辑
                            Task {
                                await saveData()
                            }
                            isEditing = false
                        }) {
                            Text("保存")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // 今日饮食记录
                VStack(alignment: .leading, spacing: 8) {
                    Text("今日饮食记录")
                        .font(.headline)
                    
                    if isEditing {
                        // 编辑模式下的输入表单
                        VStack(spacing: 10) {
                            HStack {
                                Text("早餐:")
                                    .frame(width: 60, alignment: .leading)
                                TextField("早餐内容", text: $breakfast)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            HStack {
                                Text("午餐:")
                                    .frame(width: 60, alignment: .leading)
                                TextField("午餐内容", text: $lunch)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            HStack {
                                Text("晚餐:")
                                    .frame(width: 60, alignment: .leading)
                                TextField("晚餐内容", text: $dinner)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    } else {
                        Text("早餐: \(breakfast)")
                        Text("午餐: \(lunch)")
                        Text("晚餐: \(dinner)")
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // 营养分析与建议
                VStack(alignment: .leading, spacing: 8) {
                    Text("营养分析")
                        .font(.headline)
                    
                    if isEditing {
                        // 编辑模式下的营养数据输入
                        VStack(spacing: 10) {
                            HStack {
                                Text("热量:")
                                    .frame(width: 80, alignment: .leading)
                                TextField("热量", text: $calories)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("kcal")
                            }
                            
                            HStack {
                                Text("热量目标:")
                                    .frame(width: 80, alignment: .leading)
                                TextField("热量目标", text: $caloriesTarget)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("kcal")
                            }
                            
                            HStack {
                                Text("蛋白质:")
                                    .frame(width: 80, alignment: .leading)
                                TextField("蛋白质", text: $protein)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("g")
                            }
                            
                            HStack {
                                Text("脂肪:")
                                    .frame(width: 80, alignment: .leading)
                                TextField("脂肪", text: $fat)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("g")
                            }
                            
                            HStack {
                                Text("碳水:")
                                    .frame(width: 80, alignment: .leading)
                                TextField("碳水化合物", text: $carbs)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("g")
                            }
                            
                            HStack {
                                Text("建议:")
                                    .frame(width: 80, alignment: .leading)
                                TextField("饮食建议", text: $dietAdvice)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    } else {
                        Text("热量: \(calories) kcal (目标: \(caloriesTarget) kcal)")
                        Text("蛋白质: \(protein)g")
                        Text("脂肪: \(fat)g")
                        Text("碳水化合物: \(carbs)g")
                        Text("建议: \(dietAdvice)")
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // 历史趋势（图表占位符）
                Text("饮食趋势（过去7天）")
                    .font(.headline)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(Text("图表占位符"))
                    .cornerRadius(10)
                
                // 食物替代建议
                VStack(alignment: .leading, spacing: 8) {
                    Text("食物替代建议")
                        .font(.headline)
                    
                    if isEditing {
                        TextField("食物替代建议", text: $foodAlternative)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(foodAlternative)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            // 点击空白处收起键盘
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .navigationTitle("饮食详情")
    }
    
    // 保存数据的方法
    private func saveData() async {
        // 将输入的字符串转换为适当的数值类型
        let caloriesInt = Int(calories) ?? 0
        let proteinFloat = Float(protein) ?? 0
        let fatFloat = Float(fat) ?? 0
        let carbsFloat = Float(carbs) ?? 0
        let caloriesTargetInt = Int(caloriesTarget) ?? 0
        
        // 准备食物项目数据
        let breakfastItems = createFoodItems(
            mealType: "早餐",
            description: breakfast,
            caloriesPortion: caloriesInt / 3  // 简单分配总卡路里的三分之一给早餐
        )
        
        let lunchItems = createFoodItems(
            mealType: "午餐",
            description: lunch,
            caloriesPortion: caloriesInt / 3  // 简单分配总卡路里的三分之一给午餐
        )
        
        let dinnerItems = createFoodItems(
            mealType: "晚餐",
            description: dinner,
            caloriesPortion: caloriesInt / 3  // 简单分配总卡路里的三分之一给晚餐
        )
        
        // 记录一餐饮食（可以根据需要记录多餐）
        await recordMeal(
            mealType: "早餐",
            foodItems: breakfastItems,
            totalCalories: Float(caloriesInt / 3)
        )
        
        await recordMeal(
            mealType: "午餐",
            foodItems: lunchItems,
            totalCalories: Float(caloriesInt / 3)
        )
        
        await recordMeal(
            mealType: "晚餐",
            foodItems: dinnerItems,
            totalCalories: Float(caloriesInt / 3)
        )
        
        // 更新饮食偏好
        await updateDietPreferences(
            calorieTarget: caloriesTargetInt,
            nutritionGoals: [
                "protein": proteinFloat,
                "fat": fatFloat,
                "carbs": carbsFloat
            ],
            advice: dietAdvice
        )
        
        print("保存饮食数据: 热量\(calories)kcal, 蛋白质\(protein)g, 脂肪\(fat)g, 碳水\(carbs)g")
    }
    
    // 创建食物项目数据
    private func createFoodItems(mealType: String, description: String, caloriesPortion: Int) -> [[String: Any]] {
        // 从描述中解析食物项目
        let foodDescriptions = description.components(separatedBy: "、")
        var items: [[String: Any]] = []
        
        // 为每个食物创建简单的数据结构
        for (index, food) in foodDescriptions.enumerated() {
            let calories = caloriesPortion / foodDescriptions.count // 平均分配卡路里
            let item: [String: Any] = [
                "food_name": food,
                "portion": 100.0, // 默认100克
                "calories": Float(calories),
                "protein": Float(Int(protein) ?? 0) / Float(foodDescriptions.count),
                "carbs": Float(Int(carbs) ?? 0) / Float(foodDescriptions.count),
                "fat": Float(Int(fat) ?? 0) / Float(foodDescriptions.count)
            ]
            items.append(item)
        }
        
        return items
    }
    
    // 记录一餐的方法
    private func recordMeal(mealType: String, foodItems: [[String: Any]], totalCalories: Float) async {
        // 准备请求数据
        let requestData: [String: Any] = [
            "meal_type": mealType,
            "food_items": foodItems,
            "total_calories": totalCalories,
            "notes": "用户记录的\(mealType)"
        ]
        
        do {
            // 将字典转为JSON数据
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
                print("饮食数据序列化失败")
                return
            }
            
            // 使用async/await方式调用NetworkService
            let response: FoodJourneyModels.MealResponse = try await NetworkService.shared.request(
                endpoint: "/profile/meal",
                method: "POST",
                body: jsonData,
                requiresAuth: true
            )
            
            print("\(mealType)记录成功: \(response.id)")
        } catch {
            print("\(mealType)记录失败: \(error.localizedDescription)")
        }
    }
    
    // 更新饮食偏好
    private func updateDietPreferences(calorieTarget: Int, nutritionGoals: [String: Float], advice: String) async {
        // 准备请求数据
        let requestData: [String: Any] = [
            "calorie_preference": calorieTarget,
            "nutrition_goals": nutritionGoals,
            "extended_attributes": [
                "diet_advice": advice,
                "food_alternative": foodAlternative
            ]
        ]
        
        do {
            // 将字典转为JSON数据
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
                print("饮食偏好数据序列化失败")
                return
            }
            
            // 使用async/await方式调用NetworkService
            let response: FoodJourneyModels.UpdateResponse = try await NetworkService.shared.request(
                endpoint: "/profile/diet",
                method: "PUT",
                body: jsonData,
                requiresAuth: true
            )
            
            print("饮食偏好更新成功: \(response.message)")
        } catch {
            print("饮食偏好更新失败: \(error.localizedDescription)")
        }
    }
}

struct DietDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DietDetailView()
    }
}
