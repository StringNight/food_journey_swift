import SwiftUI

struct RecoveryDetailView: View {
    // 接收从父视图传递的视图模型
    @EnvironmentObject var viewModel: HealthTrackViewModel
    
    // 状态变量用于控制编辑模式
    @State private var isEditing = false
    
    // 移除本地状态变量，使用 ViewModel 中的数据
    
    var body: some View {
        ZStack {
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
                                    await viewModel.saveRecoveryData()
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
                            VStack(spacing: 12) {
                                HStack {
                                    Text("睡眠时长:")
                                        .frame(width: 100, alignment: .leading)
                                    TextField("睡眠时长", text: $viewModel.sleepHours)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    Text("小时")
                                }
                                
                                HStack {
                                    Text("深度睡眠:")
                                        .frame(width: 100, alignment: .leading)
                                    TextField("深度睡眠百分比", text: $viewModel.deepSleepPercentage)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    Text("%")
                                }
                            }
                        } else {
                            // 查看模式下的睡眠数据显示
                            HStack {
                                Text("睡眠时长:")
                                    .frame(width: 100, alignment: .leading)
                                Text("\(viewModel.sleepHours) 小时")
                                    .bold()
                            }
                            
                            HStack {
                                Text("深度睡眠:")
                                    .frame(width: 100, alignment: .leading)
                                Text("\(viewModel.deepSleepPercentage)%")
                                    .bold()
                            }
                        }
                        
                        // 睡眠质量图表（简化版）
                        VStack(alignment: .leading, spacing: 5) {
                            Text("睡眠周期")
                                .font(.subheadline)
                                .padding(.top, 10)
                            
                            HStack(spacing: 0) {
                                // 睡眠阶段的简化表示
                                Rectangle()
                                    .fill(Color(UIColor.systemBlue).opacity(0.3))
                                    .frame(width: 50, height: 30)
                                Rectangle()
                                    .fill(Color(UIColor.systemBlue).opacity(0.6))
                                    .frame(width: 70, height: 30)
                                Rectangle()
                                    .fill(Color(UIColor.systemBlue).opacity(0.9))
                                    .frame(width: 40, height: 30)
                                Rectangle()
                                    .fill(Color(UIColor.systemBlue).opacity(0.6))
                                    .frame(width: 60, height: 30)
                                Rectangle()
                                    .fill(Color(UIColor.systemBlue).opacity(0.3))
                                    .frame(width: 30, height: 30)
                            }
                            .cornerRadius(5)
                            
                            HStack {
                                Text("浅睡眠")
                                    .font(.caption)
                                    .foregroundColor(.blue.opacity(0.5))
                                Spacer()
                                Text("深睡眠")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Spacer()
                                Text("REM")
                                    .font(.caption)
                                    .foregroundColor(.blue.opacity(0.7))
                            }
                            .padding(.top, 5)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // 疲劳感评分
                    VStack(alignment: .leading, spacing: 8) {
                        Text("疲劳感评分")
                            .font(.headline)
                        
                        if isEditing {
                            // 编辑模式下的疲劳感评分
                            VStack(alignment: .leading, spacing: 10) {
                                Text("当前疲劳程度 (1-5):")
                                    .font(.subheadline)
                                
                                HStack {
                                    ForEach(1..<6) { rating in
                                        Button(action: {
                                            viewModel.fatigueRating = rating
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(viewModel.fatigueRating >= rating ? Color.blue : Color.gray.opacity(0.3))
                                                    .frame(width: 50, height: 50)
                                                
                                                Text("\(rating)")
                                                    .foregroundColor(.white)
                                                    .font(.headline)
                                            }
                                        }
                                        if rating < 5 {
                                            Spacer()
                                        }
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        } else {
                            // 查看模式下的疲劳感评分
                            VStack(alignment: .leading, spacing: 10) {
                                Text("当前疲劳程度: \(viewModel.fatigueRating)/5")
                                    .font(.subheadline)
                                
                                HStack {
                                    ForEach(1..<6) { rating in
                                        Circle()
                                            .fill(viewModel.fatigueRating >= rating ? Color.blue : Color.gray.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Text("\(rating)")
                                                    .foregroundColor(.white)
                                                    .font(.headline)
                                            )
                                        if rating < 5 {
                                            Spacer()
                                        }
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // 恢复建议
                    VStack(alignment: .leading, spacing: 8) {
                        Text("恢复建议")
                            .font(.headline)
                        
                        if isEditing {
                            // 编辑模式下的恢复建议
                            TextEditor(text: $viewModel.recoveryAdvice)
                                .frame(height: 120)
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            // 查看模式下的恢复建议
                            Text(viewModel.recoveryAdvice)
                                .padding(.vertical, 5)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // 错误显示区域
                    if let error = viewModel.recoveryDataLoadError {
                        Text("加载数据失败: \(error)")
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .onAppear {
                // 视图出现时，加载最新数据
                Task {
                    await viewModel.forceRefreshData()
                }
            }
            
            // 保存中覆盖层
            if viewModel.isRecoveryDataSaving {
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
            if viewModel.showRecoveryDataSaveSuccess {
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
        .navigationTitle("恢复详情")
    }
}

struct RecoveryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryDetailView()
            .environmentObject(HealthTrackViewModel())
    }
}
