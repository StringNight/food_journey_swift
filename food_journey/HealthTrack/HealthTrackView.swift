import SwiftUI

// 主视图，显示健身追踪功能的入口页面
struct HealthTrackView: View {
    // 控制目标编辑模式
    @State private var isEditingGoals = false
    
    // 目标相关状态
    @State private var shortTermGoal: String = "增加5kg肌肉"
    @State private var longTermGoal: String = "体脂降至15%"
    
    // 目标数值
    @State private var targetMuscleGain: Double = 5.0 // 目标增肌量(kg)
    @State private var initialMuscleWeight: Double = 35.0 // 初始肌肉重量(kg)
    @State private var targetBodyFat: Double = 15.0 // 目标体脂率(%)
    @State private var initialBodyFat: Double = 22.0 // 初始体脂率(%)
    
    // 从BodyDataDetailView获取的数据 - 这里只是模拟，实际应该使用共享数据或环境变量
    private var currentMuscleWeight: Double = 39.0 // 当前肌肉重量(kg)
    private var currentBodyFat: Double = 20.0 // 当前体脂率(%)
    
    // 计算短期目标进度（增肌）
    private var shortTermProgress: Double {
        let gainedMuscle = currentMuscleWeight - initialMuscleWeight
        let progress = min(gainedMuscle / targetMuscleGain, 1.0)
        return max(0.0, progress) // 确保不为负数
    }
    
    // 计算长期目标进度（减脂）
    private var longTermProgress: Double {
        let totalReduction = initialBodyFat - targetBodyFat
        let currentReduction = initialBodyFat - currentBodyFat
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
                                    TextField("输入短期目标", text: $shortTermGoal)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(maxWidth: .infinity)
                                }
                                
                                // 长期目标输入
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("长期目标:")
                                        .font(.subheadline)
                                    TextField("输入长期目标", text: $longTermGoal)
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
                                        TextField("", value: $targetMuscleGain, formatter: NumberFormatter())
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
                                        TextField("", value: $initialMuscleWeight, formatter: NumberFormatter())
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
                                        TextField("", value: $targetBodyFat, formatter: NumberFormatter())
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
                                        TextField("", value: $initialBodyFat, formatter: NumberFormatter())
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
                                    Text(shortTermGoal)
                                        .font(.subheadline)
                                    ProgressView(value: shortTermProgress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                        .padding(.vertical, 4)
                                    Text("增肌进度: \(String(format: "%.1f", currentMuscleWeight - initialMuscleWeight))/\(String(format: "%.1f", targetMuscleGain))kg")
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
                                    Text(longTermGoal)
                                        .font(.subheadline)
                                    ProgressView(value: longTermProgress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                        .padding(.vertical, 4)
                                    Text("减脂进度: 从\(String(format: "%.1f", initialBodyFat))%降至\(String(format: "%.1f", currentBodyFat))%，目标\(String(format: "%.1f", targetBodyFat))%")
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
                        NavigationLink(destination: BodyDataDetailView()) {
                            CardView(title: "身体数据",
                                     subtitle: "体重: 72kg, 体脂率: \(String(format: "%.1f", currentBodyFat))%",
                                     icon: "heart.fill")
                        }
                        NavigationLink(destination: TrainingProgressDetailView()) {
                            CardView(title: "训练进度",
                                     subtitle: "今日: 腿部训练，完成3/5组深蹲",
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
