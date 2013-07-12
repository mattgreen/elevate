Elevate
======

Stop scattering your domain logic across your view controller. Consolidate it to a single conceptual unit with Elevate.

[![Code Climate](https://codeclimate.com/github/mattgreen/elevate.png)](https://codeclimate.com/github/mattgreen/elevate) [![Travis](https://api.travis-ci.org/mattgreen/elevate.png)](https://travis-ci.org/mattgreen/elevate) [![Gem Version](https://badge.fury.io/rb/elevate.png)](http://badge.fury.io/rb/elevate)

Example
-------

```ruby
@login_task = async username: username.text, password: password.text do
  # This block runs on a background thread.
  task do
    # @username and @password correspond to the Hash keys provided to async.
    args = { username: @username, password: @password }

    credentials = Elevate::HTTP.post(LOGIN_URL, args)
    if credentials
      UserRegistration.store(credentials.username, credentials.token)
    end

    # Anything yielded from this block is passed to on_update
    yield "Logged in!"

    # Return value of block is passed back to on_finish
    credentials != nil
  end

  on_start do
    # This block runs on the UI thread after the operation has been queued.
    SVProgressHUD.showWithStatus("Logging In...")
  end

  on_update do |status|
    # This block runs on the UI thread with anything the task yields
    puts status
  end

  on_finish do |result, exception|
    # This block runs on the UI thread after the task block has finished.
    SVProgressHUD.dismiss

    if exception == nil
      if result
        alert("Logged in successfully!")
      else
        alert("Invalid username/password!")
      end
    else
      alert(exception)
    end
  end
end
```

Background
-----------
Many iOS/OS X apps have fairly simple domain logic that is obscured by several programming 'taxes':

* UI management
* asynchronous network requests
* I/O-heavy operations, such as storing large datasets to disk

These are necessary to ensure a good user experience, but they splinter your domain logic (that is, what your application does) through your view controller. Gross.

Elevate is a mini task queue for your app, much like Resque or Sidekiq. Rather than defining part of an operation to run on the UI thread, and a CPU-intensive portion on a background thread, Elevate is designed so you run the *entire* operation in the background, and receive notifications at various times. This has a nice side effect of consolidating all the interaction for a particular task to one place. The UI code is cleanly isolated from the non-UI code. When your tasks become complex, you can elect to extract them out to a service object.

In a sense, Elevate is almost a control-flow library: it bends the rules of app development a bit to ensure that the unique value your application provides is as clear as possible.

Documentation
--------
- [Tutorial](https://github.com/mattgreen/elevate/wiki/Tutorial) - start here

- [Wiki](https://github.com/mattgreen/elevate/wiki)

Installation
------------
Update your Gemfile:

    gem "elevate", "~> 0.6.0"

Bundle:

    $ bundle install

Usage
-----

Include the module in your view controller:

```ruby
class ArtistsSearchViewController < UIViewController
  include Elevate
```

Launch an async task with the `async` method:
```ruby
@track_task = async artist: searchBar.text do
  task do
    response = Elevate::HTTP.get("http://example.com/artists", query: { artist: @artist })

    artist = Artist.from_hash(response)
    ArtistDB.update(artist)

    response["name"]
  end

  on_start do
    SVProgressHUD.showWithStatus("Adding...")
  end

  on_finish do |result, exception|
    SVProgressHUD.dismiss
  end
end
```

If you might need to cancel the task later, call `cancel` on the object returned by `async`:
```ruby
@track_task.cancel
```

Timeouts
--------
Elevate 0.6.0 includes support for timeouts. Timeouts are declared using the `timeout` method within the `async` block. They start when an operation is queued, and automatically abort the task when the duration passes. If the task takes longer than the specified duration, the `on_timeout` callback is run.

Example:

```ruby
async do
  timeout 0.1

  task do
    Elevate::HTTP.get("http://example.com/")
  end

  on_timeout do
    puts 'timed out'
  end

  on_finish do |result, exception|
    puts 'completed!'
  end
end


```

Caveats
---------
* Must use Elevate's HTTP client instead of other iOS networking libs

Inspiration
-----------
* [Hexagonal Architecture](http://alistair.cockburn.us/Hexagonal+architecture)
* [Android SDK's AsyncTask](http://developer.android.com/reference/android/os/AsyncTask.html)
* Go (asynchronous IO done correctly)

License
---------
MIT License

