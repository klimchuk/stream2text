//
//  Parser.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import Foundation

protocol Parser {
    associatedtype Input
    associatedtype Output

    func parse(input: Input) -> Output
}

extension Parser {
    func eraseToAnyParser() -> AnyParser<Input, Output> {
        AnyParser(self)
    }
}

struct AnyParser<Input, Output>: Parser {
    private let _parse: (Input) -> Output

    init<P: Parser>(_ parser: P) where P.Input == Input, P.Output == Output {
        _parse = parser.parse(input:)
    }

    func parse(input: Input) -> Output {
        _parse(input)
    }
}
