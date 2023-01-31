//
//  Service.swift
//  SignUpForm
//
//  Created by Silva Kirsimae on 30/01/2023.
//

import Foundation
import Combine

enum APIError: LocalizedError {
    case invalidRequestError(String)
    case transportError(Error)
}

class AuthenticationService {
    func checkUsernameAvailable(username: String) -> AnyPublisher<Bool, Error> {
        guard let url = URL(string: "http://127.0.0.1:8080/isUserNameAvailable?userName=\(username)") else {
            return Fail(error: APIError.invalidRequestError("URL invalid"))
                .eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { error -> Error in
              return APIError.transportError(error)
            }
            .map( \.data)
            .decode(type: UserNameAvailableMessage.self, decoder: JSONDecoder())
            .map(\.isAvailable)
            .eraseToAnyPublisher()
    }
}
