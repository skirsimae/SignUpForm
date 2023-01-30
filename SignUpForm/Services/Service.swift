//
//  Service.swift
//  SignUpForm
//
//  Created by Silva Kirsimae on 30/01/2023.
//

import Foundation
import Combine

class Service {
    func checkUsernameAvailableNaive(username: String) -> AnyPublisher<Bool, Never> {
        guard let url = URL(string: "http://127.0.0.1:8080/isUserNameAvailable?userName=\(username)") else {
            return Just(false).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response in
                do {
                    let decoder = JSONDecoder()
                    let userAvailableMessage = try decoder.decode(UsernameAvailableMessage.self, from: data)
                    return userAvailableMessage.isAvailable
                } catch {
                    return false
                }
            }
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }
}
