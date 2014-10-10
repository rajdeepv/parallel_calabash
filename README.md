# ParallelCalabash

Run calabash-android tests in parallel on multiple connected devices

eg. bundle exec parallel_calabash -a my.apk -o'--format pretty' features/ --serialize-stdout

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'parallel_calabash'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install parallel_calabash

## Usage

Usage: parallel_calabash [options]

Example: parallel_calabash -a my.apk -o '<cucumber opts>' features/


    -h, --help                       Show this message
    -v, --version                    Show version
    -a, --apk apk_path               apk file path
    -o, --cucumber_opts '[OPTIONS]'  execute with those cucumber options
        --serialize-stdout           Serialize stdout output show output only after process completion

## Contributing

1. Fork it ( https://github.com/[my-github-username]/parallel_calabash/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
