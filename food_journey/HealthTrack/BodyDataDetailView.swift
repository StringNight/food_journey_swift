import SwiftUI
import Charts

struct BodyDataDetailView: View {
    // 状态变量用于控制编辑模式
    @State private var isEditing = false
    
    // 用于存储用户输入的数据
    @State private var weight: String = "72"
    @State private var bodyFatPercentage: String = "20"
    @State private var muscleMass: String = "35"
    @State private var bmr: String = "1800"
    
    // 模拟数据
    let weightData: [WeightEntry] = [
        WeightEntry(day: "周一", weight: 72),
        WeightEntry(day: "周二", weight: 71.8),
        WeightEntry(day: "周三", weight: 72.2),
        WeightEntry(day: "周四", weight: 72),
        WeightEntry(day: "周五", weight: 71.9),
        WeightEntry(day: "周六", weight: 72.1),
        WeightEntry(day: "周日", weight: 72)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("身体数据")
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
                            // 这里添加保存数据到服务器或本地存储的逻辑
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
                
                // 基本指标
                VStack(alignment: .leading, spacing: 15) {
                    if isEditing {
                        // 编辑模式下显示输入框
                        HStack {
                            Text("体重 (kg):")
                                .frame(width: 100, alignment: .leading)
                            TextField("体重", text: $weight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("体脂率 (%):")
                                .frame(width: 100, alignment: .leading)
                            TextField("体脂率", text: $bodyFatPercentage)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("肌肉量 (kg):")
                                .frame(width: 100, alignment: .leading)
                            TextField("肌肉量", text: $muscleMass)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("基础代谢率:")
                                .frame(width: 100, alignment: .leading)
                            TextField("BMR", text: $bmr)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("kcal")
                        }
                    } else {
                        // 浏览模式下展示数据
                        VStack(alignment: .leading, spacing: 8) {
                            Text("体重: \(weight)kg")
                            Text("体脂率: \(bodyFatPercentage)%")
                            Text("肌肉量: \(muscleMass)kg")
                            Text("基础代谢率 (BMR): \(bmr) kcal")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // 图表展示
                Text("体重变化趋势（过去一周）")
                    .font(.headline)
                Chart {
                    ForEach(weightData) { entry in
                        LineMark(
                            x: .value("日期", entry.day),
                            y: .value("体重", entry.weight)
                        )
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // 分析与建议
                Text("分析与建议")
                    .font(.headline)
                Text("你的体脂率正在减少，但体重保持稳定。继续保持现有训练强度，增加肌肉量。")
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
        .navigationTitle("身体数据详情")
    }
    
    // 保存数据的方法
    private func saveData() async {
        // 转换输入数据为适当的类型
        let weightValue = Double(weight) ?? 0
        let bodyFatValue = Double(bodyFatPercentage) ?? 0
        let muscleMassValue = Double(muscleMass) ?? 0
        let bmrValue = Int(bmr) ?? 0
        
        // 准备请求数据
        let requestData: [String: Any] = [
            "weight": weightValue,
            "body_fat_percentage": bodyFatValue,
            "muscle_mass": muscleMassValue,
            "bmr": bmrValue
        ]
        
        do {
            // 将字典转为JSON数据
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
                print("体型数据序列化失败")
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
            print("体型数据更新成功: \(response.message)")
            // 可以在这里添加UI反馈，例如显示成功提示
            await MainActor.run {
                // 显示保存成功的反馈提示
                isEditing = false
            }
        } catch {
            // 错误处理
            print("体型数据更新失败: \(error.localizedDescription)")
            // 可以在这里添加错误处理，例如显示错误提示
            await MainActor.run {
                // 显示错误提示
            }
        }
        
        print("正在保存数据: 体重\(weight)kg, 体脂率\(bodyFatPercentage)%, 肌肉量\(muscleMass)kg, BMR\(bmr)kcal")
    }
}

struct WeightEntry: Identifiable {
    var id = UUID()
    var day: String
    var weight: Double
}

struct BodyDataDetailView_Previews: PreviewProvider {
    static var previews: some View {
        BodyDataDetailView()
    }
}
