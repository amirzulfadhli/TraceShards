import std/[os, strutils, times, enumerate]

type
    LogEntry* = object
        timestamp*: string
        level*: string
        message*: string

    RejectedLine* = object
        lineNumber*: int
        raw*: string
        reason*: string

    ParseReport* = object  
        entries*: seq[LogEntry]
        rejected*:  seq[RejectedLine]

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
    
    let timestamp = parts[0] & " " & parts[1]

    try:
        discard parse(timestamp, "yyyy-MM-dd HH:mm:ss")
    except TimeParseError:
        return

    result.timestamp = timestamp   

    result.level = extractLevel(line)

    if result.level == "UNKNOWN":
        let messageParts = line.splitWhitespace(maxsplit = 2)
        result.message = messageParts[2]
    else:
        let messageParts = line.splitWhitespace(maxsplit = 3)

        if messageParts.len > 3:
            result.message = messageParts[3]

proc parseLogFile*(filePath: string): seq[LogEntry] =
    result = @[]

    for line in lines(filePath):
        if line.strip().len > 0:
            let entry = parseLogLine(line)

            if entry.timestamp.len > 0:
                result.add(entry)

proc parseLogFileWithDiagnostics*(filePath: string): ParseReport =
    result.entries = @[]
    result.rejected = @[]

    for lineNumber, line in enumerate(1, lines(filePath)):
        if line.strip().len == 0:
            continue

        let entry = parseLogLine(line)

        if entry.timestamp.len > 0:
            result.entries.add(entry)
        else:
            let reason =
                if line.splitWhitespace().len < 3:
                    "Incomplete log entry"
                else:
                    "Invalid timestamp"

            result.rejected.add(
                RejectedLine(
                    lineNumber: lineNumber,
                    raw: line,
                    reason: reason
                )
            )

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

