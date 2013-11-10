Elevate
======

Are you suffering from symptoms of Massive View Controller?

Use Elevate to elegantly decompose tasks, and give your view controller a break.

[![Code Climate](https://codeclimate.com/github/mattgreen/elevate.png)](https://codeclimate.com/github/mattgreen/elevate) [![Travis](https://api.travis-ci.org/mattgreen/elevate.png)](https://travis-ci.org/mattgreen/elevate) [![Gem Version](https://badge.fury.io/rb/elevate.png)](http://badge.fury.io/rb/elevate)


Introduction
------------
Your poor, poor view controllers. They do **so** much for you, and they get rewarded with *even more* responsibilities:

* Handle user input
* Update the UI in response to that input
* Request data from web services
* Load/save/query your model layer

In reality, view controllers attract complexity because they often act as a conceptual junk drawer of glue code. Fat controllers are major anti-pattern in Rails, yet iOS controllers are tasked with even more concerns.

Elevate is your view controller's best friend, shouldering some of these burdens. It cleanly separates the unique behavior of your view controller (that is, what it is actually *meant* to do) from the above concerns, letting your view controller breathe more. Ultimately, Elevate makes your view controllers easier to understand and modify.

This is a rather bold claim. Let's look at an example:

```ruby
class ArtistsViewController < UIViewController
  include Elevate

  def viewDidLoad
    super

    launch(:update)
  end

  task :update do
    background do
      response = Elevate::HTTP.get("https://example.org/artists")
      DB.update(response)

      response
    end

    on_start do
      SVProgressHUD.showWithStatus("Loading...")
    end

    on_finish do |response, exception|
      SVProgressHUD.dismiss

      self.artists = response
    end
  end
end
```

We define a task named `update`. Within that task, we specify the work that it does using the `background` method of the DSL. As the name implies, this block runs on a background thread. Next, we specify two callback handlers: `on_start` and `on_finish`. These are run when the task starts and finishes, respectively. Because these are alwys run on the main thread, you can use them to update the UI. Finally, in `viewDidLoad`, we start the task by calling `launch`, passing the name of the task.

Notice that it is very clear what the actual work of the `update` task is: getting a list of artists from a web service, storing the results in a database, and passing the list of artists back. Thus, you should view Elevate as a DSL for a *very* common pattern for view controllers:

1. Update the UI, telling the user you're starting some work
2. Do the work (possibly storing it in a database)
3. Update the UI again in response to what happened

(Some tasks may not need steps 1 or 3, of course.)

Taming Complexity
--------
You may have thought that Elevate seemed a bit heavy for the example code. I'd agree with you.

Elevate was actually designed to handle the more complex interactions within a view controller:

* **Async HTTP**: Elevate's HTTP client blocks, letting you write simple, testable I/O. Multiple HTTP requests do not suffer from the Pyramid of Doom effect, allowing you to easily understand dataflow. It also benefits from...
* **Cancellation**: tasks may be aborted while they are running. (Any in-progress HTTP request is aborted.)
* **Errors**: exceptions raised in a `background` block are reported to a callback, much like `on_finish`. Specific callbacks may be defined to handle specific exceptions.
* **Timeouts**: tasks may be defined to only run for a maximum amount of time, after which they are aborted, and a callback is invoked.

The key point here is that defining a DSL for tasks enables us to **abstract away tedious and error-prone** functionality that is common to many view controllers, and necessary for a great user experience. Why re-write this code over and over?

Documentation
--------
To learn more:

- [Tutorial](https://github.com/mattgreen/elevate/wiki/Tutorial) - start here

- [Wiki](https://github.com/mattgreen/elevate/wiki)

Requirements
------------

- iOS 5 and up or OS X

- RubyMotion 2.x - Elevate pushes the limits of RubyMotion. Please ensure you have the latest version before reporting bugs!

Installation
------------
Update your Gemfile:

    gem "elevate", "~> 0.7.0"

Bundle:

    $ bundle install

Inspiration
-----------
This method of organizing work recurs on several platforms, due to its effectiveness. I've stolen many ideas from these sources:

* [Hexagonal Architecture](http://alistair.cockburn.us/Hexagonal+architecture)
* Android: [AsyncTask](http://developer.android.com/reference/android/os/AsyncTask.html)
* .NET: BackgroundWorker
* Go's goroutines for simplifying asynchronous I/O

License
---------
MIT License

