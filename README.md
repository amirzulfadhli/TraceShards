# TraceShards

A log investigation tool for finding recurring errors and understanding events behind them

TraceShards is a Python based command line application designed to help developers read, organize and ivestigate application logs more easily

## About the Project

Application logs record useful information about how a program behaves, including normal operations, warnings and errors. However, finding the cause of a failure can be difficult when a log file contains hundreds or thousands of entries

Searching for an error message alone does not always explain what happened. Developers may need to inspect earlier events, compare repaeted failures and identify patterns across timestamps

TraceShards aims to simplify this process by parsing log files, grouping recurring erros and showing the events that occured before a selected failure

The goal is to make local log investigation faster and easier without requiring a large monitoring platform

## Planned Features

### Log File Management

1. Open supported local application log files
2. Read log entries and extract important information
3. Recognize timestamps, severity levels and messages in supported formats
4. Handle malformed/incomplete entries without crashing
5. Display basic information about imported log file

### Search and Filtering

1. Filter entries by severity level such as INFO/WARNING/ERROR
2. Search log messages by kerword
3. Filter entries within a selected time range
4. Display matching entries in chronological order

### Error Grouping

1. Identify repeated error messages
2. Group similar errors using basic message normalization
3. Count how often each error group occurs
4. Show the earliest and latest occurance of each group 
5. Select an error group for closer inspection

### Event investigation

1. Display log entries leading up to a selected error
2. Set how many preceding event to inspect
3. Preserve the original event order and timestamps
4. Show surrounding warnigns or other relevant entries
5. Help developers investigate possible causes without claiming to determine the root cause automatically

### Investigation Summary

1. Show total entries and error counts
2. list teh most frequent error groups
3. Present readable investigation results in the terminal
4. Optionally export a basic summary after the core features are working

### Tech Stack

| Technology | Purpose |
| --- | --- |
| Python | Main application logic and log processing |
| pathlib | Local file and path handling |
| re | Log patterns and basic error normalization |
| datetime | Timestamp parsing and comparison |
| argparse | Command line options and arguments |
| collections | Error countes and grouping |
| unittest | Automated tests |
| Git & GitHub | Version control and project documentation |

//The proposed stack uses Python's standrad library first. It may change during developement

## How it Works

1. The user Provides a supported log file through the command line interface
2. TraceShards reads the file and seperates it into log entries
3. The parser extracts timestamps, severity levels and messages 
4. The user filters or searches entries to find relevant activity
5. TraceShards groups repeated errors and summarized their frequency
6. The user selects an error occurance or group to investigate
7. TraceShards displays the evnets before the error in chronological order
8. The user reviews the event sequence tp investigate what may have led to the failure

## Installation and Running the Project

Status: not yet available

## Planned Requirements

- Python 3 (version to be confirmed)
- Windows/macOs/Linux
- Git

## Planned Developement Setup

1. Clone the TraceShards repository
2. Open the project directory
3. Verify that a supported Python version is installed
4. Run the application using the documented command line entry point
5. Provide a sample log file and select an investigation option

Exact commands, supported platforms and any dependencies will be added after the project have been  tested

## Developement Journey

### Planned Developement Milestiones

| Phase | Developement Work | Estimated Hours |
| --- | --- | --- |
| 1 | Planning, README, requirements | 1h |
| 2 | Project setup and sample log files | 2h |
| 3 | Log reader and parser | 3h |
| 4 | malformed entries, timestamp handling | 2h |
| 5 | Severity, keyword, time filtering | 2h |
| 6 | Error grouping, occurance counts | 3h |
| 7 | Pre error event investigation | 4h |
| 8 | CLI commands, readable output | 3h |
| 9 | Testing and debugging | 3h |
| 10 | Final verification, documentation, testing | 2h |

//These are estimated planning target, Actual sessions will be updated based on completed work

### Actual Developement Time Log

| Date | Work completed | Actual Eligible TIme |
|  - | - | - |

## Challenges and Lessorns Learned

This section will record actual problems encountered during developement, including parsing difficulties, unexpected log formats, grouping mistakes, debugging and improvements

## Screenshots and Demo

Screenshots or GIFs of log parsing, error grouping and event investigation will be added once those features are implemented

Demo: not available yet

## Project Scope

The initial version focuses on investigating local, timestamped text logs through a Python command line interface. A specific input format will be chosen and documented during developement

Features outside the initial scope:

- Live log streaming from remote servers
- Cloud storage/synchronization
- User accounts and team collaboration
- AI generated root cause analysis
- A web dashboard/full graphical interface
- Integration with enterprise monitoring services

## Future Improvements

Possible improvements after the initial version:

- Support for additionla log formats and multiline entries
- Investigation across multiple log files
- More advanced error similarity detection
- Interactive terminal navigation
- Exporting  detaild investigation reports
- A visual timeline of errors and surrounding events

//These are possible future additions, not implemented features

## AI disclosure

AI assistance was used to help organize project draft, brainstorm project scope and estimate developement roadmap

Implementation, debugging, testing and developement will be recorded and done by myself rather than assumed from this plan

This document will be recorded based on work performed and any additional AI assistance during the project progress

## Project Goal

Create a functional local log investigation tool that makes finding recurring errors easier and inspect the events preceding failures, whule learning Python file processing, parsing, data grouping, command line design, debugging and software testing