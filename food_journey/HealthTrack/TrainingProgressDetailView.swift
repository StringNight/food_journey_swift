import SwiftUI

struct TrainingProgressDetailView: View {
    // 接收从父视图传递的视图模型
    @EnvironmentObject var viewModel: HealthTrackViewModel
    
    // 状态变量用于控制编辑模式
    @State private var isEditing = false
    
    // 移除本地状态变量，改用 ViewModel 中的数据
    
    var body: some View {
        ZStack {
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
                                    await viewModel.saveTrainingData()
                                }
                                isEditing = false
                            }) {
                                Text("保存")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    // 当前训练卡片
                    VStack(alignment: .leading, spacing: 15) {
                        Text("当前训练")
                            .font(.headline)
                        
                        if isEditing {
                            // 编辑模式下的训练类型和肌肉群
                            VStack(spacing: 15) {
                                // 训练类型
                                HStack {
                                    Text("训练类型:")
                                        .frame(width: 100, alignment: .leading)
                                    TextField("例如：深蹲、卧推", text: $viewModel.trainingType)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // 肌肉群
                                HStack {
                                    Text("目标肌群:")
                                        .frame(width: 100, alignment: .leading)
                                    TextField("例如：腿部、胸部", text: $viewModel.muscleGroup)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // 完成组数
                                HStack {
                                    Text("完成组数:")
                                        .frame(width: 100, alignment: .leading)
                                    Stepper("\(viewModel.completedSets)/\(viewModel.totalSets) 组", value: $viewModel.completedSets, in: 0...viewModel.totalSets)
                                }
                                
                                // 总组数
                                HStack {
                                    Text("总组数:")
                                        .frame(width: 100, alignment: .leading)
                                    Stepper("\(viewModel.totalSets) 组", value: $viewModel.totalSets, in: 1...10)
                                }
                                
                                // 训练详情
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("训练详情:")
                                        .frame(width: 100, alignment: .leading)
                                    TextEditor(text: $viewModel.trainingDetail)
                                        .frame(height: 100)
                                        .padding(4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        } else {
                            // 查看模式下的训练信息
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("训练类型:")
                                        .foregroundColor(.gray)
                                    Text(viewModel.trainingType)
                                        .bold()
                                }
                                
                                HStack {
                                    Text("目标肌群:")
                                        .foregroundColor(.gray)
                                    Text(viewModel.muscleGroup)
                                        .bold()
                                }
                                
                                HStack {
                                    Text("训练进度:")
                                        .foregroundColor(.gray)
                                    Text("\(viewModel.completedSets)/\(viewModel.totalSets) 组")
                                        .bold()
                                }
                                
                                // 进度条
                                ProgressView(value: Double(viewModel.completedSets), total: Double(max(1, viewModel.totalSets)))
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .tint(.blue)
                                    .padding(.vertical, 5)
                                
                                Text("训练详情:")
                                    .foregroundColor(.gray)
                                Text(viewModel.trainingDetail)
                                    .padding(.leading, 5)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // 恢复建议卡片
                    VStack(alignment: .leading, spacing: 15) {
                        Text("恢复建议")
                            .font(.headline)
                        
                        if isEditing {
                            // 编辑模式下的建议
                            VStack(spacing: 15) {
                                // 休息建议
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("休息建议:")
                                        .frame(alignment: .leading)
                                    TextEditor(text: $viewModel.restAdvice)
                                        .frame(height: 80)
                                        .padding(4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
                                // 下次训练建议
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("下次训练:")
                                        .frame(alignment: .leading)
                                    TextField("例如：背部训练", text: $viewModel.nextTraining)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        } else {
                            // 查看模式下的建议
                            VStack(alignment: .leading, spacing: 10) {
                                Text("休息建议:")
                                    .foregroundColor(.gray)
                                Text(viewModel.restAdvice)
                                    .padding(.leading, 5)
                                
                                Text("下次训练:")
                                    .foregroundColor(.gray)
                                Text(viewModel.nextTraining)
                                    .bold()
                                    .padding(.leading, 5)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // 历史训练记录（占位）
                    VStack(alignment: .leading, spacing: 10) {
                        Text("历史训练记录")
                            .font(.headline)
                        
                        // 示例历史记录
                        ForEach(["胸部训练 (2天前)", "背部训练 (4天前)", "腿部训练 (6天前)"], id: \.self) { record in
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 10, height: 10)
                                Text(record)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // 错误显示区域
                    if let error = viewModel.trainingDataLoadError {
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
                // 视图出现时加载最新数据
                Task {
                    await viewModel.forceRefreshData()
                }
            }
            
            // 保存中覆盖层
            if viewModel.isTrainingDataSaving {
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
            if viewModel.showTrainingDataSaveSuccess {
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
        .navigationTitle("训练进度")
    }
}

struct TrainingProgressDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingProgressDetailView()
            .environmentObject(HealthTrackViewModel())
    }
}
