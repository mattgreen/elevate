Elevate
======

Stop scattering your domain logic across your view controller. Consolidate it to a single conceptual unit with Elevate.

[![Code Climate](https://codeclimate.com/github/mattgreen/elevate.png)](https://codeclimate.com/github/mattgreen/elevate) [![Travis](https://api.travis-ci.org/mattgreen/elevate.png)](https://travis-ci.org/mattgreen/elevate)

Example
-------

```ruby
@login_task = async username: username.text, password: password.text do
  task do
    # This block runs on a background thread.
    #
    # The @username and @password instance variables correspond to the args
    # passed into async. API is a thin wrapper class over Elevate::HTTP,
    # which blocks until the request returns, yet can be interrupted.
    credentials = API.login(@username, @password)
    if credentials
      UserRegistration.store(credentials.username, credentials.token)
    end

    # Return value of block is passed back to on_completed
    credentials != nil
  end

  on_started do
    # This block runs on the UI thread after the operation has been queued.
    SVProgressHUD.showWithStatus("Logging In...")
  end

  on_completed do |result, exception|
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
Many iOS apps have fairly simple domain logic that is obscured by several programming 'taxes':

* UI management
* asynchronous network requests
* I/O-heavy operations, such as storing large datasets to disk

These are necessary to ensure a good user experience, but they splinter your domain logic (that is, what your application does) through your view controller. Gross.

Elevate is a mini task queue for your iOS app, much like Resque or Sidekiq. Rather than defining part of an operation to run on the UI thread, and a CPU-intensive portion on a background thread, Elevate is designed so you run the *entire* operation in the background, and receive notifications when it starts and finishes. This has a nice side effect of consolidating all the interaction for a particular task to one place. The UI code is cleanly isolated from the non-UI code. When your tasks become complex, you can elect to extract them out to a service object.

In a sense, Elevate is almost a control-flow library: it bends the rules of iOS development a bit to ensure that the unique value your application provides is as clear as possible. This is most apparent with how Elevate handles network I/O: it provides a blocking HTTP client built from NSURLRequest for use within your tasks. This lets you write your tasks in a simple, blocking manner, while letting Elevate handle concerns relating to cancellation, and errors. 

Features
--------

* Small, beautiful DSL for describing your tasks
* Actor-style concurrency
* Simplifies asynchronous HTTP requests when used with Elevate::HTTP
* Built atop of NSOperationQueue

Installation
------------
Update your Gemfile:

    gem "elevate", "~> 0.4.0"

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

* Pass all the data the task needs to operate (such as credentials or search terms) in to the `async` method.
* Define a block that contains a `task` block. The `task` block should contain all of your non-UI code. It will be run on a background thread. Any data passed into the `async` method will be available as instance variables, keyed by the provided hash key.
* Optionally, define `on_started` and `on_completed` blocks to run as the task starts and finishes. These are run in the UI thread, and should contain all of your UI code.

```ruby
@track_task = async artist: searchBar.text do
  task do
    artist = API.track(@artist)
    ArtistDB.update(artist)
  end

  on_started do
    SVProgressHUD.showWithStatus("Adding...")
  end

  on_completed do |result, exception|
    SVProgressHUD.dismiss
  end
end
```

To cancel a task (like when the view controller is being dismissed), call `cancel` on the task returned by the `async` method. This causes a `CancelledError` to be raised within the task itself, which is handled by the Elevate runtime. This also prevents any callbacks you have defined from running.

**NOTE: Within tasks, do not access the UI or containing view controller! It is extremely dangerous to do so. You must pass data into the `async` method to use it safely.**

To Do
-----
* Need ability to set timeout for tasks
* More thought on the semantics

Caveats
---------
* Must use Elevate's HTTP client instead of other iOS networking libs
* No way to report progress (idea: `execute` could yield status information via optional block)

Inspiration
-----------
* [Hexagonal Architecture](http://alistair.cockburn.us/Hexagonal+architecture)
* [Android SDK's AsyncTask](http://developer.android.com/reference/android/os/AsyncTask.html)
* Go (asynchronous IO done correctly)

License
---------
MIT License

