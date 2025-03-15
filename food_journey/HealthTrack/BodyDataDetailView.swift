import SwiftUI
import Charts

struct BodyDataDetailView: View {
    // 接收从父视图传递的视图模型
    @EnvironmentObject var viewModel: HealthTrackViewModel
    
    // 状态变量用于控制编辑模式
    @State private var isEditing = false
    
    // 时间范围选择
    @State private var selectedTimeRange: TimeRange = .week
    
    // 体重和体脂率数据（按周显示）
    let weeklyData: [DataPoint] = [
        DataPoint(day: "周一", weight: 72.0, bodyFat: 20.5),
        DataPoint(day: "周二", weight: 71.8, bodyFat: 20.3),
        DataPoint(day: "周三", weight: 72.2, bodyFat: 20.6),
        DataPoint(day: "周四", weight: 72.0, bodyFat: 20.2),
        DataPoint(day: "周五", weight: 71.9, bodyFat: 20.0),
        DataPoint(day: "周六", weight: 72.1, bodyFat: 19.8),
        DataPoint(day: "周日", weight: 72.0, bodyFat: 19.5)
    ]
    
    // 月度数据
    let monthlyData: [DataPoint] = [
        DataPoint(day: "第1周", weight: 72.0, bodyFat: 20.5),
        DataPoint(day: "第2周", weight: 71.7, bodyFat: 20.0),
        DataPoint(day: "第3周", weight: 71.5, bodyFat: 19.6),
        DataPoint(day: "第4周", weight: 71.2, bodyFat: 19.2)
    ]
    
    // 季度数据
    let quarterlyData: [DataPoint] = [
        DataPoint(day: "1月", weight: 73.0, bodyFat: 21.0),
        DataPoint(day: "2月", weight: 72.5, bodyFat: 20.5),
        DataPoint(day: "3月", weight: 72.0, bodyFat: 20.0),
        DataPoint(day: "4月", weight: 71.5, bodyFat: 19.5),
        DataPoint(day: "5月", weight: 71.0, bodyFat: 19.0),
        DataPoint(day: "6月", weight: 70.5, bodyFat: 18.5)
    ]
    
    // 获取当前选择的数据
    var currentData: [DataPoint] {
        switch selectedTimeRange {
        case .week:
            return weeklyData
        case .month:
            return monthlyData
        case .quarter:
            return quarterlyData
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("身体数据")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // 添加编辑按钮
                        Button(action: {
                            isEditing.toggle()
                            // 如果取消编辑，重新加载数据
                            if !isEditing {
                                Task {
                                    await viewModel.forceRefreshData()
                                }
                            }
                        }) {
                            Text(isEditing ? "取消" : "编辑")
                                .foregroundColor(.blue)
                        }
                        
                        if isEditing {
                            // 保存按钮
                            Button(action: {
                                // 使用 ViewModel 的保存方法
                                Task {
                                    await viewModel.saveBodyData()
                                }
                                isEditing = false
                            }) {
                                Text("保存")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 显示基础身体数据
                    VStack(spacing: 20) {
                        // 体重信息
                        if isEditing {
                            HStack {
                                Text("体重:")
                                    .frame(width: 100, alignment: .leading)
                                TextField("当前体重", value: $viewModel.currentWeight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("kg")
                            }
                            .padding(.horizontal)
                        } else {
                            HStack {
                                Text("体重:")
                                    .frame(width: 100, alignment: .leading)
                                Text("\(String(format: "%.1f", viewModel.currentWeight)) kg")
                                    .bold()
                            }
                            .padding(.horizontal)
                        }
                        
                        // 体脂率信息
                        if isEditing {
                            HStack {
                                Text("体脂率:")
                                    .frame(width: 100, alignment: .leading)
                                TextField("体脂率", value: $viewModel.currentBodyFat, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("%")
                            }
                            .padding(.horizontal)
                        } else {
                            HStack {
                                Text("体脂率:")
                                    .frame(width: 100, alignment: .leading)
                                Text("\(String(format: "%.1f", viewModel.currentBodyFat))%")
                                    .bold()
                            }
                            .padding(.horizontal)
                        }
                        
                        // 肌肉量信息
                        if isEditing {
                            HStack {
                                Text("肌肉量:")
                                    .frame(width: 100, alignment: .leading)
                                TextField("肌肉量", value: $viewModel.currentMuscleWeight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("kg")
                            }
                            .padding(.horizontal)
                        } else {
                            HStack {
                                Text("肌肉量:")
                                    .frame(width: 100, alignment: .leading)
                                Text("\(String(format: "%.1f", viewModel.currentMuscleWeight)) kg")
                                    .bold()
                            }
                            .padding(.horizontal)
                        }
                        
                        // 基础代谢率信息
                        if isEditing {
                            HStack {
                                Text("基础代谢率:")
                                    .frame(width: 100, alignment: .leading)
                                TextField("基础代谢率", text: $viewModel.bmr)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("kcal/天")
                            }
                            .padding(.horizontal)
                        } else {
                            HStack {
                                Text("基础代谢率:")
                                    .frame(width: 100, alignment: .leading)
                                Text("\(viewModel.bmr) kcal/天")
                                    .bold()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // 时间范围选择器
                    VStack(alignment: .leading, spacing: 10) {
                        Text("数据展示范围")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Picker("时间范围", selection: $selectedTimeRange) {
                            Text("按周").tag(TimeRange.week)
                            Text("按月").tag(TimeRange.month)
                            Text("按季度").tag(TimeRange.quarter)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // 趋势图表标题
                    Text("体重和体脂率趋势图")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    VStack(alignment: .leading) {
                        // 组合图表
                        combinedBodyDataChart
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // 体脂率分析建议
                    Text("体脂率分析与建议")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        // 当前状态
                        HStack {
                            Text("当前状态:")
                                .foregroundColor(.gray)
                            Text(bodyFatStatusText)
                                .bold()
                                .foregroundColor(bodyFatStatusColor)
                        }
                        .padding(.horizontal)
                        
                        // 个性化建议
                        Text("健康建议:")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        Text(bodyFatAdviceText)
                            .padding(.horizontal)
                            .padding(.top, 2)
                        
                        // 健康目标
                        if let targetBodyFat = bodyFatTargetText {
                            Text("推荐目标:")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.top, 5)
                            
                            Text(targetBodyFat)
                                .padding(.horizontal)
                                .padding(.top, 2)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // 显示错误消息
                    if let error = viewModel.bodyDataLoadError {
                        Text("错误: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .onAppear {
                // 视图出现时加载最新数据
                Task {
                    await viewModel.forceRefreshData()
                }
            }
            
            // 保存中覆盖层
            if viewModel.isBodyDataSaving {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("正在保存...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .frame(width: 150, height: 150)
                .background(Color.gray.opacity(0.7))
                .cornerRadius(10)
            }
            
            // 保存成功覆盖层
            if viewModel.showBodyDataSaveSuccess {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.green)
                        .padding()
                    Text("保存成功")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .frame(width: 150, height: 150)
                .background(Color.gray.opacity(0.7))
                .cornerRadius(10)
            }
        }
        .navigationTitle("身体数据")
    }
    
    // 使用简化的单图表实现，体重和体脂率分别使用不同Y轴
    private var combinedBodyDataChart: some View {
        VStack(spacing: 0) {
            // 图表标签
            HStack {
                Text("体重 (kg)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.blue)
                
                Spacer()
                
                Text("体脂率 (%)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.orange)
            }
            .padding(.horizontal, 20)  // 增加水平内边距以对齐Y轴标签
            
            // 图表区域
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // 左侧体重Y轴标签区域
                    VStack(spacing: 0) {
                        ForEach(0..<6) { i in
                            if i > 0 {
                                Spacer()
                            }
                            Text(weightAxisLabels[i])
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                                .frame(width: 40, alignment: .trailing)  // 固定宽度并右对齐
                            if i < 5 {
                                Spacer()
                            }
                        }
                    }
                    .frame(width: 40)  // 固定左侧标签宽度
                    .padding(.top, 8)
                    .padding(.bottom, 20)  // 为X轴留出空间
                    
                    // 中央图表区域
                    ZStack {
                        // 网格线
                        GridLinesView()
                        
                        // 数据线和点
                        let chartWidth = geo.size.width - 80  // 减去左右标签区域的宽度
                        let dataCount = currentData.count
                        
                        // 体重数据线
                        Path { path in
                            for i in 0..<dataCount {
                                let x = chartWidth * CGFloat(i) / CGFloat(max(1, dataCount - 1))
                                let normalizedValue = (currentData[i].weight - weightRange.lowerBound) / (weightRange.upperBound - weightRange.lowerBound)
                                let y = (geo.size.height - 20) * (1 - CGFloat(normalizedValue))  // 减去底部X轴空间
                                
                                if i == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.blue, lineWidth: 2)
                        
                        // 体脂率数据线
                        Path { path in
                            for i in 0..<dataCount {
                                let x = chartWidth * CGFloat(i) / CGFloat(max(1, dataCount - 1))
                                let normalizedValue = (currentData[i].bodyFat - bodyFatRange.lowerBound) / (bodyFatRange.upperBound - bodyFatRange.lowerBound)
                                let y = (geo.size.height - 20) * (1 - CGFloat(normalizedValue))  // 减去底部X轴空间
                                
                                if i == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.orange, lineWidth: 2)
                        
                        // 体重数据点和标签 - 交错显示以避免拥挤
                        ForEach(0..<dataCount, id: \.self) { i in
                            let x = chartWidth * CGFloat(i) / CGFloat(max(1, dataCount - 1))
                            let normalizedValue = (currentData[i].weight - weightRange.lowerBound) / (weightRange.upperBound - weightRange.lowerBound)
                            let y = (geo.size.height - 20) * (1 - CGFloat(normalizedValue))  // 减去底部X轴空间
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                            
                            if i % 2 == 0 || i == dataCount - 1 {
                                Text(String(format: "%.1f", currentData[i].weight))
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                                    .position(x: x, y: max(10, y - 12))
                            }
                        }
                        
                        // 体脂率数据点和标签 - 交错显示以避免拥挤
                        ForEach(0..<dataCount, id: \.self) { i in
                            let x = chartWidth * CGFloat(i) / CGFloat(max(1, dataCount - 1))
                            let normalizedValue = (currentData[i].bodyFat - bodyFatRange.lowerBound) / (bodyFatRange.upperBound - bodyFatRange.lowerBound)
                            let y = (geo.size.height - 20) * (1 - CGFloat(normalizedValue))  // 减去底部X轴空间
                            
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                            
                            if i % 2 == 1 || i == 0 {
                                Text(String(format: "%.1f", currentData[i].bodyFat))
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                    .position(x: x, y: max(10, y - 12))
                            }
                        }
                        
                        // X轴标签位置
                        VStack {
                            Spacer()
                            HStack(spacing: 0) {
                                ForEach(0..<dataCount, id: \.self) { i in
                                    Text(currentData[i].day)
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                        .frame(width: chartWidth / CGFloat(dataCount))
                                }
                            }
                        }
                        .padding(.bottom, 3)  // 微调底部间距
                    }
                    .frame(height: geo.size.height)
                    
                    // 右侧体脂率Y轴标签区域
                    VStack(spacing: 0) {
                        ForEach(0..<6) { i in
                            if i > 0 {
                                Spacer()
                            }
                            Text(bodyFatAxisLabels[i])
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                                .frame(width: 40, alignment: .leading)  // 固定宽度并左对齐
                            if i < 5 {
                                Spacer()
                            }
                        }
                    }
                    .frame(width: 40)  // 固定右侧标签宽度
                    .padding(.top, 8)
                    .padding(.bottom, 20)  // 为X轴留出空间
                }
            }
        }
        .frame(height: 250)  // 保持整体高度
    }
    
    // 网格线视图 - 更淡的网格线
    private struct GridLinesView: View {
        var body: some View {
            ZStack {
                // 水平线
                VStack(spacing: 0) {
                    ForEach(0..<6) { _ in
                        Spacer()
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 1)
                    }
                }
                
                // 垂直线
                HStack(spacing: 0) {
                    ForEach(0..<7) { _ in
                        Spacer()
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 1)
                    }
                    Spacer()
                }
            }
        }
    }
    
    // 计算体重Y轴标签
    private var weightAxisLabels: [String] {
        let min = weightRange.lowerBound
        let max = weightRange.upperBound
        let range = max - min
        let step = range / 5.0
        
        return (0...5).map { i in
            let value = max - step * Double(i)
            return String(format: "%.1f", value)
        }
    }
    
    // 计算体脂率Y轴标签
    private var bodyFatAxisLabels: [String] {
        let min = bodyFatRange.lowerBound
        let max = bodyFatRange.upperBound
        let range = max - min
        let step = range / 5.0
        
        return (0...5).map { i in
            let value = max - step * Double(i)
            return String(format: "%.1f", value)
        }
    }
    
    // 计算体重的范围以调整Y轴
    private var weightRange: ClosedRange<Double> {
        if let min = currentData.map({ $0.weight }).min(),
           let max = currentData.map({ $0.weight }).max() {
            // 扩展范围到比最小值小1.5kg，比最大值大1.5kg，确保数据线不会太靠近边缘
            let minValue = Swift.max(0, min - 1.5)
            let maxValue = max + 1.5
            return minValue...maxValue
        }
        return 50...90 // 默认范围
    }
    
    // 计算体脂率的范围以调整Y轴
    private var bodyFatRange: ClosedRange<Double> {
        if let min = currentData.map({ $0.bodyFat }).min(),
           let max = currentData.map({ $0.bodyFat }).max() {
            // 扩展范围到比最小值小1.5%，比最大值大1.5%，确保数据线不会太靠近边缘
            let minValue = Swift.max(0, min - 1.5)
            let maxValue = max + 1.5
            return minValue...maxValue
        }
        return 10...30 // 默认范围
    }
    
    // 添加用于计算均匀刻度的辅助方法
    
    // 计算体重Y轴刻度间隔，确保有5个均匀的刻度
    private func calculateWeightStride() -> Double {
        let range = weightRange.upperBound - weightRange.lowerBound
        return range / 5.0
    }
    
    // 计算体脂率Y轴刻度间隔，确保有5个均匀的刻度
    private func calculateBodyFatStride() -> Double {
        let range = bodyFatRange.upperBound - bodyFatRange.lowerBound
        return range / 5.0
    }
}

// 时间范围枚举
enum TimeRange {
    case week
    case month
    case quarter
}

// 组合数据模型，包含体重和体脂率
struct DataPoint: Identifiable {
    let id = UUID()
    let day: String
    let weight: Double
    let bodyFat: Double
}

// 添加计算属性获取体脂率状态描述和建议
extension BodyDataDetailView {
    // 获取当前体脂率状态
    var bodyFatStatusText: String {
        let bodyFat = viewModel.currentBodyFat
        
        // 假设用户为男性（理想情况下应根据用户性别判断）
        // 这里为简化实现，可以根据用户配置文件中的性别信息进行调整
        if bodyFat < 6 {
            return "必要体脂水平（过低）"
        } else if bodyFat < 14 {
            return "运动员水平"
        } else if bodyFat < 18 {
            return "健身水平"
        } else if bodyFat < 25 {
            return "平均水平"
        } else {
            return "超重水平"
        }
    }
    
    // 获取体脂率状态颜色
    var bodyFatStatusColor: Color {
        let bodyFat = viewModel.currentBodyFat
        
        if bodyFat < 6 {
            return .orange  // 过低警告
        } else if bodyFat < 18 {
            return .green   // 良好
        } else if bodyFat < 25 {
            return .blue    // 一般
        } else {
            return .red     // 偏高
        }
    }
    
    // 获取体脂率建议
    var bodyFatAdviceText: String {
        let bodyFat = viewModel.currentBodyFat
        
        // 根据体脂率提供相应建议
        if bodyFat < 6 {
            return "您的体脂率低于健康水平，建议增加适当热量摄入，尤其是健康脂肪。过低的体脂率可能影响激素分泌和免疫系统功能。"
        } else if bodyFat < 14 {
            return "您的体脂率处于运动员水平，非常健康。继续保持均衡饮食和有规律的训练，确保充分休息和恢复。"
        } else if bodyFat < 18 {
            return "您的体脂率处于健身爱好者水平，肌肉轮廓清晰可见。保持当前的饮食和训练计划，注意训练的多样性以平衡肌肉发展。"
        } else if bodyFat < 25 {
            return "您的体脂率处于平均水平。建议增加每周3-5次有氧运动，结合力量训练和控制碳水化合物摄入，特别是精制碳水。控制热量摄入，增加蛋白质摄入，有助于减少体脂。"
        } else {
            return "您的体脂率高于健康水平。建议在专业健康顾问指导下制定减脂计划，包括：减少总热量摄入，控制精制糖和碳水化合物，增加蛋白质摄入，每天至少30分钟中等强度有氧运动，每周至少2-3次力量训练。"
        }
    }
    
    // 获取推荐目标
    var bodyFatTargetText: String? {
        let bodyFat = viewModel.currentBodyFat
        
        if bodyFat < 6 {
            return "建议在3个月内将体脂率提高到10%以上"
        } else if bodyFat > 20 {
            return "建议在6个月内将体脂率降低到18%以下，每月平均降低0.5-1%的体脂率是健康安全的"
        }
        
        return nil  // 体脂率在健康范围内不需要特别目标
    }
}

struct BodyDataDetailView_Previews: PreviewProvider {
    static var previews: some View {
        BodyDataDetailView()
            .environmentObject(HealthTrackViewModel())
    }
}

