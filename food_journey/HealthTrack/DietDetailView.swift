import SwiftUI

struct DietDetailView: View {
    // 添加对HealthTrackViewModel的引用
    @EnvironmentObject var viewModel: HealthTrackViewModel
    
    // 状态变量用于控制编辑模式
    @State private var isEditing = false
    
    var body: some View {
        ZStack {
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
                                    await viewModel.saveDietData()
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
                                    TextField("早餐内容", text: $viewModel.breakfast)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                HStack {
                                    Text("午餐:")
                                        .frame(width: 60, alignment: .leading)
                                    TextField("午餐内容", text: $viewModel.lunch)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                HStack {
                                    Text("晚餐:")
                                        .frame(width: 60, alignment: .leading)
                                    TextField("晚餐内容", text: $viewModel.dinner)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        } else {
                            Text("早餐: \(viewModel.breakfast)")
                            Text("午餐: \(viewModel.lunch)")
                            Text("晚餐: \(viewModel.dinner)")
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
                                    TextField("热量", text: $viewModel.calories)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    Text("kcal")
                                }
                                
                                HStack {
                                    Text("热量目标:")
                                        .frame(width: 80, alignment: .leading)
                                    TextField("热量目标", text: $viewModel.caloriesTarget)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    Text("kcal")
                                }
                                
                                HStack {
                                    Text("蛋白质:")
                                        .frame(width: 80, alignment: .leading)
                                    TextField("蛋白质", text: $viewModel.protein)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    Text("g")
                                }
                                
                                HStack {
                                    Text("脂肪:")
                                        .frame(width: 80, alignment: .leading)
                                    TextField("脂肪", text: $viewModel.fat)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    Text("g")
                                }
                                
                                HStack {
                                    Text("碳水:")
                                        .frame(width: 80, alignment: .leading)
                                    TextField("碳水化合物", text: $viewModel.carbs)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    Text("g")
                                }
                                
                                HStack {
                                    Text("建议:")
                                        .frame(width: 80, alignment: .leading)
                                    TextField("饮食建议", text: $viewModel.dietAdvice)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        } else {
                            Text("热量: \(viewModel.calories) kcal (目标: \(viewModel.caloriesTarget) kcal)")
                            Text("蛋白质: \(viewModel.protein)g")
                            Text("脂肪: \(viewModel.fat)g")
                            Text("碳水化合物: \(viewModel.carbs)g")
                            Text("建议: \(viewModel.dietAdvice)")
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
                    
                    // 错误显示区域
                    if let error = viewModel.dietLoadError {
                        Text("加载数据失败: \(error)")
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    Spacer()
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
            if viewModel.isDietDataSaving {
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
            if viewModel.showDietSaveSuccess {
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
        .navigationTitle("饮食详情")
    }
}

struct DietDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DietDetailView()
            .environmentObject(HealthTrackViewModel())
    }
}
