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
            Form {
                Section(header: Text("基本信息")) {
                    TextField("菜谱名称", text: $title)
                    TextField("烹饪时间（分钟）", text: $cookingTime)
                        .keyboardType(.numberPad)
                    Picker("难度", selection: $difficulty) {
                        ForEach(difficulties, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                Section(header: Text("食材")) {
                    ForEach($ingredients.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("食材名称", text: $ingredients[index].name)
                            HStack {
                                TextField("用量", text: $ingredients[index].amount)
                                    .keyboardType(.decimalPad)
                                TextField("单位（可选）", text: $ingredients[index].unit)
                            }
                            Divider()
                        }
                    }
                    Button("添加食材") {
                        ingredients.append(IngredientInput())
                    }
                }
                
                Section(header: Text("烹饪步骤")) {
                    ForEach($steps.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("步骤 \(index + 1)")
                                .font(.headline)
                            TextEditor(text: $steps[index].description)
                                .frame(height: 80)
                            TextField("小贴士（可选）", text: $steps[index].tips)
                            Divider()
                        }
                    }
                    Button("添加步骤") {
                        steps.append(StepInput(stepNumber: steps.count + 1))
                    }
                }
                
                Section(header: Text("营养成分")) {
                    TextField("热量（卡路里）", text: $nutrition.calories)
                        .keyboardType(.decimalPad)
                    TextField("蛋白质（克）", text: $nutrition.protein)
                        .keyboardType(.decimalPad)
                    TextField("碳水化合物（克）", text: $nutrition.carbs)
                        .keyboardType(.decimalPad)
                    TextField("脂肪（克）", text: $nutrition.fat)
                        .keyboardType(.decimalPad)
                    TextField("膳食纤维（克，可选）", text: $nutrition.fiber)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("创建菜谱")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await saveRecipe()
                        }
                    }
                    .disabled(isLoading || !isValid)
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty &&
        !ingredients.filter { !$0.name.isEmpty && !$0.amount.isEmpty }.isEmpty &&
        !steps.filter { !$0.description.isEmpty }.isEmpty &&
        !cookingTime.isEmpty &&
        !nutrition.calories.isEmpty &&
        !nutrition.protein.isEmpty &&
        !nutrition.carbs.isEmpty &&
        !nutrition.fat.isEmpty
    }
    
    private func saveRecipe() async {
        isLoading = true
        defer { isLoading = false }
        
        let recipeIngredients = ingredients
            .filter { !$0.name.isEmpty && !$0.amount.isEmpty }
            .map { Ingredient(name: $0.name, amount: $0.amount, unit: $0.unit.isEmpty ? nil : $0.unit) }
        
        let recipeSteps = steps
            .filter { !$0.description.isEmpty }
            .enumerated()
            .map { index, step in
                Step(
                    stepNumber: index + 1,
                    description: step.description,
                    image: nil,
                    tips: step.tips.isEmpty ? nil : step.tips
                )
            }
        
        let recipeNutrition = Nutrition(
            calories: Float(nutrition.calories) ?? 0,
            protein: Float(nutrition.protein) ?? 0,
            carbs: Float(nutrition.carbs) ?? 0,
            fat: Float(nutrition.fat) ?? 0,
            fiber: Float(nutrition.fiber),
            vitamins: nil
        )
        
        do {
            let recipe = FoodJourneyModels.RecipeCreate(
                title: title,
                ingredients: recipeIngredients,
                steps: recipeSteps,
                nutrition: recipeNutrition,
                cooking_time: Int(cookingTime) ?? 0,
                difficulty: difficulty,
                tags: tags.isEmpty ? nil : tags
            )
            
            try await recipeService.createRecipe(recipe)
            isPresented = false
        } catch {
            showingError = true
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CreateRecipeView(isPresented: .constant(true))
}
