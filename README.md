# calabash parallel execution

## NOTE: This is not yet tested on windows.


Run calabash-android tests in parallel on multiple connected devices. This is inspired by parallel_tests  https://rubygems.org/gems/parallel_tests

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

Example: parallel_calabash -a my.apk -o 'cucumber_opts_like_tags_profile_etc_here' features/


    -h, --help                       Show this message
    -v, --version                    Show version
    -a, --apk apk_path               apk file path
    -o, --cucumber_opts '[OPTIONS]'  execute with those cucumber options

    -d distribution_tag,             divide features into groups as per occurrence of given tag
            --distribution-tag
        --serialize-stdout           Serialize stdout output show output only after process completion
        
## REPROTING

use ENV['TEST_PROCESS_NUMBER'] environment variable in your ruby scripts to find out the process number. you can use this for reporting purpose.

eg. modify default profile in cucumber.yml as below to get different report from different process

default: --format html --out reports/Automation_report_<%= ENV['TEST_PROCESS_NUMBER'] %>.html --format pretty

## Contributing

1. Fork it ( https://github.com/[my-github-username]/parallel_calabash/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
