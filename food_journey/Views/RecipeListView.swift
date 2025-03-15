import SwiftUI

struct RecipeListView: View {
    @StateObject private var recipeService = RecipeService.shared
    @State private var searchText = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showingCreateRecipe = false
    @State private var selectedCategories: Set<String> = []
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            mainContentView
                .navigationTitle("美食食谱")
                .searchable(text: $searchText, prompt: "搜索食谱")
                .onChange(of: searchText) { oldValue, newValue in
                    Task {
                        await searchRecipes(query: newValue)
                    }
                }
                .onChange(of: selectedCategories) { oldValue, newValue in
                    recipeService.filterRecipes(by: newValue)
                }
                .refreshable {
                    await loadRecipes()
                }
                .alert("错误", isPresented: $showingError) {
                    Button("确定", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingCreateRecipe = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingCreateRecipe) {
                    CreateRecipeView(isPresented: $showingCreateRecipe)
                }
        }
        .task {
            await loadRecipes()
        }
    }
    
    private var mainContentView: some View {
        ScrollView {
            if isLoading {
                loadingView
            } else if recipeService.filteredRecipes.isEmpty {
                emptyStateView
            } else {
                recipeGridView
            }
        }
    }
    
    private var loadingView: some View {
        ProgressView()
            .padding()
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text("未获取到菜谱")
                .foregroundColor(.secondary)
                .padding()
            Spacer()
        }
    }
    
    private var recipeGridView: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(recipeService.filteredRecipes) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    RecipeCard(recipe: recipe)
                }
            }
        }
        .padding()
    }
    
    private func loadRecipes() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await recipeService.fetchRecipes()
        } catch {
            showingError = true
            errorMessage = error.localizedDescription
        }
    }
    
    private func searchRecipes(query: String) async {
        guard !query.isEmpty else {
            await loadRecipes()
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await recipeService.searchRecipes(query: query)
        } catch {
            showingError = true
            errorMessage = error.localizedDescription
        }
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading) {
            if let imageUrl = recipe.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(height: 150)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 150)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let difficulty = recipe.difficulty {
                    Label(difficulty, systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let cookingTime = recipe.cookingTime {
                    Label("\(cookingTime) 分钟", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

#Preview {
    RecipeListView()
}
