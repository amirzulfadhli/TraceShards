import std/unittest
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
