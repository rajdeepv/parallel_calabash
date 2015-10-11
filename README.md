# calabash parallel execution

[![Build Status](https://travis-ci.org/rajdeepv/parallel_calabash.svg?branch=master)](https://travis-ci.org/rajdeepv/parallel_calabash)

## Watch a quick demo here:

https://www.youtube.com/watch?v=sK3s0txeJvc


Run calabash-android or calabash-ios tests in parallel on multiple connected devices. This is inspired by parallel_tests  https://rubygems.org/gems/parallel_tests

eg. Android: bundle exec parallel_calabash --apk my.apk -o'--format pretty' features/ --serialize-stdout  
eg. iOS: bundle exec parallel_calabash --app my.app -o'--format pretty' features/ --serialize-stdout

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
    -f, --filter                     Filter devices to run tests against using partial device id or model name matching. Multiple filters seperated by ','
    --serialize-stdout               Serialize stdout output, nothing will be written until everything is done
    --group-by-scenarios             Distribute equally as per scenarios. This uses cucumber dry run
    --concurrent                     Run tests concurrently. Each test will run once on each device.

## Usage iOS

Example: parallel_calabash -app my.app --ios_config ~/.parallel_calabash.iphoneos -o '-cucumber -opts' -r '-cucumber -reports>' features/

    -h, --help                       Show this message
    -v, --version                    Show version
        --app app_path               app file path
        --device_target target       ios target if no .parallel-calabash config
        --device_endpoint endpoint   ios endpoint if no .parallel-calabash config
        --simulator type             for simctl create, e.g. 'com.apple.CoreSimulator.SimDeviceType.iPhone-6 com.apple.CoreSimulator.SimRuntime.iOS-8-4'
        --ios_config file            for ios, configuration for devices and users
    -d, --distribution-tag tag       divide features into groups as per occurrence of given tag
    -f, --filter filter              Filter devices to run tests against keys or values in config. Multiple filters seperated by ','
        --skip_ios_ping_check        Skip the connectivity test for iOS devices
    -o, --cucumber_opts '[OPTIONS]'  execute with those cucumber options
    -r '[REPORTS]',                  generate these cucumber reports (not during filtering)
        --cucumber_reports
        --serialize-stdout           Serialize stdout output, nothing will be written until everything is done
        --concurrent                 Run tests concurrently. Each test will run once on each device
        --group-by-scenarios         Distribute equally as per scenarios. This uses cucumber dry run

### iOS set-up

* iOS testing is only supported on MacOS hosts.
* Create as many (Administrator-privileged!) test accounts as you have devices or want simulators (Settings > Users & Groups)
* As the main user, the one that runs parallel_calabash, create ~/.parallel_calabash.iphonesimulator and/or ~/.parallel_calabash.iphoneos

As follows:

    {
      USERS: [ 'tester1', 'tester2', 'tester3' ],
      INIT: '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"',
      # You only need to specify the port if the default clashes for you. Simulators start sequentially from this.
      # CALABASH_SERVER_PORT: 3800,
      # You only need to give the test users' password if you want to run autostart_test_users
      # PASSWORD: 'testuserspassword',
      # You only need to set this if you want to run autostart_test_users and the default 6900 clashes with something.
      # VNC_FORWARD: 6900,
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

* As the main account, run ssh-keygen
* As each test account:
1. Use Screen Sharing to log in to the user's desktop (particularly if you're using simulators) to let the computer set it up.
2. Settings > Sharing > Remote Login > Allow access for main account (if not already permitted by Remote Management)
3. Copy ~main_account/.ssh/id_rsa.pub into each test account's ~tester1/.ssh/authorized_keys
4. Any other set-up, e.g. ln -s /Users/main_account/.rvm ~/.rvm

* If you don't want to test on simulators, your set-up stops here.
* If you want to test on simulators too...
* ... for each test user, Settings > Sharing > Screen sharing > Allow access (if not already permitted by Remote Management)
* ... (we were suprised that a mac mini can cheerfully run upwards of 7 simulators without much struggle)
* ... and as your primary user:
1. Run: sudo defaults write com.apple.ScreenSharing skipLocalAddressCheck -boolean YES
2. Run: ln -s ~/.parallel_config.iphonesimulator ~/.parallel_config.autostart  (or whatever your simulators' config is called).
3. Add a PASSWORD: 'whatever', in your config - same password for all test users.
4. Copy misc/autostart_test_users.app from the Git repository into the system /Applications/ directory
5. Run /Applications/autostart_test_users, skip the countdown, and see it complain about accessibility; close the connection request dialog
6. In Settings > Privacy & Security > Privacy > Accessibility, allow it - close Settings
7. Re-run it, skip the countdown, and it should open a screen sharing session for each test user.
8. Add it into Settings > User & Groups > Login Items, set BOOT_DELAY if you need to tune the post-login startup time.

## FILTERING
Filters are partial matches on the device id, or model name.
> adb devices -l
List of devices attached
4100142545f271b5       device usb:14200000 product:sltexx model:SM_G850F device:slte
4366432135f271c6       device usb:14200000 product:sltexx model:SM_G9901 device:slte
emulator-5554          device product:sdk_phone_x86_64 model:Android_SDK_built_for_x86_64 device:generic_x86_64

To run against just the emulator: -f emulator
To run against a device id list: -f 4100142545f271b5,4366432135f271c6

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
