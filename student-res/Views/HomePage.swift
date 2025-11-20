//
//  HomePage.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 11/10/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct HomePage: View {
    @State var navigate: Bool = false
    @State var sem: String = ""
    @State private var animateGradient = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.3),
                        Color.purple.opacity(0.3),
                        Color.pink.opacity(0.2)
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
                VStack(spacing: 40) {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: .blue.opacity(0.4), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(animateGradient ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGradient)
                    
                    VStack(spacing: 12) {
                        Text("Welcome to")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("Student Resources")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    
                    Text("Your one-stop solution for\nnotes, question papers, and study materials")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    Button(action: {
                        navigate = true
                    }) {
                        HStack(spacing: 12) {
                            Text("Get Started")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
            .navigationDestination(isPresented: $navigate) {
                if sem == "" {
                    NextPage()
                } else {
                    MainHomePage()
                }
            }
            .onAppear {
                UserService.shared.getsemester { sem = $0 ?? "" }
            }
        }
    }
}

#Preview {
    HomePage()
}
