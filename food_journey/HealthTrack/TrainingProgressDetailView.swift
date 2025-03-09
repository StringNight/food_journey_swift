import SwiftUI

struct TrainingProgressDetailView: View {
    // 接收从父视图传递的视图模型
    @EnvironmentObject var viewModel: HealthTrackViewModel
    
    // 状态变量用于控制编辑模式
    @State private var isEditing = false
    
    // 用于存储用户输入的训练数据
    @State private var trainingType: String = "深蹲"
    @State private var trainingSet: String = "3"
    @State private var trainingReps: String = "10"
    @State private var trainingWeight: String = "60"
    @State private var completedSets: String = "3"
    @State private var totalSets: String = "5"
    @State private var muscleGroup: String = "腿部"
    @State private var trainingDetail: String = "重点锻炼了股四头肌和腿后肌"
    @State private var restAdvice: String = "休息48小时，进行腿部拉伸"
    @State private var nextTraining: String = "背部训练"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("训练进度")
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
                
                // 今日训练详情
                VStack(alignment: .leading, spacing: 8) {
                    Text("今日训练")
                        .font(.headline)
                    
                    if isEditing {
                        // 编辑模式下的输入表单
                        HStack {
                            Text("训练类型:")
                                .frame(width: 80, alignment: .leading)
                            TextField("训练类型", text: $trainingType)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("组数:")
                                .frame(width: 80, alignment: .leading)
                            TextField("组数", text: $trainingSet)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("每组次数:")
                                .frame(width: 80, alignment: .leading)
                            TextField("每组次数", text: $trainingReps)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("重量(kg):")
                                .frame(width: 80, alignment: .leading)
                            TextField("重量", text: $trainingWeight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    } else {
                        Text("\(trainingType): \(trainingSet)组 x \(trainingReps)次, 重量 \(trainingWeight)kg")
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // 训练完成度
                VStack(alignment: .leading, spacing: 8) {
                    Text("训练完成度")
                        .font(.headline)
                    
                    ProgressView(value: Double(completedSets) ?? 0, total: Double(totalSets) ?? 1)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .padding(.vertical)
                    
                    if isEditing {
                        HStack {
                            Text("已完成组数:")
                                .frame(width: 100, alignment: .leading)
                            TextField("已完成组数", text: $completedSets)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("总组数:")
                                .frame(width: 100, alignment: .leading)
                            TextField("总组数", text: $totalSets)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    } else {
                        Text("完成\(completedSets)/\(totalSets)组")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // 肌肉群分析
                VStack(alignment: .leading, spacing: 8) {
                    Text("肌肉群分析")
                        .font(.headline)
                    
                    if isEditing {
                        HStack {
                            Text("训练肌群:")
                                .frame(width: 100, alignment: .leading)
                            TextField("训练肌群", text: $muscleGroup)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("训练细节:")
                                .frame(width: 100, alignment: .leading)
                            TextField("训练细节", text: $trainingDetail)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    } else {
                        Text("今天你训练了\(muscleGroup)，\(trainingDetail)。")
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // 休息与拉伸建议
                VStack(alignment: .leading, spacing: 8) {
                    Text("休息与拉伸建议")
                        .font(.headline)
                    
                    if isEditing {
                        TextField("休息与拉伸建议", text: $restAdvice)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text("今天进行了大肌群训练，建议\(restAdvice)。")
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // 接下来的训练计划
                VStack(alignment: .leading, spacing: 8) {
                    Text("接下来的训练")
                        .font(.headline)
                    
                    if isEditing {
                        TextField("下次训练计划", text: $nextTraining)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text("明天进行\(nextTraining)。")
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
        .navigationTitle("训练详情")
        .onAppear {
            // 当视图出现时，从ViewModel加载数据
            loadDataFromViewModel()
        }
    }
    
    // 从ViewModel加载数据
    private func loadDataFromViewModel() {
        trainingType = viewModel.trainingType
        completedSets = String(viewModel.completedSets)
        totalSets = String(viewModel.totalSets)
        muscleGroup = viewModel.muscleGroup
    }
    
    // 保存数据的方法
    private func saveData() async {
        // 转换输入数据为适当的类型
        let trainingSetInt = Int(trainingSet) ?? 0
        let trainingRepsInt = Int(trainingReps) ?? 0
        let trainingWeightDouble = Double(trainingWeight) ?? 0
        let trainingProgressValue = Double(completedSets) ?? 0
        
        // 记录训练数据 - 使用与后端对应的ExerciseRecord结构
        let exerciseSetData: [String: Any] = [
            "reps": trainingRepsInt,
            "weight": trainingWeightDouble
        ]
        
        let exerciseData: [String: Any] = [
            "id": UUID().uuidString, // 生成一个临时ID，后端会替换
            "user_id": "current_user", // 后端会根据认证信息替换
            "exercise_name": trainingType,
            "exercise_type": "力量", // 假设是力量训练
            "sets": [exerciseSetData],
            "calories_burned": 0.0,
            "notes": "用户记录的训练",
            "recorded_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            // 将字典转为JSON数据
            guard let jsonData = try? JSONSerialization.data(withJSONObject: exerciseData) else {
                print("数据序列化失败")
                return
            }
            
            // 使用async/await方式调用NetworkService
            let response: FoodJourneyModels.ExerciseResponse = try await NetworkService.shared.request(
                endpoint: "/profile/exercise",
                method: "POST",
                body: jsonData,
                requiresAuth: true
            )
            
            // 成功处理
            print("训练数据更新成功: \(response.id)")
            
            // 更新训练偏好 - 但不触发额外刷新
            await updateTrainingPreferences(
                trainingType: trainingType,
                trainingProgress: trainingProgressValue,
                muscleGroup: muscleGroup,
                trainingDetail: trainingDetail
            )
            
            // 更新ViewModel中的数据 - 直接更新，避免额外的网络请求
            await MainActor.run {
                viewModel.trainingType = trainingType
                viewModel.completedSets = Int(completedSets) ?? 0
                viewModel.totalSets = Int(totalSets) ?? 0
                viewModel.muscleGroup = muscleGroup
                
                // 显示保存成功的反馈提示
                isEditing = false
            }
            
        } catch {
            // 错误处理
            print("训练数据更新失败: \(error.localizedDescription)")
            // 可以在这里添加错误处理，例如显示错误提示
            await MainActor.run {
                // 显示错误提示
            }
        }
        
        print("保存训练数据: 类型\(trainingType), 组数\(trainingSet)x\(trainingReps), 重量\(trainingWeight)kg")
    }
    
    // 更新训练偏好
    private func updateTrainingPreferences(trainingType: String, trainingProgress: Double, muscleGroup: String, trainingDetail: String) async {
        // 准备请求数据
        let fitnessPreferencesData: [String: Any] = [
            "training_type": trainingType,
            "training_progress": trainingProgress,
            "muscle_group_analysis": [
                muscleGroup: trainingDetail
            ]
        ]
        
        do {
            // 将字典转为JSON数据
            guard let jsonData = try? JSONSerialization.data(withJSONObject: fitnessPreferencesData) else {
                print("训练偏好数据序列化失败")
                return
            }
            
            // 使用async/await方式调用NetworkService
            let response: FoodJourneyModels.UpdateResponse = try await NetworkService.shared.request(
                endpoint: "/profile/fitness",
                method: "PUT",
                body: jsonData,
                requiresAuth: true
            )
            
            print("训练偏好更新成功: \(response.message)")
            
            // 更新ViewModel中的数据 - 直接更新本地数据，避免额外的网络请求
            await MainActor.run {
                viewModel.trainingType = trainingType
                viewModel.muscleGroup = muscleGroup
            }
            
            // 不再调用刷新，因为我们已经手动更新了视图模型数据
            // await viewModel.refreshData()
        } catch {
            print("训练偏好更新失败: \(error.localizedDescription)")
        }
    }
}

struct TrainingProgressDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingProgressDetailView()
            .environmentObject(HealthTrackViewModel())
    }
}
