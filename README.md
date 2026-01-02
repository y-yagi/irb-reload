# IRB::Reload

`irb-reload` reloads updated files into IRB session like Rails' `reload` command.

## Installation

Add the gem to your application's development dependencies:

```bash
bundle add irb-reload --group development
```

Or install it directly:

```bash
gem install irb-reload
```

## Usage

1. Add `require "irb/reload"` to `.irbrc` or `bin/console`.
1. Start IRB session

```ruby
reload! # Reload updated files
```

### Configuration

You can tweak the watcher through `IRB.conf`.

```ruby
IRB.conf[:RELOAD] = {
	paths: %w[app lib],               # directories to watch. Default is `lib`.
	listen: { latency: 0.2 },         # options forwarded to Listen
}
```

Any keys under `:listen` are passed straight to `Listen.to`. Use this to change latency, polling, or ignore patterns.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to execute the test suite. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/y-yagi/irb-reload. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/y-yagi/irb-reload/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Irb::Reload project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/y-yagi/irb-reload/blob/main/CODE_OF_CONDUCT.md).
