# Changelog

## [0.1.4] - 2024-02-18

### Enhanced
- Simplified error messages by removing stack traces

## [0.1.3] - 2024-02-18

### Enhanced
- Improved error logging format for better CloudWatch Logs integration

## [0.1.2] - 2024-02-18

### Added
- Added configurable statistics reporting feature
- Added command line options for enabling/disabling statistics (--enable-stats)
- Added command line option for setting statistics interval (--stats-interval)

### Enhanced
- Improved JSON data handling with automatic sanitization
- Enhanced logging format for better CloudWatch Logs integration

## [0.1.1] - 2024-01-21

### Fixed
- Fixed SQL syntax error when using MySQL reserved words as column names by properly escaping them with backticks
- Fixed error handling in DELETE operations when primary key is missing

## [0.1.0] - 2024-01-20

### Added
- Initial release
- Basic replication functionality using Maxwell's Daemon
- Support for data masking through hooks
- Dry-run mode for testing
