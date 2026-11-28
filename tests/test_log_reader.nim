import std/[unittest, times]
import ../src/traceshards

suite "Log Reader":
    test "Counts non-empty lines":
        check countNonEmptyLines("samples/demo.log") == 4

    test "Ignores whitespace-only lines":
        check countNonEmptyLines("samples/blank.log") == 0

    test "Stores a structured log entry":
        let entry = LogEntry(
            timestamp: "2026-11-23 10:00:02",
            level: "ERROR",
            message: "Connection lost"
        )

        check entry.level == "ERROR"

    test "Extracts severity from a log line":
        let line = "2026-11-23 10:00:02 ERROR Connection lost"
        check extractLevel(line) == "ERROR"

    test "Rejects invalid severity levels":
        let line = "2026-11-23 10:00:02 Connection lost"
        check extractLevel(line) == "UNKNOWN"

    test "Recognize lowercase severity":
        let line = "2026-11-23 10:00:02 error Connection lost"
        check extractLevel(line) == "ERROR"

    test "Parses a complete log entry":
        let line = "2026-11-23 10:00:02 ERROR Connection lost"
        let entry = parseLogLine(line)

        check entry.timestamp == "2026-11-23 10:00:02"
        check entry.level == "ERROR"
        check entry.message == "Connection lost"

    test "Preserves messages without severity":
        let line = "2026-11-23 10:00:02 Connection lost"
        let entry = parseLogLine(line)

        check entry.level == "UNKNOWN"
        check entry.message == "Connection lost"

    test "Parses a single word message":
        let line = "2026-11-23 10:00:02 Connected"
        let entry = parseLogLine(line)

        check entry.timestamp == "2026-11-23 10:00:02"
        check entry.level == "UNKNOWN"
        check entry.message == "Connected"

    test "Handles severity without a message":
        let line = "2026-11-23 10:00:02 ERROR"
        let entry = parseLogLine(line)

        check entry.timestamp == "2026-11-23 10:00:02"
        check entry.level == "ERROR"
        check entry.message == ""

    test "Parses multiple entries from a file":
        let entries = parseLogFile("samples/demo.log")

        check entries.len == 4
        check entries[0].level == "INFO"
        check entries[2].message == "Connection lost"

    test "Skips malformed line when parsing a file":
        let entries = parseLogFile("samples/malformed.log")

        check entries.len == 2

    test "Rejects invalid timestamp text":
        let line = "banana potato ERROR Connection lost"
        let entry = parseLogLine(line)

        check entry.timestamp == ""

    test "Rejects impossible calendar dates":
        let line = "2026-02-30 10:00:02 ERROR Connection lost"
        let entry = parseLogLine(line)

        check entry.timestamp == ""

    test "Preserves rejected log lines":
        let report = parseLogFileWithDiagnostics("samples/malformed.log")

        check report.entries.len == 2
        check report.rejected.len == 1
        check report.rejected[0].lineNumber == 2
        check report.rejected[0].raw == "INVALID_LOG"
        check report.rejected[0].reason == "Incomplete log entry"

    test "Explains invalid timestamp rejection":
        let report = parseLogFileWithDiagnostics("samples/invalid_timestamp.log")

        check report.rejected.len == 1
        check report.rejected[0].reason == "Invalid timestamp"

    test "Preserves spacing within log messages":
        let line = "2026-11-23 10:00:02 ERROR Database  connection  lost"
        let entry = parseLogLine(line)

        check entry.message == "Database  connection  lost"

    test "Parses ISO 8601 UTC log entries":
        let line = "2026-11-23T10:00:02Z ERROR Connection lost"
        let entry = parseLogLine(line)

        check entry.timestamp == "2026-11-23T10:00:02Z"
        check entry.level == "ERROR"
        check entry.message == "Connection lost"

    test "Parses iSO log with a single word message":
        let line = "2026-11-23T10:00:02Z Connected"
        let entry = parseLogLine(line)

        check entry.timestamp == "2026-11-23T10:00:02Z"
        check entry.level == "UNKNOWN"
        check entry.message == "Connected"

    test "Handles ISO severity without a message":
        let line = "2026-11-23T10:00:02Z ERROR"
        let entry = parseLogLine(line)

        check entry. timestamp == "2026-11-23T10:00:02Z"
        check entry.level == "ERROR"
        check entry.message == ""

    test "Rejects impossible ISO UTC dates":
        let line = "2026-02-30T10:00:02Z ERROR Conenction lost"
        let entry = parseLogLine(line)

        check entry.timestamp == ""

    test "Parses ISO timestamp with timezone offsets":
        let line = "2026-11-23T10:00:02+08:00 ERROR Connection lost"
        let entry = parseLogLine(line)

        check entry.timestamp == "2026-11-23T10:00:02+08:00"
        check entry.level == "ERROR"
        check entry.message == "Connection lost"

    test "Rejects invalid timezone offsets":
        let line = "2026-11-23T10:00:02+08:99 ERROR Connection lost"
        let entry = parseLogLine(line)

        check entry.timestamp == ""

    test "Rejects invalid timezone offset hours":
        let line = "2026-11-23T10:00:02+25:00 ERROR Connection lost"
        let entry = parseLogLine(line)

        check entry.timestamp == ""

    test "Parses negative timezone offsets":
        let line = "2026-11-23T10:00:02-05:30 WARN High memory usage"
        let entry = parseLogLine(line)

        check entry.timestamp == "2026-11-23T10:00:02-05:30"
        check entry.level == "WARN"
        check entry.message == "High memory usage"

    test "Rejects timezone offsets without a colon":
        let line = "2026-11-23T10:00:02+0800 ERROR Connection lost"
        let entry = parseLogLine(line)

        check entry.timestamp == ""

    test "Rejects ISO timestamps without timezone":
        let line = "2026-11-23T10:00:02 ERROR Connection lost"
        let entry = parseLogLine(line)

        check entry.timestamp == ""

    test "Parses ISO timestamps with milliseconds":
        let line = "2026-11-23T10:00:02.125Z ERROR Connection lost"
        let entry = parseLogLine(line)

        check entry.timestamp == "2026-11-23T10:00:02.125Z"
        check entry.level == "ERROR"
        check entry.message == "Connection lost"
    
    test "Parses milliseconds with timezone offsets":
        let line = "2026-11-23T10:00:02.125+08:00 ERROR Connection lost"
        let entry = parseLogLine(line)

        check entry.timestamp == "2026-11-23T10:00:02.125+08:00"
        check entry.level == "ERROR"
        check entry.message == "Connection lost"

    test "Counts log entries by severity":
        let entries = @[
            parseLogLine("2026-11-23T10:00:00Z INFO Server started"),
            parseLogLine("2026-11-23T10:00:01Z ERROR Connection lost"),
            parseLogLine("2026-11-23T10:00:02Z WARN Retrying"),
            parseLogLine("2026-11-23T10:00:03Z ERROR Retry failed")
        ]

        check countEntriesByLevel(entries, "ERROR") == 2

    test "Counts severity level case-insensitively":
        let entries = @[
            parseLogLine("2026-11-23T10:00:00Z ERROR Connection lost"),
            parseLogLine("2026-11-23T10:00:01Z INFO Retrying"),
            parseLogLine("2026-11-23T10:00:02Z ERROR Retry failed")
        ]

        check countEntriesByLevel(entries, "error") == 2

    test "Filters log entries by severity":
        let entries = @[
            parseLogLine("2026-11-23T10:00:00Z INFO Server started"),
            parseLogLine("2026-11-23T10:00:01Z ERROR Connection lost"),
            parseLogLine("2026-11-23T10:00:02Z WARN Retrying connection"),
            parseLogLine("2026-11-23T10:00:03Z ERROR Retry failed")
        ]

        let errors = filterEntriesByLevel(entries, "ERROR")

        check errors.len == 2
        check errors[0].message == "Connection lost"
        check errors[1].message == "Retry failed"

    test "Searches log messages case-insensitively":
        let entries = @[
            parseLogLine("2026-11-23T10:00:00Z ERROR Connection lost"),
            parseLogLine("2026-11-23T10:00:01Z INFO Loading configuration"),
            parseLogLine("2026-11-23T10:00:02Z INFO connection restored")
        ]

        let matches = searchEntriesByMessage(entries, "CONNECTION")

        check matches.len == 2
        check matches[0].message == "Connection lost"
        check matches[1].message == "connection restored"

    
    test "Combines severity filtering with ketboard search":
        let entries = @[
            parseLogLine("2026-11-23T10:00:00Z ERROR Connection lost"),
            parseLogLine("2026-11-23T10:00:01Z INFO Connection restored"),
            parseLogLine("2026-11-23T10:00:02Z WARN Connection unstable"),
            parseLogLine("2026-11-23T10:00:03Z ERROR Disk full"),
            parseLogLine("2026-11-23T10:00:04Z ERROR Connection timeout")
        ]

        let errors = filterEntriesByLevel(entries, "ERROR")
        let matches = searchEntriesByMessage(errors, "connection")

        check matches.len == 2
        check matches[0].message == "Connection lost"
        check matches[1].message == "Connection timeout"

    test "Sorts log entries by actual shrnological time":
        let entries = @[
            parseLogLine("2026-11-23T10:00:02+08:00 ERROR Connection lost"),
            parseLogLine("2026-11-23T02:00:03Z ERROR Retry failed"),
            parseLogLine("2026-11-23T02:00:01Z WARN Connection unstable")
        ]

        let sorted = sortEntriesChronologically(entries)

        check sorted.len == 3
        check sorted[0].message == "Connection unstable"
        check sorted[1].message == "Connection lost"
        check sorted[2].message == "Retry failed"

    test "Timezone offsets represent the same instant":
        let malaysia = parseTime(
            "2026-11-23T10:00:02+08:00",
            "yyyy-MM-dd'T'HH:mm:sszzz",
            utc()
        )

        let utcTime = parseTime(
            "2026-11-23T02:00:02+00:00",
            "yyyy-MM-dd'T'HH:mm:sszzz",
            utc()
        )

        check malaysia == utcTime

    test "Sorts milliseconds timestamps chronologically":
        let entries = @[
            parseLogLine("2026-11-23T10:00:02.300+08:00 ERROR Retry failed"),
            parseLogLine("2026-11-23T02:00:02.200Z ERROR Connection lost"),
            parseLogLine("2026-11-23T02:00:01.100Z WARN Connection unstable")
        ]

        let sorted = sortEntriesChronologically(entries)

        check sorted.len == 3
        check sorted[0].message == "Connection unstable"
        check sorted[1].message == "Connection lost"
        check sorted[2].message == "Retry failed"

    test "sorts legacy log timestamps chronologically":
        let entries = @[
            parseLogLine("2026-11-23 10:00:03 ERROR Retry failed"),
            parseLogLine("2026-11-23 10:00:01 WARN Connection unstable"),
            parseLogLine("2026-11-23 10:00:02 ERROR Connection lost")
        ]

        let sorted = sortEntriesChronologically(entries)

        check sorted.len == 3
        check sorted[0].message == "Connection unstable"
        check sorted[1].message == "Connection lost"
        check sorted[2].message == "Retry failed"

    test "Sorts mixed legacy and ISO timestamps":
        let entries = @[
            parseLogLine("2026-11-23T10:00:03+08:00 ERROR Retry failed"),
            parseLogLine("2026-11-23 02:00:02 ERROR Connection lost"),
            parseLogLine("2026-11-23T02:00:01Z WARN Connection unstable")
        ]

        let sorted = sortEntriesChronologically(entries)

        check sorted.len == 3
        check sorted[0].message == "Connection unstable"
        check sorted[1].message == "Connection lost"
        check sorted[2].message == "Retry failed"

    test "Calculates time gap between log entries":
        let first = parseLogLine("2026-11-23T02:00:01Z ERROR Connection lost")
        let second = parseLogLine("2026-11-23T02:00:04Z ERROR Reconnection failed")

        let gap = calculateTimeGap(first, second)

        check gap == 3.0

    test "Calculates millisecond time gaps":
        let first = parseLogLine("2026-11-23T02:00:02.150Z ERROR Connection lost")
        let second = parseLogLine("2026-11-23T10:00:02.400+08:00 INFO Reconnection attempted")

        let gap = calculateTimeGap(first, second)

        check gap == 0.25

    test "Calculates time gaps across midnight":
        let first = parseLogLine("2026-11-23T23:59:58Z ERROR Connection lost")
        let second = parseLogLine("2026-11-24T00:00:03Z INFO Connection restored")

        let gap = calculateTimeGap(first, second)

        check gap == 5.0

    test "Detects time gaps above a threshold":
        let first = parseLogLine("2026-11-23T02:00:01Z ERROR Connection lost")
        let second = parseLogLine("2026-11-23T02:00:13Z WARN Reconnection attempted")

        check isGapAboveThreshold(first, second, 10.0) == true
        check isGapAboveThreshold(first, second, 15.0) == false

    test "Does not flag gaps equal to threshold":
        let first = parseLogLine("2026-11-23T02:00:01Z ERROR Conenction lost")
        let second = parseLogLine("2026-11-23T02:00:13Z WARN Reconnection attempted")

        let gap = calculateTimeGap(first, second)

        check gap == 12.0
        check isGapAboveThreshold(first, second, 12.0) == false

    test "Parses gap option without severity":
        let options = parseCliArguments(@[
            "samples/timeline_demo.log",
            "--gap",
            "1"
        ])

        check options.filePath == "samples/timeline_demo.log"
        check options.severity == "ERROR"
        check options.hasGapOtion == true
        check options.gapThreshold == 1.0

    test "Parses custom severity case-insensitively":
        let options = parseCliArguments(@[
            "samples/timeline_demo.log",
            "warn"
        ])

        check options.filePath == "samples/timeline_demo.log"
        check options.severity == "WARN"
        check options.hasGapOtion == false

    test "Parses custom severity with gap option":
        let options = parseCliArguments(@[
            "samples/timeline_demo.log",
            "warn",
            "--gap",
            "2.5"
        ])

        check options.filePath == "samples/timeline_demo.log"
        check options.severity == "WARN"
        check options.hasGapOtion == true
        check options.gapThreshold == 2.5

    test "Parses keywrod with severity and gap option":
        let options = parseCliArguments(@[
            "samples/timeline_demo.log",
            "ERROR",
            "connection",
            "--gap",
            "1"
        ])

        check options.severity == "ERROR"
        check options.keyword == "connection"
        check options.hasGapOtion == true
        check options.gapThreshold == 1.0

    test "Rejects missing gap threshold":
        expect(ValueError):
            discard parseCliArguments(@[
                "samples/timeline_demo.log",
                "ERROR",
                "--gap"
            ])

    test "Rejects negative gap thresholds":
        expect(ValueError):
            discard parseCliArguments(@[
                "samples/timeline_demo.log",
                "ERROR",
                "--gap",
                "-5"
            ])

    test "Rejects unsupported severity levels":
        expect(ValueError):
            discard parseCliArguments(@[
                "samples/timeline_demo.log",
                "BANANA"
            ])

    test "Rejects excessive positional arguments":
        expect(ValueError):
            discard parseCliArguments(@[
                "samples/timeline_demo.log",
                "ERROR",
                "connection",
                "extra"
            ])

    test "Parses severity and keyword without gap option":
        let options = parseCliArguments(@[
            "samples/timeline_demo.log",
            "warn",
            "connection"
        ])

        check options.filePath == "samples/timeline_demo.log"
        check options.severity == "WARN"
        check options.keyword == "connection"
        check options.hasGapOtion == false

    test "Rejects duplicate gap options":
        expect(ValueError):
            discard parseCliArguments(@[
                "samples/timeline_demo.log",
                "--gap",
                "1",
                "--gap",
                "2"
            ])

    test "Rejects blank log filenames":
        expect(ValueError):
            discard parseCliArguments(@[" "])

    test "Rejects NaN gap thresholds":
        expect(ValueError):
            discard parseCliArguments(@[
                "samples/timeline_demo.log",
                "--gap",
                "NaN"
            ])

    test "Rejects infinite gap threshold":
        expect(ValueError):
            discard parseCliArguments(@[
                "samples/timeline_demo.log",
                "--gap",
                "Inf"
            ])
        
    test "Uses default CLI options":
        let options = parseCliArguments(@[
            "samples/timeline_demo.log"
        ])

        check options.filePath == "samples/timeline_demo.log"
        check options.severity == "ERROR"
        check options.keyword == ""
        check options.hasGapOtion == false
        check options.gapThreshold == 0.0

    test "Parses help option":
        let option =parseCliArguments(@["--help"])

        check option.showHelp == true