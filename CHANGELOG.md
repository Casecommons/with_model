### 1.2.0

- Allow specifying scope for before/after blocks (Miks Miķelsons)

### 1.1.0
- Support Ruby 2.1
- Support Rails 4.1
- Refactor some internals

### 1.0.0
- Start using [Semantic Versioning 2.0.0](http://semver.org/spec/v2.0.0.html)
- Complete refactor of internals (Andrew Marshall)
- Remove support for Active Record 2 (Andrew Marshall)
- Remove dependency on RSpec (Andrew Marshall)
- Add support for MiniTest (Andrew Marshall)
- Add option for specifying superclass (Miks Miķelsons)

### 0.3.2

- Allow calling with_model without a block. (Andrew Marshall)
- Ensure that ActiveSupport’s descendants works correctly between tests. (Andrew Marshall)
- Allow Active Record 4 in gemspec.

### 0.3.1

- Don’t cache connection between tests. (Ryan Ong & Richard Nuno)

### 0.3

- Use RSpec 2.11’s built-in constant stubbing.
- Remove RSpec 1.x and Active Record 2.x support.
- Remove Mixico support.

### 0.2.6

- Active Record 3.2 compatible. (Steven Harman / Brent Wheeldon)

### 0.2.5

- Clear Active Record 3.x associations class cache between specs to clean up test
- pollution.

### 0.2.4

- Active Record 3.1 compatible.
- Fix bug where column information was being cached incorrectly by Active
- Record.

### 0.2.3

- Create a new class each run to prevent test pollution. (J. Andrew Marshall)
- Use :UpperCase in examples.

### 0.2.2

- The table block is now optional.

### 0.2.1

- Fix a bug when the with_model name contains capital letters. Now you can
- safely make calls like `with_model :BlogPost`

### 0.2

- Remove the buggy attr_accessor method for accessing with_model classes. Now
- there is only the constant available in the example group.

### 0.1.5

- WithModel::Base is now marked as an abstract_class, which makes polymorphic
- belongs_to work properly.

### 0.1.4

- Add ability to pass arguments to create_table.

### 0.1.2

- Make Mixico optional.
