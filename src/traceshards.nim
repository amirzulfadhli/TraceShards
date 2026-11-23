import std/[os, strutils]

type
    LogEntry* = object
        timestamp*: string
        level*: string
        message*: string

proc countNonemptyLines*(filePath: string): int =
    for line in lines(filePath):
        if line.strip().len > 0:
            inc result

proc extractLevel*(line: string): string =
    let parts = line.splitWhitespace()

    if parts.len < 3:
        return "UNKNOWN"

    let level = parts[2].toUpperAscii()

    case level
    of "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL":
        result = level
    else:
        result = "UNKNOWN"

proc parseLogLine*(line: string): LogEntry =
    let parts = line.splitWhitespace()

    if parts.len < 3:
        return
    
    result.timestamp = parts[0] & " " & parts[1]
    result.level = extractLevel(line)

    if result.level == "UNKNOWN":
        result.message = parts[2..^1].join(" ")
    else:
        result.message = parts[3..^1].join(" ")

proc main() =
    if paramCount() != 1:
        echo "Usage: traceshards <log.files>"
        quit(1)

    let filePath = paramStr(1)

    if not fileExists(filePath):
        echo "Error: File not found: ", filePath
        quit(1)

    let count = countNonEmptyLines(filePath)
    echo "Total non empty lines: ", count

when isMainModule:
    main()

