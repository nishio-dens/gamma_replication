# GammaReplication

GammaReplication is a tool that reads MySQL binlog using [Maxwell's Daemon](https://github.com/zendesk/maxwell) and replicates data to another MySQL database while masking sensitive information.

## Features

- Real-time replication using MySQL binlog
- Column-level data masking
- Flexible hook system for custom data transformation
- Dry-run mode for operation verification

## Requirements

- Ruby 3.0.0 or higher
- MySQL 5.7 or higher
- Maxwell's Daemon
- Java 8 or higher (for Maxwell's Daemon)

## Directory Structure

The tool expects Maxwell's Daemon to be available in the same directory:

```
your_project/
├── maxwell/
│   └── bin/
│       └── maxwell
└── your_application_files
```

## Installation

```bash
gem install gamma_replication
```

Or add this line to your application's Gemfile:

```ruby
gem 'gamma_replication'
```

## Setup

1. Set up Maxwell's Daemon:
```bash
# Download Maxwell's Daemon
wget https://github.com/zendesk/maxwell/releases/download/v1.42.2/maxwell-1.42.2.tar.gz
tar xvf maxwell-1.42.2.tar.gz
mv maxwell-1.42.2 maxwell

# The maxwell executable will be available at maxwell/bin/maxwell
```

2. Create configuration files:

```bash
bin/setup
```

This command will create the following files:
- `config.properties`: Maxwell configuration
- `settings.yml`: Database connection settings
- `data.yml`: Table and masking configuration
- `hooks/`: Masking scripts

3. Configure MySQL:
   - Enable binlog in your MySQL configuration:
   ```ini
   [mysqld]
   server-id=1
   log-bin=master
   binlog_format=row
   ```
   - Create a user with replication privileges:
   ```sql
   CREATE USER 'maxwell'@'%' IDENTIFIED BY 'maxwell';
   GRANT ALL ON maxwell.* TO 'maxwell'@'%';
   GRANT SELECT, REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO 'maxwell'@'%';
   ```

4. Edit configuration files:

### settings.yml
```yaml
in_database_config:
  host: localhost
  port: 3306
  username: repl_user
  password: password
  database: source_db

out_database_config:
  host: localhost
  port: 3306
  username: root
  password: password
  database: target_db
```

### data.yml
```yaml
- data:
    table: "users"
    hooks:
      - column:
          name:
            - "email"
          scripts:
            - "hooks/mask_email.rb"
      - column:
          name:
            - "phone_number"
          scripts:
            - "hooks/mask_phone_number.rb"
```

## Usage

### Start Replication

```bash
gamma_replication start -s settings.yml -d data.yml -m config.properties
```

### Dry Run (Check SQL)

```bash
gamma_replication dryrun -s settings.yml -d data.yml -m config.properties
```

## Custom Masking

Create Ruby scripts in the `hooks/` directory to implement custom masking logic:

```ruby
class MaskEmail
  def execute(apply, column, value)
    return value unless apply
    "masked_#{value}"
  end
end
```

## Development

1. Clone the repository
2. Run `bin/setup` to install dependencies
3. Run `rake spec` to run the tests
4. Run `bin/console` for an interactive prompt

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request