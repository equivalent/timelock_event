# TimelockEvent

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pobble/timelock_event'
```

And then execute:

    $ bundle

## Usage

Given you have a Ruby on Rails application with Active Job
Given you use [redis rb](https://github.com/redis/redis-rb) client:

```ruby
# app/jobs/import_songs_job.rb

require "redis"

class ImportSongsJob < ActiveJob::Base
  queue_as :default

  def self.timelocker
    @timelocker ||= begin
      config = TimelockEvent::Config.new
      config.redis_connection = Redis.new(host: 'localhost') # connection to your application Redis
      config.unlock_hour_window = 2..3         # between 2 AM and 3 Am
      config.lock_for = 24.hours               # lock for 24 hours
      config.key = 'TimeLockEventImportSongs'  # redis key for this locker

      TimelockEvent.new(config: config)
    end
  end

  def perform
    body = HTTParty.get('http://my-song-domain.com/user/1234')
    JSON.parse(body).each do |song|
      # ....
    end
  end
end
```

```ruby
# app/controllers/maintenance_controller.rb
class MaintenanceController < ActionController::Metal    # really slim Rails enviroment for your controller
  include AbstractController::Rendering
  include ActionView::Layouts

  def pull_songs
    ImportSongsJob.timelocker.transaction do
      ImportSongsJob.perform_later
    end

    render text: "ok"
  end
end
```

```ruby
# config/routes.rb
Rails.application.routes.draw do
  get '/maintenance/pull_songs' => "maintenance#pull_songs"
end
```

Now your endpoint will `/maintenance/pull_songs` will schedule your task
only if it receives request in given timeframe (in this case 2 AM - 3 AM)

You can configure [request repeater](https://github.com/Pobble/request_repeater) to tak care of it.

## Developing & Testing

git clone this repo and run tests:

```
TEST_REDIS_HOST=localhost rake

# .. or
TEST_REDIS_HOST=localhost TEST_REDIS_PORT=6379 TEST_REDIS_PORT=0 rake

# ..or

TEST_REDIS_HOST=localhost rspec spec/timelock_event_spec.rb
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/equivalent/timelock_event. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

