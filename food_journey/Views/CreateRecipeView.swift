import SwiftUI

struct CreateRecipeView: View {
    @Binding var isPresented: Bool
    @StateObject private var recipeService = RecipeService.shared
    
    @State private var title = ""
    @State private var ingredients: [IngredientInput] = [IngredientInput()]
    @State private var steps: [StepInput] = [StepInput()]
    @State private var nutrition = NutritionInput()
    @State private var cookingTime = ""
    @State private var difficulty = "简单"
    @State private var tags: [String] = []
    @State private var currentTag: String = "" // 用于跟踪当前输入的标签
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    private let difficulties = ["简单", "中等", "困难"]
    
    struct IngredientInput {
        var name: String = ""
        var amount: String = ""
        var unit: String = ""
    }
    
    struct StepInput {
        var stepNumber: Int = 1
        var description: String = ""
        var tips: String = ""
    }
    
    struct NutritionInput {
        var calories: String = ""
        var protein: String = ""
        var carbs: String = ""
        var fat: String = ""
        var fiber: String = ""
    }
    
    var body: some View {
        NavigationView {
            if isLoading {
                loadingView
            } else {
                mainFormView
                    .navigationTitle("创建新食谱")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("取消") {
                                isPresented = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("保存") {
                                submitRecipe()
                            }
                            .disabled(title.isEmpty)
                        }
                    }
                    .alert("错误", isPresented: $showingError) {
                        Button("确定", role: .cancel) {}
                    } message: {
                        Text(errorMessage)
                    }
            }
        }
    }
    
    // 加载视图
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("正在保存...")
                .padding()
        }
    }
    
    // 主表单视图
    private var mainFormView: some View {
        Form {
            // 标题部分
            Section(header: Text("基本信息")) {
                TextField("标题", text: $title)
                
                HStack {
                    Text("难度")
                    Spacer()
                    Picker("难度", selection: $difficulty) {
                        ForEach(difficulties, id: \.self) { level in
                            Text(level).tag(level as String)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Text("烹饪时间")
                    Spacer()
                    TextField("分钟", text: $cookingTime)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            
            // 标签部分
            tagsSection
            
            // 食材部分
            ingredientsSection
            
            // 步骤部分
            stepsSection
            
            // 营养信息部分
            nutritionSection
        }
    }
    
    // 标签部分
    private var tagsSection: some View {
        Section {
            TextField("添加标签", text: $currentTag)
                .onSubmit {
                    addTag()
                }
            
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(zip(tags.indices, tags)), id: \.0) { index, tag in
                            TagView(tag: tag) {
                                removeTag(at: index)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("标签")
        }
    }
    
    @MainActor 
    private func addTag() {
        if !currentTag.isEmpty {
            let newTag: String = currentTag.trimmingCharacters(in: .whitespacesAndNewlines)
            tags.append(newTag)
            currentTag = ""
        }
    }
    
    @MainActor
    private func removeTag(at index: Int) {
        tags.remove(at: index)
    }
    
    private struct TagView: View {
        let tag: String
        let onRemove: () -> Void
        
        var body: some View {
            HStack {
                Text(tag)
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(red: 0.0, green: 0.47, blue: 1.0, opacity: 0.1))
            .cornerRadius(8)
        }
    }
    
    // 食材部分
    private var ingredientsSection: some View {
        Section(header: ingredientsSectionHeader) {
            ForEach(Array(ingredients.indices), id: \.self) { index in
                VStack {
                    TextField("食材名称", text: $ingredients[index].name)
                    
                    HStack {
                        TextField("数量", text: $ingredients[index].amount)
                            .keyboardType(.decimalPad)
                        TextField("单位", text: $ingredients[index].unit)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                ingredients.remove(atOffsets: indexSet)
            }
        }
    }
    
    // 食材部分的标题栏
    private var ingredientsSectionHeader: some View {
        HStack {
            Text("食材")
            Spacer()
            Button {
                ingredients.append(IngredientInput())
            } label: {
                Label("添加食材", systemImage: "plus.circle")
            }
        }
    }
    
    // 步骤部分
    private var stepsSection: some View {
        Section(header: stepsSectionHeader) {
            ForEach(Array(steps.indices), id: \.self) { index in
                VStack(alignment: .leading) {
                    Text("步骤 \(index + 1)")
                        .font(.headline)
                        .padding(.vertical, 4)
                    
                    TextField("描述", text: $steps[index].description, axis: .vertical)
                        .lineLimit(3...)
                    
                    TextField("小贴士（可选）", text: $steps[index].tips)
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                steps.remove(atOffsets: indexSet)
                // 重新计算步骤编号
                for i in 0..<steps.count {
                    steps[i].stepNumber = i + 1
                }
            }
        }
    }
    
    // 步骤部分的标题栏
    private var stepsSectionHeader: some View {
        HStack {
            Text("步骤")
            Spacer()
            Button {
                steps.append(StepInput(stepNumber: steps.count + 1))
            } label: {
                Label("添加步骤", systemImage: "plus.circle")
            }
        }
    }
    
    // 营养信息部分
    private var nutritionSection: some View {
        Section(header: Text("营养信息")) {
            HStack {
                Text("热量")
                Spacer()
                TextField("卡路里", text: $nutrition.calories)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
            
            HStack {
                Text("蛋白质")
                Spacer()
                TextField("克", text: $nutrition.protein)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
            
            HStack {
                Text("碳水化合物")
                Spacer()
                TextField("克", text: $nutrition.carbs)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
            
            HStack {
                Text("脂肪")
                Spacer()
                TextField("克", text: $nutrition.fat)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
            
            HStack {
                Text("膳食纤维")
                Spacer()
                TextField("克", text: $nutrition.fiber)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
        }
    }
    
    // 提交食谱方法
    private func submitRecipe() {
        // 验证输入
        guard !title.isEmpty else {
            showingError = true
            errorMessage = "请输入食谱标题"
            return
        }
        
        isLoading = true
        
        // 转换数据，使用实际的Recipe类型创建对象
        Task {
            do {
                let processedIngredients: [Ingredient] = ingredients.filter { !$0.name.isEmpty }.map { ingredient -> Ingredient in
                    return Ingredient(
                        id: UUID().uuidString,
                        name: ingredient.name,
                        amount: ingredient.amount.isEmpty ? "0" : ingredient.amount,
                        unit: ingredient.unit.isEmpty ? nil : ingredient.unit
                    )
                }
                
                let processedSteps: [Step] = steps.filter { !$0.description.isEmpty }.map { step -> Step in
                    return Step(
                        id: UUID().uuidString,
                        stepNumber: step.stepNumber,
                        description: step.description,
                        image: nil, 
                        tips: step.tips.isEmpty ? nil : step.tips
                    )
                }
                
                let processedNutrition: Nutrition = Nutrition(
                    calories: Float(nutrition.calories) ?? 0,
                    protein: Float(nutrition.protein) ?? 0,
                    carbs: Float(nutrition.carbs) ?? 0,
                    fat: Float(nutrition.fat) ?? 0,
                    fiber: nutrition.fiber.isEmpty ? nil : Float(nutrition.fiber),
                    vitamins: nil
                )
                
                let tagsArray: [String] = tags.isEmpty ? [] : tags
                
                let newRecipe: FoodJourneyModels.RecipeCreate = FoodJourneyModels.RecipeCreate(
                    title: title,
                    ingredients: processedIngredients,
                    steps: processedSteps,
                    nutrition: processedNutrition,
                    cooking_time: Int(cookingTime) ?? 0,
                    difficulty: difficulty,
                    tags: tagsArray
                )
                
                _ = try await recipeService.createRecipe(newRecipe)
                await MainActor.run {
                    isLoading = false
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showingError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    CreateRecipeView(isPresented: .constant(true))
}
