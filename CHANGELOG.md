# YAHLP Changelog

## [2.2.0] - 2026-08-06

### Added
- **Dynamic Service Loading**: Services can now be configured via JSON5 files in `/etc/yahlp/additional-conf` and `/etc/yahlp/additional-vhost` without modifying codebase
- **GraphQL Metrics Support**: Services can expose metrics via GraphQL queries with automatic value extraction and transformation
- **Vhost Integration**: Apache vhost services (.conf files) now automatically appear on the dashboard with `isDynamic` flag
- **Dashboard Metrics API**: New `/api/services/dashboard` endpoint provides metrics for all configured dynamic services
- **Metrics Endpoint**: Generic `/api/:service/metrics/:metricId` endpoint handles metric fetching and transformations (kb_to_gb)
- **API Key Support**: JSON5 configurations can include API keys for authenticated GraphQL queries
- **Auto-enable Dashboard**: Services with metrics defined automatically enable dashboard display
- **Multiple Header Formats**: Support for both `X-Api-Key` and `Authorization` headers for API authentication

### Changed
- Services are now fetched from proxy API at runtime instead of pre-computed in HTML
- Dynamic services (isDynamic: true) skip rendering if no metrics are configured
- Dashboard menu generation now supports mixed built-in and custom services

### Fixed
- Vhost services now properly marked as isDynamic with metrics support
- JSON5 metrics files in additional-vhost no longer overwrite vhost service definitions
- GraphQL query execution with proper authentication headers
- Metrics transformation and value extraction via dot-notation paths

### Technical Details
- Metrics configuration format: `dashboard.metrics[].{id, label, unit, type, query, path, transform}`
- Supported transforms: `kb_to_gb` (kilobytes to gigabytes)
- Metrics are cached for 30 seconds via NodeCache
- Services can be hot-reloaded by modifying JSON5 files

## [2.1.0] - Previous Release

See git history for details on version 2.1.0 and earlier.
