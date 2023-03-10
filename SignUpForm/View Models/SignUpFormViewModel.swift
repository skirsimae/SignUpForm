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
    typealias Available = Result<Bool, Error>
    
    // MARK: Input
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var passwordConfirmation: String = ""
    
    // MARK: Output
    @Published var usernameMessage: String = ""
    @Published var passwordMessage: String = ""
    @Published var isValid: Bool = false
    @Published var showUpdateDialog: Bool = false
    
    private lazy var isUsernameLengthValidPublisher: AnyPublisher<Bool, Never> = {
        $username
            .map { $0.count >= 3 }
            .eraseToAnyPublisher()
    }()
    
    private lazy var isUsernameAvailablePublisher: AnyPublisher<Available, Never> = {
        $username
            .debounce(for: 0.8, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .flatMap { username -> AnyPublisher<Available, Never> in
                self.authenticationService.checkUsernameAvailable(username: username)
                    .asResult()
            }
            .receive(on: DispatchQueue.main)
            .share()
            .eraseToAnyPublisher()
    }()
    
    private lazy var isUsernameValidPublisher: AnyPublisher<UsernameValid, Never> = {
        Publishers.CombineLatest(isUsernameLengthValidPublisher, isUsernameAvailablePublisher)
            .map { longEnough, available in
                if !longEnough {
                    return .tooShort
                }
                
                let availabilityResult = available.map{ $0 }
                
                switch availabilityResult {
                case .failure(let error):
                    if case APIError.transportError(_) = error {
                        return .valid
                    } else {
                        return .notAvailable
                    }
                case .success(let isAvailable):
                    if isAvailable {
                        return .valid
                    }
                }
                return .valid
            }
            .share()
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
    
    private lazy var passwordStrengthPublisher: AnyPublisher<PasswordStrength, Never> = {
        $password
            .map(Navajo.strength(ofPassword:))
            .eraseToAnyPublisher()
    }()
    
    private lazy var isPasswordStrongPublisher: AnyPublisher<Bool, Never> = {
        passwordStrengthPublisher
            .map { passwordStrength in
                switch passwordStrength {
                case .veryWeak, .weak:
                    return false
                case .reasonable, .strong, .veryStrong:
                    return true
                }
            }
            .eraseToAnyPublisher()
    }()
    
    private lazy var isPasswordValidPublisher: AnyPublisher<Bool, Never> = {
        Publishers.CombineLatest4(isPasswordEmptyPublisher, isPasswordLengthValidPublisher, isPasswordStrongPublisher, isPasswordMatchingPublisher)
            .map { !$0 && $1 && $2 && $3 }
            .eraseToAnyPublisher()
    }()
    
    private lazy var isFormValidPublisher: AnyPublisher<Bool, Never> = {
        Publishers.CombineLatest(isUsernameValidPublisher, isPasswordValidPublisher)
            .map { $0 == .valid && $1 }
            .eraseToAnyPublisher()
    }()
    
    init() {
        isUsernameAvailablePublisher
            .map { result in
                switch result {
                case .failure(let error):
                    if case APIError.transportError(_) = error {
                        return ""
                    } else if case APIError.validationError(let reason) = error {
                        return reason
                    } else if case APIError.serverError(statusCode: _, reason: let reason, retryAfter: _) = error {
                        return reason ?? "Server error"
                    }
                    else {
                        return error.localizedDescription
                    }
                case .success(let isAvailable):
                    return isAvailable ? "" : "This username is not available"
                }
            }
            .assign(to: &$usernameMessage)
        
        isUsernameAvailablePublisher
            .map { result in
                if case .failure(let error) = result {
                    if case APIError.decodingError = error {
                        return true
                    }
                }
                return false
            }
            .assign(to: &$showUpdateDialog)
        
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

extension Publisher {
    func asResult() ->
    AnyPublisher<Result<Output, Failure>, Never>
    {
        self
            .map(Result.success)
            .catch { error in
                Just(.failure(error))
            }
            .eraseToAnyPublisher()
    }
}
