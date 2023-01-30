//
//  SignUpFormViewModel.swift
//  SignUpForm
//
//  Created by Silva Kirsimae on 30/01/2023.
//

import Combine
import Navajo_Swift

class SignUpFormViewModel: ObservableObject {
    
    private var authenticationService = AuthenticationService()
    
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
    
    private lazy var isUsernameAvailablePublisher: AnyPublisher<Bool, Never> = {
      $username
        .flatMap { username in
            self.authenticationService.checkUsernameAvailable(username: username)
        }
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
        
        isUsernameAvailablePublisher
          .assign(to: &$isValid)
        isUsernameAvailablePublisher
          .map {
            $0 ? ""
               : "Username not available. Try a different one."
          }
          .assign(to: &$usernameMessage)
        
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
