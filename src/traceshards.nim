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

    let isIso = parts.len > 0 and
        parts[0].contains('T')

    let levelIndex =
        if isIso:
            1
        else:
            2

    if parts.len <= levelIndex:
        return "UNKNOWN"

    let level = parts[levelIndex].toUpperAscii()

    case level
    of "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL":
        result = level
    else:
        result = "UNKNOWN"

proc parseLogLine*(line: string): LogEntry =
    let parts = line.splitWhitespace()
    let isIso = parts.len > 0 and
        parts[0].contains('T')

    let minParts =
        if isIso:
            2
        else:
            3
        
    if parts.len < minParts:
        return

    let timestamp =
        if isIso:
            parts[0]
        else:
            parts[0] & " " & parts[1]

    try:
        if isIso:
            if timestamp.contains('.'):
                discard parse(timestamp, "yyyy-MM-dd'T'HH:mm:ss.fffzzz", utc())
            else:
                discard parse(timestamp, "yyyy-MM-dd'T'HH:mm:sszzz", utc())

            if not timestamp.endsWith("Z"):
                let offsetHours = parseInt(timestamp[^5 .. ^ 4])
                let offsetMinutes = parseInt(timestamp[^2 .. ^1])

                if offsetHours >= 24 or offsetMinutes >= 60:
                    return
        else:
            discard parse(timestamp, "yyyy-MM-dd HH:mm:ss")
    except TimeParseError, ValueError:
        return

    result.timestamp = timestamp

    result.level = extractLevel(line)

    var messageStart =
        if isIso:
            1
        else:
            2

    if result.level != "UNKNOWN":
        inc messageStart

    let messageParts = line.splitWhitespace(maxsplit = messageStart)

    if messageParts.len > messageStart:
        result.message = messageParts[messageStart]

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

proc filterEntriesByLevel*(entries: seq[LogEntry], level: string): seq[LogEntry] = 
    let targetLevel = level.toUpperAscii()

    for entry in entries:
        if entry.level == targetLevel:
            result.add(entry)

proc countEntriesByLevel*(entries: seq[LogEntry], level: string): int =
    let targetLevel = level.toUpperAscii()
    
    for entry in entries:
        if entry.level == targetLevel:
            inc result

proc searchEntriesByMessage*(entries: seq[LogEntry], keyword: string): seq[LogEntry] = 
    let targetKeyword = keyword.toLowerAscii()

    for entry in entries:
        if entry.message.toLowerAscii().contains(targetKeyword):
            result.add(entry)

proc main() =
    if paramCount() < 1 or paramCount() > 3:
        echo "Usage: tracesgards <log-file> [severity] [keyword]"
        quit(1)

    let filePath = paramStr(1)

    if not fileExists(filePath):
        echo "Error: File not found: ", filePath
        quit(1)

    let selectedLevel = 
        if paramCount() == 2:
            paramStr(2).toUpperAscii()
        else:
            "ERROR"

    if selectedLevel notin ["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "UNKNOWN"]:
        echo "Error: Unsupported severity level: ", selectedLevel
        echo "Valid levels: TRACE, DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN"
        quit(1)

    let count = countNonEmptyLines(filePath)
    echo "Total non empty lines: ", count

    let report = parseLogFileWithDiagnostics(filePath)
    echo "Valid entries: ", report.entries.len
    echo "Rejected entries: ", report.rejected.len
    for level in ["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "UNKNOWN"]:
        echo level, " entries: ", countEntriesByLevel(report.entries, level)

    for rejected in report.rejected:
        echo "Line ", rejected.lineNumber, " rejected: ", rejected.reason
        echo " Original: ", rejected.raw

    var matches = filterEntriesByLevel(report.entries, selectedLevel)

    if paramCount() == 3:
        let keyword = paramStr(3)
        matches = searchEntriesByMessage(matches, keyword)

    echo "Matching events: ", matches.len
    echo selectedLevel, " events:"

    if matches.len == 0:
        echo " No matching event found"
    else:
        for entry in matches:
            echo "  ", entry.timestamp, " | ", entry.message

when isMainModule:
    main()

