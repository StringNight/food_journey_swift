import SwiftUI

struct AboutView: View {
    let appVersion = "0.1.0"
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image("cat")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                    .padding(.top, 40)
                
                Text("Food Journey")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("版本 \(appVersion)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                    .padding(.horizontal, 30)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Food Journey 是您的个人饮食助手，帮助您记录和分析日常饮食习惯，提供健康建议，让您的饮食之旅更加愉快和有意义。")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("特色功能：")
                        .font(.headline)
                        .padding(.top)
                        .padding(.horizontal)
                    
                    FeatureRow(icon: "camera", text: "拍照识别食物")
                    FeatureRow(icon: "waveform", text: "语音交互")
                    FeatureRow(icon: "chart.bar", text: "饮食分析")
                    FeatureRow(icon: "person.text.rectangle", text: "个性化建议")
                }
                .padding()
                
                Spacer()
                
                Text("© 2025 InfSols. 保留所有权利。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationBarTitle("关于", displayMode: .inline)
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 25)
            Text(text)
                .font(.body)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}