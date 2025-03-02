import SwiftUI

struct RecoveryDetailView: View {
    // 状态变量用于控制编辑模式
    @State private var isEditing = false
    
    // 用于存储用户输入的恢复数据
    @State private var sleepHours: String = "7"
    @State private var deepSleepPercentage: String = "50"
    @State private var fatigueRating: Int = 4
    @State private var recoveryAdvice: String = "根据你的疲劳感，建议进行轻柔的瑜伽或拉伸。"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("恢复详情")
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
                
                // 睡眠分析
                VStack(alignment: .leading, spacing: 8) {
                    Text("睡眠分析")
                        .font(.headline)
                    
                    if isEditing {
                        // 编辑模式下的睡眠数据输入
                        HStack {
                            Text("睡眠时长:")
                                .frame(width: 80, alignment: .leading)
                            TextField("睡眠时长", text: $sleepHours)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("小时")
                        }
                        
                        HStack {
                            Text("深睡比例:")
                                .frame(width: 80, alignment: .leading)
                            TextField("深睡比例", text: $deepSleepPercentage)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("%")
                        }
                    } else {
                        Text("睡眠时长: \(sleepHours)小时")
                        Text("深睡: \(deepSleepPercentage)%")
                    }
                    
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(height: 150)
                        .overlay(Text("睡眠趋势图"))
                        .cornerRadius(10)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // 疲劳感评估（星级评分）
                VStack(alignment: .leading, spacing: 8) {
                    Text("疲劳感评估")
                        .font(.headline)
                    
                    if isEditing {
                        // 编辑模式下的星级选择器
                        HStack {
                            ForEach(1...5, id: \.self) { rating in
                                Image(systemName: rating <= fatigueRating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .onTapGesture {
                                        fatigueRating = rating
                                    }
                            }
                        }
                        Text("点击星星设置疲劳感评分")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        HStack {
                            ForEach(0..<5) { index in
                                Image(systemName: index < fatigueRating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    Text("疲劳感: \(fatigueRating)/5")
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // 恢复活动建议
                VStack(alignment: .leading, spacing: 8) {
                    Text("恢复活动建议")
                        .font(.headline)
                    
                    if isEditing {
                        TextField("恢复建议", text: $recoveryAdvice)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(recoveryAdvice)
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
        .navigationTitle("恢复详情")
    }
    
    // 保存数据的方法
    private func saveData() async {
        // 转换输入数据为适当的类型
        let sleepDuration = Double(sleepHours) ?? 0
        let deepSleepValue = Double(deepSleepPercentage) ?? 0
        
        // 准备请求数据
        let requestData: [String: Any] = [
            "sleep_duration": sleepDuration,
            "deep_sleep_percentage": deepSleepValue,
            "fatigue_score": fatigueRating,
            "extended_attributes": [
                "recovery_advice": recoveryAdvice
            ]
        ]
        
        do {
            // 将字典转为JSON数据
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
                print("恢复数据序列化失败")
                return
            }
            
            // 使用async/await方式调用NetworkService
            let response: FoodJourneyModels.UpdateResponse = try await NetworkService.shared.request(
                endpoint: "/profile/fitness",
                method: "PUT",
                body: jsonData,
                requiresAuth: true
            )
            
            // 成功处理
            print("恢复数据更新成功: \(response.message)")
            // 可以在这里添加UI反馈，例如显示成功提示
            await MainActor.run {
                // 显示保存成功的反馈提示
                isEditing = false
            }
        } catch {
            // 错误处理
            print("恢复数据更新失败: \(error.localizedDescription)")
            // 可以在这里添加错误处理，例如显示错误提示
            await MainActor.run {
                // 显示错误提示
            }
        }
        
        print("保存恢复数据: 睡眠\(sleepHours)小时, 深度睡眠\(deepSleepPercentage)%, 疲劳感\(fatigueRating)分")
    }
}

struct RecoveryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryDetailView()
    }
}
