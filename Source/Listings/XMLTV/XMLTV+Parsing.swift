//
//  XMLTV+Parsing.swift
//  PrevuePackage
//
//  Created by Ari on 9/12/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation
#if os(Windows) || os(Linux)
import FoundationXML
#endif

extension XMLTV {
    init(xmlData: Data) throws {
        let calendar = Calendar.current
        let timeZone = TimeZone.tulsa
        let startOfToday = calendar.startOfListingsDay(for: .currentTulsaDate)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        let parser = XMLTVParser(fromDate: startOfToday, toDate: startOfTomorrow, timeZone: timeZone, maxChannelNumber: 100)
        
        let xmlParser = XMLParser(data: xmlData)
        let delegateStack = ParserDelegateStack(xmlParser: xmlParser)
        delegateStack.push(parser)
        
        guard xmlParser.parse(),
            let result = parser.result else {
                if let parserError = xmlParser.parserError {
                    throw parserError
                } else {
                    throw NSError(domain: XMLParser.errorDomain, code: XMLParser.ErrorCode.internalError.rawValue, userInfo: nil)
                }
        }
        
        print("Finished parsing \(result.channels.count) channels")
        
        self = result
    }
}

// MARK: Parsing

class XMLTVParser: NodeParser {
    var result: XMLTV?
    
    init(fromDate: Date, toDate: Date, timeZone: TimeZone, maxChannelNumber: Int) {
        channelsParser = ChannelsParser(maxChannelNumber: maxChannelNumber)
        programsParser = ProgramsParser(fromDate: fromDate, toDate: toDate, timeZone: timeZone, channelsParser: channelsParser)
        super.init(tagName: "tv")
    }
    
    override func didParseElement() {
        result = XMLTV(sourceInfoURL: attributes["source-info-url"],
                       sourceInfoName: attributes["source-info-name"],
                       generatorInfoName: attributes["generator-info-name"],
                       channels: channelsParser.channels)
    }
        
    let channelsParser: ChannelsParser
    let programsParser: ProgramsParser
    override var childParsers: [NodeParser] {
        return [channelsParser, programsParser]
    }
    
    class ChannelsParser: NodeParser {
        var channels: [String: XMLTV.Channel] = [:]
        
        let maxChannelNumber: Int
        let displayNamesParser = StringParser(tagName: "display-name")
        
        init(maxChannelNumber: Int) {
            self.maxChannelNumber = maxChannelNumber
            super.init(tagName: "channel")
        }
        
        override var childParsers: [NodeParser] {
            return [displayNamesParser]
        }
        
        override func didParseElement() {
            guard let channelIdentifier = attributes["id"] else { return }
            
            let channel = XMLTV.Channel(displayNames: displayNamesParser.strings, programs: [])
            if let channelNumber = channel.channelNumber,
                channelNumber <= maxChannelNumber {
                channels[channelIdentifier] = channel
            }
        }
    }

    class StringParser: NodeParser {
        var strings: [String] = []

        override var parsesContent: Bool { true }
        override func didParseElement() {
            guard let content = content else { return }
            strings += [content]
        }
        
        override func reset() {
            strings = []
        }
    }

    class AudioDetailsParser: NodeParser {
        var stereo: Bool?
        
        override func didParseElement() {
            guard let stereoString = stereoParser.strings.first else { return }
            stereo = (stereoString != "mono")
        }
        
        let stereoParser = StringParser(tagName: "stereo")
        override var childParsers: [NodeParser] {
            return [stereoParser]
        }
        
        override func reset() {
            stereo = nil
        }
    }

    class CreditsParser: NodeParser {
        var actors: [String] = []
        
        override func didParseElement() {
            actors = actorsParser.strings
        }
        
        let actorsParser = StringParser(tagName: "actor")
        override var childParsers: [NodeParser] {
            return [actorsParser]
        }
        
        override func reset() {
            actors = []
        }
    }

    class RatingsParser: NodeParser {
        var ratings: [XMLTV.Channel.Program.Rating] = []
        
        override func didParseElement() {
            if let ratingSystem = attributes["system"],
                let value = valueParser.strings.first {
                ratings += [XMLTV.Channel.Program.Rating(ratingSystem: ratingSystem, rating: value)]
            }
        }
        
        let valueParser = StringParser(tagName: "value")
        override var childParsers: [NodeParser] {
            return [valueParser]
        }
        
        override func reset() {
            ratings = []
        }
    }

    class ClosedCaptionsParser: NodeParser {
        var closedCaptions: Bool = false
        
        override func didParseElement() {
            closedCaptions = true
        }
        
        override func reset() {
            closedCaptions = false
        }
    }

    class ProgramsParser: NodeParser {
        let minDate: Date
        let maxDate: Date
        let timeZone: TimeZone
        let dateFormatter: DateFormatter
        
        init(fromDate: Date, toDate: Date, timeZone: TimeZone, channelsParser: ChannelsParser) {
            minDate = fromDate
            maxDate = toDate
            dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMddHHmmss Z"
            self.timeZone = timeZone
            
            self.channelsParser = channelsParser
            super.init(tagName: "programme")
        }
        
        override func didParseElement() {
            guard let channelIdentifier = attributes["channel"],
                channelsParser.channels[channelIdentifier] != nil,
                let start = attributes["start"],
                let startDate = dateFormatter.date(from: start)?.convertTimeZone(from: .current, to: timeZone),
                startDate > minDate,
                startDate < maxDate,
                let title = titleParser.strings.first else { return }
            
            var endDate: Date? = nil
            if let end = attributes["end"] {
                endDate = dateFormatter.date(from: end)?.convertTimeZone(from: .current, to: timeZone)
            }
            
            var duration: TimeInterval? = nil
            if let durationString = durationParser.strings.first,
                let durationInteger = Int(durationString) {
                duration = TimeInterval(durationInteger * 60)
            }
            
            let subtitle = subtitleParser.strings.first
            let description = descriptionParser.strings.first
            
            let program = XMLTV.Channel.Program(startDate: startDate, endDate: endDate, title: title, subtitle: subtitle, description: description, categories: categoriesParser.strings, actors: creditsParser.actors, year: yearParser.strings.first, duration: duration, stereo: audioDetailsParser.stereo, closedCaptioned: closedCaptionsParser.closedCaptions, ratings: ratingsParser.ratings)
            channelsParser.channels[channelIdentifier]?.programs += [program]
        }
        
        let channelsParser: ChannelsParser
        let titleParser = StringParser(tagName: "title")
        let subtitleParser = StringParser(tagName: "sub-title")
        let descriptionParser = StringParser(tagName: "desc")
        let categoriesParser = StringParser(tagName: "category")
        let audioDetailsParser = AudioDetailsParser(tagName: "audio")
        let closedCaptionsParser = ClosedCaptionsParser(tagName: "subtitles")
        let yearParser = StringParser(tagName: "date")
        let durationParser = StringParser(tagName: "length")
        let creditsParser = CreditsParser(tagName: "credits")
        let ratingsParser = RatingsParser(tagName: "rating")
        override var childParsers: [NodeParser] {
            return [titleParser, subtitleParser, descriptionParser, categoriesParser, audioDetailsParser, closedCaptionsParser, yearParser, durationParser, creditsParser, ratingsParser]
        }
    }
}

class NodeParser: NSObject {
    var attributes: [String: String] = [:]
    var content: String?
    var parsesContent: Bool { false }

    let tagName: String
    var delegateStack: ParserDelegateStack?
    var childParsers: [NodeParser] { [] }
    
    init(tagName: String) {
        self.tagName = tagName
    }
    
    func didParseElement() {
        // Implemented by subclasses
    }
    
    func reset() {
        // Implemented by subclasses
    }
}

extension NodeParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == tagName {
            attributes.merge(attributeDict) { $1 }
            return
        }
        
        for childParser in childParsers {
            if elementName == childParser.tagName {
                delegateStack?.push(childParser)
                childParser.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if parsesContent {
            let existingContent = content ?? ""
            content = (existingContent + string)
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == tagName {
            didParseElement()
            attributes = [:]
            content = nil
            
            for childParser in childParsers {
                childParser.reset()
            }
            
            delegateStack?.pop()
        }
    }
}

class ParserDelegateStack {
    private var parsers: [NodeParser] = []
    private let xmlParser: XMLParser

    init(xmlParser: XMLParser) {
        self.xmlParser = xmlParser
    }

    func push(_ parser: NodeParser) {
        parser.delegateStack = self
        xmlParser.delegate = parser
        parsers.append(parser)
    }

    func pop() {
        parsers.removeLast()
        if let next = parsers.last {
            xmlParser.delegate = next
        } else {
            xmlParser.delegate = nil
        }
    }
} 
