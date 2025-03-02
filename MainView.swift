// ... existing code before AccountView Tab
                    NavigationView {
                        // 新增健身追踪功能：展示健康数据（身体数据、训练进度、饮食详情、恢复状态）
                        HealthTrackView()
                    }
                    .tabItem {
                        Label("健身", systemImage: "figure.walk")
                    }
// ... existing code after Recipe tab and before AccountView Tab 