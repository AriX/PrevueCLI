//
//  XMLParsing.swift
//  PrevuePackage
//
//  Created by Ari on 9/16/23.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation
#if os(Windows) || os(Linux)
import FoundationXML
#endif
import SwiftXMLParser
import SwiftXMLInterfaces
import Progress

protocol AbstractXMLParserDelegate: AnyObject {
    func parser(didStartElement elementName: String, attributes: [String: String])
    func parser(foundCharacters string: String)
    func parser(didEndElement elementName: String)
}

protocol AbstractXMLParser {
    init(data: Data)
    var delegate: AbstractXMLParserDelegate? { get set }
    func parse() throws
}

// MARK: Open source XML parser

class OpenSourceXMLParser: XDefaultEventHandler, AbstractXMLParser {
    let parser = XParser()
    let data: Data
    weak var delegate: AbstractXMLParserDelegate?
    
    required init(data: Data) {
        self.data = data
    }
    
    func parse() throws {
        // This parser is a bit slow, so let's keep the user updated with a progress bar
        var bar = ProgressBar(count: data.count, configuration: [ProgressPercent(), ProgressBarLine(), ProgressTimeEstimates()])
        
        let queue = DispatchQueue(label: "com.prevueguide.xmlparser.progress")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler { 
            bar.setValue(self.currentProgress)
        }
        timer.resume()
        
        try parser.parse(fromData: data, eventHandlers: [self])
        
        timer.cancel()
        bar.setValue(data.count) // Set progress to 100% complete
    }
    
    var currentProgress: Int = 0
    
    override func elementStart(name: String, attributes: [String: String?]?, textRange: XTextRange?, dataRange: XDataRange?) {
        if let dataRange {
            currentProgress = dataRange.binaryUntil
        }
        let attributes = (attributes ?? [:]).compactMapValues { $0 }
        delegate?.parser(didStartElement: name, attributes: attributes)
    }
    
    override func elementEnd(name: String, textRange: XTextRange?, dataRange: XDataRange?) {
        if let dataRange {
            currentProgress = dataRange.binaryUntil
        }
        delegate?.parser(didEndElement: name)
    }
    
    override func text(text: String, whitespace: WhitespaceIndicator, textRange: XTextRange?, dataRange: XDataRange?) {
        if let dataRange {
            currentProgress = dataRange.binaryUntil
        }
        delegate?.parser(foundCharacters: text)
    }
}

// MARK: Foundation XML parser

class FoundationXMLParser: NSObject, AbstractXMLParser {
    let parser: XMLParser
    weak var delegate: AbstractXMLParserDelegate?
    
    required init(data: Data) {
        self.parser = XMLParser(data: data)
    }
    
    func parse() throws {
        parser.delegate = self
        guard parser.parse() else {
            if let parserError = parser.parserError {
                throw parserError
            } else {
                throw NSError(domain: XMLParser.errorDomain, code: XMLParser.ErrorCode.internalError.rawValue)
            }
        }
    }
}

extension FoundationXMLParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes: [String: String] = [:]) {
        delegate?.parser(didStartElement: elementName, attributes: attributes)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        delegate?.parser(didEndElement: elementName)
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        delegate?.parser(foundCharacters: string)
    }
}
