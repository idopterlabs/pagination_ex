# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2025-03-05

### Added

- Initial version with core pagination functionality
- `PaginationEx.Core` module for paginating Ecto queries with:
  - Customizable page size
  - Total entries and page calculations
  - Support for complex queries (grouped, distinct, etc.)
- `PaginationEx.HTML` module with Phoenix integration:
  - Tailwind CSS styled pagination controls
  - Support for path helpers and URL strings
  - Customizable through template modules
  - i18n support via Gettext
- `PaginationEx.Config` module for centralized configuration:
  - Configurable repo, router helpers, and Gettext
  - Default pagination settings
  - Runtime validation of required configuration

[0.1.0]: https://github.com/idopterlabs/pagination_ex/releases/tag/v0.1.0