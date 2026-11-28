import std/[os, strutils, times, enumerate, algorithm, math]

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

proc parseTimestampTime(timestamp: string): Time =
    let timestampFormat = 
        if not timestamp.contains('T'):
            "yyyy-MM-dd HH:mm:ss"
        elif timestamp.contains('.'):
            "yyyy-MM-dd'T'HH:mm:ss.fffzzz"
        else:
            "yyyy-MM-dd'T'HH:mm:sszzz"

    result = parseTime(timestamp, timestampFormat, utc())

proc sortEntriesChronologically*(entries: seq[LogEntry]): seq[LogEntry] =
    for entry in entries:
        result.add(entry)

    result.sort(proc(a, b: LogEntry): int =
        let timeA = parseTimestampTime(a.timestamp)
        let timeB = parseTimestampTime(b.timestamp)

        if timeA < timeB:
            return -1
        elif timeA > timeB:
            return 1
        else:
            return 0
    )

proc calculateTimeGap*(first, second: LogEntry): float =
    let firstTime = parseTimestampTime(first.timestamp)
    let secondTime = parseTimestampTime(second.timestamp)

    let duration = secondTime - firstTime

    result = duration.inMilliseconds.float / 1000.0

proc isGapAboveThreshold*(first, second: LogEntry, threshold: float): bool =
    let gap = calculateTimeGap(first, second)

    result = gap > threshold

type    
    CliOptions* = object
        filePath*: string
        severity*: string
        keyword*: string
        hasGapOtion*: bool
        gapThreshold*: float

proc parseCliArguments*(args: seq[string]): CliOptions = 
    if args.len == 0:
        raise newException(ValueError, "Missing log filename")

    var gapCount = 0

    for arg in args:
        if arg == "--gap":
            inc gapCount
    
    if gapCount > 1:
        raise newException(ValueError, "Duplicate --gap option")

    if args[args.len - 1] == "--gap":
        raise newException(ValueError, "Missing value for --gap")

    result.filePath = args[0]

    if result.filePath.strip().len == 0:
        raise newException(ValueError, "Log filename cannot be blank")

    result.severity = "ERROR"

    if args.len >= 2 and args[1] != "--gap":
        result.severity = args[1].toUpperAscii()

    if result.severity notin [
        "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "UNKNOWN"
    ]:
        raise newException(
            ValueError,
            "Unsupported severity level: " & result.severity
        )

    if args.len >= 3 and args[args.len - 2] == "--gap":
        result.hasGapOtion = true
        result.gapThreshold = parseFloat(args[args.len - 1])

        if result.gapThreshold != result.gapThreshold:
            raise newException(ValueError, "Gap threshold cannot be NaN")

        if result.gapThreshold < 0.0:
            raise newException(ValueError, "Gap threshold cannot be negative")

        if classify(result.gapThreshold) in {fcInf, fcNegInf}:
            raise newException(ValueError, "Gap threshold cannot be infinite")

    let positionalCount = 
        if result.hasGapOtion:
            args.len - 2
        else:
            args.len

    if positionalCount > 3:
        raise newException(
            ValueError,
            "Too many positional arguments"
        )
    
    if positionalCount == 3:
        result.keyword = args[2]

proc main() =
    var options: CliOptions

    try:
        options = parseCliArguments(commandLineParams())
    except ValueError as e:
        echo "Error: ", e.msg
        quit(1)

    let hasGapOtion = options.hasGapOtion

    var gapThreshold = options.gapThreshold

    if hasGapOtion:
       echo "Gap alert threshold: ", gapThreshold, " seconds"

    let filePath = options.filePath

    if not fileExists(filePath):
        echo "Error: File not found: ", filePath
        quit(1)

    let selectedLevel = options.severity

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

    if options.keyword.len > 0:
        matches = searchEntriesByMessage(matches, options.keyword)

    matches = sortEntriesChronologically(matches)

    echo "Matching events: ", matches.len
    echo selectedLevel, " events:"

    if matches.len == 0:
        echo " No matching event found"
    else:
        for i, entry in matches:
            if i == 0:
                echo "  ", entry.timestamp, " | ", entry.message
            else:
                let gap = calculateTimeGap(matches[i - 1], entry)
                echo "  ", entry.timestamp, " | ", entry.message,
                     " (+", gap, "s)"
                    
                if hasGapOtion and isGapAboveThreshold(matches[i - 1], entry, gapThreshold):
                    echo " [GAP ALERT] ", gap,
                         "s exceeds ", gapThreshold, "s threshold"

when isMainModule:
    main()