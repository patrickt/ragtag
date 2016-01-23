#!/usr/bin/swift

//  main.swift
//  ragtag
//
//  Created by Patrick Thomson on 1/23/16.
//  Copyright © 2016 Patrick Thomson. All rights reserved.
//

import Foundation
import ScriptingBridge

func usage() {
    print("usage: ragtag [commands]")
    print("valid commands:\n")
    print("[--tag, -t] NAME - target a given tag (default: track name)")
    print("[--strip, -s] - strip whitespace from targeted tag")
    print("[--replace, -r] PATT TMPL - regex search and replace")
    print("[--renumber, -e] - renumbers (1..n) the current selection")
    print("[-h, --help] - show this help")
    print("[-v, --verbose] - log verbosely")
    
}

enum Command {
    case Strip
    case Replace(NSRegularExpression, String?)
    case Tag(String)
    case Filter(NSRegularExpression)
    // case SentenceCapitalize (out of scope for now)
    // case Delete (can't be implemented, possibly swift limitation)
    case Help
    case Verbose
    case DryRun
    case Renumber
}

enum CommandParsingError : ErrorType {
    case UnrecognizedCommand(String)
    case InvalidRegex
}

func parseRegex(pattern: String) throws -> NSRegularExpression {
    return try NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions())
}

func parseTemplate(input : String?) -> String? {
    return input;
}

struct State {
    static let iTunes = SBApplication(bundleIdentifier: "com.apple.iTunes")!;
    var shouldActually = true
    var toTarget = "name"
    var verbose = false
    
    init() {
        if !State.iTunes.running {
            print("iTunes is not running. Nothing to do.");
            exit(EXIT_SUCCESS);
        }
    }
    
    func log(msg:String) {
        if (self.verbose) {
            print(msg)
        }
    }
}

func commandAlgebra(state:State, cmd:Command) -> State {
    var newState = state;
    let tracks = (State.iTunes.valueForKey("selection") as! SBObject).get() as! [SBObject]
    
    switch cmd {
    case .DryRun:
        newState.shouldActually = false;
    case .Help:
        usage();
        exit(EXIT_SUCCESS)
    case .Verbose:
        newState.verbose = true
    case .Tag(let str):
        newState.toTarget = str
    case .Renumber:
        var ii = 1
        for track in tracks {
            track.setValue(ii, forKey: "trackNumber")
            ii += 1
        }
    case .Replace(let regex, let mReplace):
        for track in tracks {
            let orig = track.valueForKey(newState.toTarget) as! String
            let replaced = regex.stringByReplacingMatchesInString(orig,
                                                                  options: NSMatchingOptions(),
                                                                  range: NSRange(location:0, length:orig.utf8.count),
                                                                  withTemplate: mReplace ?? "")
            state.log("Old: \(orig)")
            state.log("New: \(replaced)")
            if state.shouldActually {
                state.log("abstaining")
                track.setValue(replaced, forKey: newState.toTarget)
            }
        }
    default:
        state.log("Doing nothing with \(cmd)")
    }
    return newState;
}

func processCommands() throws -> [Command] {
    var args = ArraySlice(Process.arguments).dropFirst()
    var result : [Command] = Array()
    
    while !args.isEmpty {
        
        let arg = args.first!
        switch args.first! {
        case "--help", "-h":
            return [.Help]
        case "--verbose", "-v":
            result.append(.Verbose)
            args = args.dropFirst()
        case "--dry-run", "-n":
            result.append(.DryRun)
            args = args.dropFirst()
        case "--strip", "-s":
            result.append(.Strip)
            args = args.dropFirst()
        case "--replace", "-r":
            result.append(.Replace(
                try parseRegex(args[1 + args.startIndex]),
                parseTemplate(args[2 + args.startIndex])))
            args = args.dropFirst(3)
        case "--tag", "-t":
            result.append(.Tag(args[1]))
            args = args.dropFirst(2)
        case "--renumber", "-e":
            result.append(.Renumber)
            args = args.dropFirst()
//        case "--capitalize", "-c":
//            result.append(.Capitalize)
//            args = args.dropFirst()
        default:
            throw CommandParsingError.UnrecognizedCommand(arg)
        }
    }
    
    return result
}


let commands = try processCommands()
print(commands)

let state = State()
commands.reduce(state, combine:commandAlgebra)

