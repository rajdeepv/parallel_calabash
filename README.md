# calabash parallel execution

## Watch a quick demo here:

https://www.youtube.com/watch?v=sK3s0txeJvc


Run calabash-android or calabash-ios tests in parallel on multiple connected devices. This is inspired by parallel_tests  https://rubygems.org/gems/parallel_tests

eg. bundle exec parallel_calabash --apk my.apk -o'--format pretty' features/ --serialize-stdout
eg. bundle exec parallel_calabash --app my.app -o'--format pretty' features/ --serialize-stdout

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'parallel_calabash'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install parallel_calabash

## Usage Android

Usage: parallel_calabash [options]

Example: parallel_calabash -a my.apk -o 'cucumber_opts_like_tags_profile_etc_here' features/

    -h, --help                       Show this message
    -v, --version                    Show version
    -a, --apk apk_path               apk file path
    -o, --cucumber_opts '[OPTIONS]'  execute with those cucumber options
    --serialize-stdout               Serialize stdout output, nothing will be written until everything is done
    --group-by-scenarios             Distribute equally as per scenarios. This uses cucumber dry run
    --concurrent                     Run tests concurrently. Each test will run once on each device.

## Usage iOS

Example: parallel_calabash -a my.apk -o '<cucumber opts>' -r '<cucumber_reports>' features/
    -h, --help                       Show this message
    -v, --version                    Show version
        --app app_path               app file path
        --device_target target       ios target if no .parallel-calabash config
        --device_endpoint endpoint   ios endpoint if no .parallel-calabash config
        --simulator type             for simctl create, e.g. 'com.apple.CoreSimulator.SimDeviceType.iPhone-6 com.apple.CoreSimulator.SimRuntime.iOS-8-4'
        --ios_config file            for ios, configuration for devices and users
    -d, --distribution-tag tag       divide features into groups as per occurrence of given tag
    -f, --filter filter              Filter devices to run tests against using partial device id or model name matching. Multiple filters seperated by ','
        --skip_ios_ping_check        Skip the connectivity test for iOS devices
    -o, --cucumber_opts '[OPTIONS]'  execute with those cucumber options
    -r '[REPORTS]',                  generate these cucumber reports (not during filtering)
        --cucumber_reports
        --serialize-stdout           Serialize stdout output, nothing will be written until everything is done
        --concurrent                 Run tests concurrently. Each test will run once on each device
        --group-by-scenarios         Distribute equally as per scenarios. This uses cucumber dry run

### iOS configuration

* iOS testing is only supported on MacOS hosts.
* Each device or simulator must run as a separate user account (Settings > Users & Groups)
** As the main account - the one that runs parallel_calabash - run ssh-keygen
** As each test account (which can include the main account)
*** Log in to the user graphically
*** Settings > Sharing > Remote Login > Allow access for main account
*** Copy ~main_account/.ssh/id_rsa.pub into each test account's ~tester/.ssh/authorized_keys
*** Any other set-up, e.g. ln -s /Users/main_account/.rvm ~/.rvm
*** If you want to test on simulators, you should also:
**** Settings > Sharing > Screen sharing > Allow access for all users and set a VNC password
**** And make sure every test user has a desktop open (e.g. TightVNC) when you start testing.
* Create .parallel_calabash based on the following
** (You have two files .parallel_calabash.iphoneos (for devices) and .parallel_calabash.iphonesimulator (for simulators))

    {
      USERS: [ 'qa', 'qa2', 'qa3' ],
      # CALABASH_SERVER_PORT: 3800,
      INIT: '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"',
      # Omit 'DEVICES' entirely if you're only testing on simulators.
      DEVICES: [
        {
          NAME: 'ios-iphone5c-tinkywinkie (8.4.1)',
          DEVICE_TARGET: '23984729837401987239874987239',
          DEVICE_ENDPOINT: 'http://192.168.126.206:37265'
        },
        {
          NAME: 'ios-iphone6plus-lala (8.4)',
          DEVICE_TARGET: 'c987234987983458729375923485792345',
          DEVICE_ENDPOINT: 'http://192.168.126.205:37265',
        },
        {
          NAME: 'ios-iphone6plus-dipsy (8.4.1)',
          DEVICE_TARGET: '98723498792873459872398475982347589',
          DEVICE_ENDPOINT: 'http://192.168.126.207:37265',
        }
      ]
    }


## REPORTING

use ENV['TEST_PROCESS_NUMBER'] environment variable in your ruby scripts to find out the process number. you can use this for reporting purpose OR process specific action.

To get device model info, use ENV['DEVICE_INFO'] env variable.

eg. modify default profile in cucumber.yml as below to get different report from different process

default: --format html --out reports/Report_<%=ENV['DEVICE_INFO']%>_<%= ENV['TEST_PROCESS_NUMBER']%>.html --format pretty

## Contributing

1. Fork it ( https://github.com/[my-github-username]/parallel_calabash/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
