import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @StateObject private var recipeService = RecipeService.shared
    @State private var showingRatingSheet = false
    @State private var rating: Int = 0
    @State private var comment: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isFavorite: Bool = false
    
    private let imageHeight: CGFloat = 300
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 使用子视图拆分复杂结构
                recipeHeaderView
                
                // 菜谱信息部分
                recipeInfoSection
                
                // 食材部分
                ingredientsSection
                
                // 步骤部分
                stepsSection
                
                // 营养信息
                nutritionSection
                
                // 评论部分
                ratingsSection
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    toggleFavorite()
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .gray)
                }
            }
        }
        .onAppear {
            checkFavoriteStatus()
        }
        .sheet(isPresented: $showingRatingSheet) {
            ratingSheetView
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // 食谱头部视图(图片)
    private var recipeHeaderView: some View {
        Group {
            if let imageUrl = recipe.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: imageHeight)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: imageHeight)
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: imageHeight)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
            }
        }
    }
    
    // 菜谱信息部分
    private var recipeInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("食谱信息")
                .font(.headline)
            
            HStack {
                if let difficulty = recipe.difficulty {
                    Label(difficulty, systemImage: "star.fill")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let cookingTime = recipe.cookingTime {
                    Label("\(cookingTime) 分钟", systemImage: "clock.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            if let tags = recipe.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(UIColor.systemBlue).opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            Divider()
        }
    }
    
    // 食材部分
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("食材")
                .font(.headline)
            
            ForEach(recipe.ingredients) { ingredient in
                HStack {
                    Text("•")
                    Text(ingredient.name)
                    Spacer()
                    Text("\(ingredient.amount) \(ingredient.unit ?? "")")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Divider()
        }
    }
    
    // 步骤部分
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("步骤")
                .font(.headline)
            
            ForEach(recipe.steps) { step in
                VStack(alignment: .leading, spacing: 4) {
                    Text("步骤 \(step.stepNumber)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(step.description)
                        .padding(.vertical, 4)
                    
                    if let tips = step.tips, !tips.isEmpty {
                        Text("小贴士: \(tips)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Divider()
        }
    }
    
    // 营养信息
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("营养信息")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                nutritionRow(title: "热量", value: "\(recipe.nutrition.calories) kcal")
                nutritionRow(title: "蛋白质", value: "\(recipe.nutrition.protein) g")
                nutritionRow(title: "碳水化合物", value: "\(recipe.nutrition.carbs) g")
                nutritionRow(title: "脂肪", value: "\(recipe.nutrition.fat) g")
                if let fiber = recipe.nutrition.fiber {
                    nutritionRow(title: "纤维", value: "\(fiber) g")
                }
            }
            
            Divider()
        }
    }
    
    // 营养信息行
    private func nutritionRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
        }
    }
    
    // 评论部分
    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("评论")
                    .font(.headline)
                
                Spacer()
                
                Button("添加评价") {
                    showingRatingSheet = true
                }
                .buttonStyle(.bordered)
            }
            
            if let ratings = recipe.ratings, !ratings.isEmpty {
                ForEach(ratings) { rating in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            // 显示评分
                            ForEach(1..<6, id: \.self) { star in
                                Image(systemName: star <= rating.rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                            
                            Spacer()
                            
                            Text(formatDate(rating.createdAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let comment = rating.comment, !comment.isEmpty {
                            Text(comment)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            } else {
                Text("暂无评价")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
        }
    }
    
    // 评分表单视图
    private var ratingSheetView: some View {
        VStack(spacing: 20) {
            Text("为这个食谱评分")
                .font(.headline)
            
            HStack {
                ForEach(1..<6, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.title)
                        .onTapGesture {
                            rating = star
                        }
                }
            }
            
            TextField("评论 (可选)", text: $comment)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("取消") {
                    showingRatingSheet = false
                }
                .buttonStyle(.bordered)
                
                Button("提交") {
                    Task {
                        await submitRating()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(rating == 0)
            }
            .padding()
        }
        .padding()
    }
    
    private func toggleFavorite() {
        Task {
            do {
                if isFavorite {
                    try await recipeService.removeFromFavorites(recipeId: recipe.id)
                } else {
                    try await recipeService.addToFavorites(recipeId: recipe.id)
                }
                isFavorite.toggle()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func submitRating() async {
        do {
            try await recipeService.rateRecipe(recipeId: recipe.id, rating: rating, comment: comment.isEmpty ? nil : comment)
            showingRatingSheet = false
            rating = 0
            comment = ""
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    private func checkFavoriteStatus() {
        isFavorite = recipeService.favoriteRecipes.contains { $0.id == recipe.id }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 