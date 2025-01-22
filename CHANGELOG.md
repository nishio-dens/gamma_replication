# Changelog

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
