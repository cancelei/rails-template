# Linting Guide

This guide explains the code quality and linting setup for this Rails application.

## Quick Start

### Run All Linters

```bash
# Check all files (no changes)
./bin/lint

# Auto-fix all issues
./bin/lint --fix
```

### Run Individual Linters

```bash
# Only RuboCop
./bin/lint --only rubocop

# Only ESLint with auto-fix
./bin/lint --only eslint --fix

# Only Stylelint
./bin/lint --only stylelint

# Only ERB Lint
./bin/lint --only erb_lint
```

## Available Linters

This project uses four different linters for comprehensive code quality:

### 1. RuboCop (Ruby)

**Purpose**: Enforces Ruby style guide and best practices

**Configuration**: `.rubocop.yml`

**Run directly**:
```bash
bin/rubocop              # Check only
bin/rubocop -a           # Auto-correct
```

**Key rules**:
- Line length: 120 characters
- Method length: 20 lines (excluding migrations, specs, controllers)
- Uses double quotes for strings
- Enforces Rails best practices
- RSpec and FactoryBot conventions

**Plugins**:
- rubocop-capybara
- rubocop-factory_bot
- rubocop-performance
- rubocop-rails
- rubocop-rspec
- rubocop-rspec_rails

### 2. ERB Lint (ERB Templates)

**Purpose**: Lints ERB templates for security and style

**Configuration**: `.erb_lint.yml`

**Run directly**:
```bash
bundle exec erb_lint --lint-all               # Check only
bundle exec erb_lint --lint-all --autocorrect # Auto-fix
```

**Key rules**:
- Enforces ERB safety
- Self-closing tags
- Disables hard-coded strings (for i18n future-proofing)
- Allows partial instance variables (common Rails pattern)

### 3. ESLint (JavaScript)

**Purpose**: Enforces JavaScript style and best practices

**Configuration**: `eslint.config.js`

**Run directly**:
```bash
npm run js-lint          # Check only
npm run js-lint-fix      # Auto-fix
```

**Key rules**:
- Ackama style guide (professional JavaScript standards)
- Jest and Testing Library conventions
- Import/export best practices
- Prettier integration for formatting

**Plugins**:
- @eslint/js
- eslint-plugin-import
- eslint-plugin-jest
- eslint-plugin-jest-dom
- eslint-plugin-jest-formatting
- eslint-plugin-testing-library
- eslint-plugin-prettier

### 4. Stylelint (CSS)

**Purpose**: Enforces CSS/SCSS style and catches errors

**Configuration**: `.stylelintrc.js`

**Ignore patterns**: `.stylelintignore`

**Run directly**:
```bash
npm run css-lint         # Check only
npm run css-lint-fix     # Auto-fix
```

**Key rules**:
- SCSS recommended config
- No descending specificity warnings (disabled for utility-first CSS)
- No duplicate properties or custom properties
- Supports Tailwind v4 custom properties (ring, ring-color, etc.)

**Ignored paths**:
- `node_modules/`
- `coverage/`
- `public/`
- `vendor/`
- `tmp/`
- `app/assets/builds/` (generated files)

## Configuration Files

```
.
├── .rubocop.yml         # RuboCop configuration
├── .erb_lint.yml        # ERB Lint configuration
├── eslint.config.js     # ESLint configuration
├── .stylelintrc.js      # Stylelint configuration
├── .stylelintignore     # Stylelint ignore patterns
└── bin/lint             # Unified lint runner script
```

## CI/CD Integration

The unified lint script is designed for CI/CD pipelines:

```bash
# In your CI pipeline
./bin/lint
```

Exit codes:
- `0`: All linters passed
- `1`: One or more linters failed

You can also check individual linters in separate CI jobs:

```yaml
# Example GitHub Actions
jobs:
  lint-ruby:
    runs-on: ubuntu-latest
    steps:
      - run: ./bin/lint --only rubocop

  lint-javascript:
    runs-on: ubuntu-latest
    steps:
      - run: ./bin/lint --only eslint

  lint-css:
    runs-on: ubuntu-latest
    steps:
      - run: ./bin/lint --only stylelint

  lint-erb:
    runs-on: ubuntu-latest
    steps:
      - run: ./bin/lint --only erb_lint
```

## Common Issues and Solutions

### RuboCop: Metrics violations

**Issue**: Methods are too complex or too long

**Solution**:
- Break down large methods into smaller ones
- Extract logic into service objects
- Use concerns for shared behavior
- Some exceptions are configured (controllers, specs, jobs)

### ESLint: Testing Library violations

**Issue**: Direct DOM node access in tests

**Solution**:
- Use Testing Library queries (`getByRole`, `getByText`, etc.)
- Avoid `querySelector` in tests
- Use semantic queries for better accessibility

### Stylelint: Unknown properties

**Issue**: Tailwind custom properties not recognized

**Solution**:
- Already configured to ignore Tailwind properties
- Check `.stylelintrc.js` `property-no-unknown` rule
- Add new Tailwind properties to `ignoreProperties` if needed

### ERB Lint: Hard-coded strings

**Issue**: Text in templates should be internationalized

**Solution**:
- This rule is disabled (`HardCodedString: enabled: false`)
- Enable when ready to add i18n support
- Use `I18n.t()` for all user-facing strings

## Pre-commit Hooks

You can add linting to pre-commit hooks using tools like Husky or Overcommit:

### Using Overcommit

```yaml
# .overcommit.yml
PreCommit:
  RuboCop:
    enabled: true
    command: ['bin/rubocop']

  EsLint:
    enabled: true
    command: ['npm', 'run', 'js-lint']

  StyleLint:
    enabled: true
    command: ['npm', 'run', 'css-lint']
```

### Using Lefthook

```yaml
# lefthook.yml
pre-commit:
  commands:
    lint:
      run: ./bin/lint
```

## Auto-fix on Save (Editor Integration)

### VS Code

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true,
    "source.fixAll.stylelint": true
  },
  "ruby.rubocop.onSave": true,
  "[ruby]": {
    "editor.defaultFormatter": "rubocop"
  }
}
```

### RubyMine/IntelliJ

1. Go to Preferences → Tools → RuboCop
2. Enable "Run RuboCop on Save"
3. Go to Preferences → Languages → JavaScript → ESLint
4. Enable "Run eslint --fix on save"

## Disabling Rules

### In specific files

**Ruby:**
```ruby
# rubocop:disable Style/Documentation
class MyClass
  # ...
end
# rubocop:enable Style/Documentation
```

**JavaScript:**
```javascript
/* eslint-disable no-console */
console.log('Debug info');
/* eslint-enable no-console */
```

**CSS:**
```css
/* stylelint-disable property-no-unknown */
.custom {
  custom-property: value;
}
/* stylelint-enable property-no-unknown */
```

### In configuration

Edit the respective configuration file (`.rubocop.yml`, `eslint.config.js`, `.stylelintrc.js`)

## Performance Tips

1. **Run only changed files**:
   ```bash
   # RuboCop on changed files
   git diff --name-only --diff-filter=AM | grep '\.rb$' | xargs bin/rubocop

   # ESLint on changed files
   git diff --name-only --diff-filter=AM | grep '\.js$' | xargs npm run js-lint
   ```

2. **Use linter caches**:
   - RuboCop: Uses `.rubocop_cache/` automatically
   - ESLint: Uses `.eslintcache` (add to .gitignore)

3. **Parallel execution**:
   - RuboCop: Built-in parallel processing
   - ESLint: `--max-warnings 0` for stricter checking

## Contributing

When contributing to this project:

1. **Run linters before committing**:
   ```bash
   ./bin/lint --fix
   ```

2. **Address all violations**: Don't commit code with linting errors

3. **Disable rules sparingly**: Only disable rules with good reason and add a comment explaining why

4. **Update configs carefully**: Discuss significant config changes with the team

## Resources

- [RuboCop Documentation](https://docs.rubocop.org/)
- [ESLint Documentation](https://eslint.org/docs/latest/)
- [Stylelint Documentation](https://stylelint.io/)
- [ERB Lint Documentation](https://github.com/Shopify/erb-lint)
- [Ruby Style Guide](https://rubystyle.guide/)
- [JavaScript Style Guide (Ackama)](https://github.com/ackama/eslint-config-ackama)

---

**Last Updated**: November 2025

For questions or improvements to this guide, please create an issue or pull request.
