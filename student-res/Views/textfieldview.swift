//
//  textfriledview.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 11/10/25.
//

import Foundation
import SwiftUI

struct textfieldview: View {
    @Binding var data2: String
    var data: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField(data, text: $data2)
            .focused($isFocused)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct securefieldview: View {
    @Binding var data2: String
    var data: String
    @FocusState private var isFocused: Bool
    @State private var showPassword = false
    
    var body: some View {
        HStack {
            if showPassword {
                TextField(data, text: $data2)
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                SecureField(data, text: $data2)
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            
            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

