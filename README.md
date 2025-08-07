# oe-cqm-parsers

A Docker-based tool for parsing eCQM (Electronic Clinical Quality Measures) files and generating OpenEMR-compatible SQL lists for QRDA period reporting.

## Overview

This project processes CMS eCQM measure files (ZIP format) and converts them into JSON format with value sets, then generates SQL insert statements for OpenEMR's list_options table to enable eCQM selection in the QRDA export interface.

## Features

- Parse CMS eCQM ZIP files into structured JSON
- Extract value sets from measure definitions
- Generate OpenEMR-compatible SQL for UI menu configuration
- Docker containerized for consistent environment
- MongoDB integration for CQM processing
- VSAC (Value Set Authority Center) integration

## Prerequisites

- Docker and Docker Compose
- VSAC API Key (obtain from [VSAC](https://vsac.nlm.nih.gov/))

## Quick Start

### 1. Clone Repository
```bash
git clone <repository-url>
cd oe-cqm-parsers
```

### 2. Environment Setup
Create a `.env` file with your VSAC API key:
```bash
echo "VSAC_API_KEY=your_api_key_here" > .env
```

### 3. Build and Run Docker Container
```bash
# Build the container
docker-compose build

# Start services (MongoDB + parser)
docker-compose up -d

# Access the parser container
docker-compose exec parser bash
```

## Usage

### Parse eCQM Measures
Place your CMS eCQM ZIP files in the `{year}_reporting_period/cms_measures/` directory, then run:

```bash
# Inside the container
ruby script.rb --year 2025

# Or specify a custom VSAC profile
ruby script.rb --profile "eCQM Update 2024-05-02"

# From outside container
docker-compose exec parser ruby script.rb --year 2025
```

**Directory Structure**: When using `--year`, the script expects measures in `{year}_reporting_period/cms_measures/` (e.g., `2025_reporting_period/cms_measures/`)

**Available options:**
- `--year YEAR`: Use eCQM Update profile for specific year (2019-2025)
- `--profile PROFILE`: Use custom VSAC profile name (overrides --year)
- `--measures-dir DIR`: Input directory for ZIP files (default: cms_measures)
- `--output-dir DIR`: Output directory for JSON (default: json_measures)
- `--help`: Show all available options and supported years

**Supported eCQM Update profiles by year:**
- 2025: eCQM Update 2025-05-08
- 2024: eCQM Update 2024-05-02
- 2023: eCQM Update 2023-05-04
- 2022: eCQM Update 2022-05-05
- 2021: eCQM Update 2021-05-06
- 2020: eCQM Update 2020-05-07
- 2019: eCQM Update 2019-05-10

This will:
- Process all ZIP files in specified measures directory
- Extract measures and value sets using selected VSAC profile
- Output JSON files to `{year}_reporting_period/json_measures/[measure_name]/`
- Skip processing if measure JSON already exists
- Log any failed measures with timestamp

### Generate OpenEMR SQL Lists
Create SQL insert statements for OpenEMR's UI menus:

```bash
# Inside the container - generate SQL for a specific reporting period
ruby generate_ecqm_list.rb \
  --year 2025 \
  --list-id "ecqm_2025_reporting" \
  --list-title "eCQM 2025 Performance Period" \
  --defaults "CMS122v12,CMS124v12,CMS125v12" \
  --output-dir output/

# Or use auto-generated list ID and title
ruby generate_ecqm_list.rb --year 2025 --defaults "CMS122v12,CMS124v12"

# From outside container
docker-compose exec parser ruby generate_ecqm_list.rb --year 2025
```

**Options:**
- `--year`: Reporting period year (required for auto-generation)
- `--list-id`: Custom list identifier
- `--list-title`: Display title for the list
- `--defaults`: Comma-separated CMS IDs to mark as default active
- `--json-dir`: Source directory for parsed JSON measures
- `--output-dir`: Output directory for SQL files

### Apply SQL to OpenEMR
Import the generated SQL file into your OpenEMR database:

```bash
mysql -u openemr_user -p openemr_db < output/ecqm_2025_reporting.sql
```

## Project Structure

```
oe-cqm-parsers/
├── 2025_reporting_period/      # Year-specific directories
│   ├── cms_measures/           # Input: CMS eCQM ZIP files for 2025
│   └── json_measures/          # Output: Parsed JSON measures for 2025
├── 2024_reporting_period/
│   ├── cms_measures/           # Input: CMS eCQM ZIP files for 2024
│   └── json_measures/          # Output: Parsed JSON measures for 2024
├── output/                     # Output: Generated SQL files
├── script.rb                   # Main parsing script
├── generate_ecqm_list.rb       # SQL generation script
├── docker-compose.yml          # Docker services configuration
├── Dockerfile                  # Container build instructions
└── .env                        # Environment variables (VSAC_API_KEY)
```

## Docker Commands Reference

```bash
# Build container
docker-compose build

# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs parser

# Access container shell
docker-compose exec parser bash

# Run parsing script from outside container
docker-compose exec parser ruby script.rb --year 2025

# Generate SQL lists from outside container  
docker-compose exec parser ruby generate_ecqm_list.rb --year 2025

# Run one-off commands
docker-compose run parser ruby script.rb --help
```

## Integration with OpenEMR

The generated SQL creates list options that integrate with OpenEMR's QRDA export functionality:

1. **Lists Table Entry**: Creates a new list category for the reporting period
2. **List Options**: Individual eCQM measures as selectable options
3. **Default Selection**: Marks specified measures as default active
4. **Descriptions**: Includes measure descriptions for UI tooltips

## Troubleshooting

**VSAC Authentication Errors:**
- Verify your VSAC_API_KEY in `.env`
- Check that your VSAC account has appropriate permissions

**MongoDB Connection Issues:**
- Ensure MongoDB container is running: `docker-compose ps`
- Check container logs: `docker-compose logs mongo`

**Failed Measure Processing:**
- Review `failed_measures.log` for specific errors
- Verify ZIP file integrity and format

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
