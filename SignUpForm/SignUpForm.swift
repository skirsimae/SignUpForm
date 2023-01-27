//
//  ContentView.swift
//  SignUpForm
//
//  Created by Silva Kirsimae on 23/01/2023.
//

import SwiftUI
import Combine
import Navajo_Swift

// MARK: - View Model
class SignUpFormViewModel: ObservableObject {
    
    // MARK: Input
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var passwordConfirmation: String = ""
    @Published var passwordStrength: PasswordStrength = .veryWeak
    
    // MARK: Output
    @Published var usernameMessage: String = ""
    @Published var passwordMessage: String = ""
    @Published var isValid: Bool = false
    
    private lazy var isUsernameLengthValidPublisher: AnyPublisher<Bool, Never> = {
        $username
            .map { $0.count >= 3 }
            .eraseToAnyPublisher()
    }()
    
    private lazy var isPasswordEmptyPublisher: AnyPublisher<Bool, Never> = {
        $password
            .map(\.isEmpty)
            .eraseToAnyPublisher()
    }()
    
    private lazy var isPasswordLengthValidPublisher: AnyPublisher<Bool, Never> = {
        $password
            .map{ $0.count >= 8 }
            .eraseToAnyPublisher()
    }()
    
    private lazy var isPasswordMatchingPublisher: AnyPublisher<Bool, Never> = {
        Publishers.CombineLatest($password, $passwordConfirmation)
            .map(==)
            .eraseToAnyPublisher()
    }()
    
    private lazy var isPasswordStrongPublisher: AnyPublisher<Bool, Never> = {
        $passwordStrength
            .map{ $0 == .reasonable || $0 == .strong || $0 == .veryStrong }
            .eraseToAnyPublisher()
    }()
    
    private lazy var isPasswordValidPublisher: AnyPublisher<Bool, Never> = {
        Publishers.CombineLatest4(isPasswordEmptyPublisher, isPasswordLengthValidPublisher, isPasswordStrongPublisher, isPasswordMatchingPublisher)
            .map { !$0 && $1 && $2 && $3 }
            .eraseToAnyPublisher()
    }()
    
    private lazy var isFormValidPublisher: AnyPublisher<Bool, Never> = {
        Publishers.CombineLatest(isUsernameLengthValidPublisher, isPasswordValidPublisher)
            .map { $0 && $1 }
            .eraseToAnyPublisher()
    }()
    
    init() {
        passwordStrength = Navajo.strength(ofPassword: password)
        
        isFormValidPublisher
            .assign(to: &$isValid)
        isUsernameLengthValidPublisher
            .map { $0 ? "" : "Username too short. Needs to be at least 3 characters." }
            .assign(to: &$usernameMessage)
        
        Publishers.CombineLatest4(isPasswordEmptyPublisher, isPasswordLengthValidPublisher, isPasswordStrongPublisher,  isPasswordMatchingPublisher)
            .map { isPasswordEmpty, isPasswordLengthValid ,isPasswordStrong, isPasswordMatching in
                if isPasswordEmpty {
                    return "Password must not be empty"
                }
                else if !isPasswordLengthValid {
                    return "Password must be longer than 7 characters"
                } else if !isPasswordStrong {
                    return "Password is too weak"
                }
                else if !isPasswordMatching {
                    return "Passwords do not match"
                }
                return ""
            }
            .assign(to: &$passwordMessage)
    }
}

// MARK: - View
struct SignUpForm: View {
    @StateObject var viewModel = SignUpFormViewModel()
    
    var body: some View {
        Form {
            // Username
            Section {
                TextField("Username", text: $viewModel.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } footer: {
                Text(viewModel.usernameMessage)
                    .foregroundColor(.red)
            }
            
            // Password
            Section {
                SecureField("Password", text: $viewModel.password)
                SecureField("Repeat password", text: $viewModel.passwordConfirmation)
            } footer: {
                Text(viewModel.passwordMessage)
                    .foregroundColor(.red)
            }
            
            // Submit button
            Section {
                Button("Sign up") {
                    print("Signing up as \(viewModel.username)")
                }
                .disabled(!viewModel.isValid)
            }
        }
    }
}

// MARK: - Preview
struct SignUpForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignUpForm()
                .navigationTitle("Sign up")
        }
    }
}
