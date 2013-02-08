Elevate
======
How do we convey the intent of our application?

**Status:** beta quality. Feedback desired!

Background
-----------
iOS applications employ the MVC architecture to delineate responsibilities:

* Models represent the entities important to our app
* Views display those entities
* Controllers react to user input, adjusting the model

However, iOS view controllers seem to attract complexity: not only do they coordinate models, but they also coordinate boundary objects (persistence mechanisms, backend APIs) and view-related concerns. This conflation of responsibilities shrouds the domain logic (that is, what your application does), making it harder to reason about and test. Pure model-related logic can be tested easily on its own, the difficulty arises when models interact with boundaries. Asynchronous behavior only makes it worse.

Elevate posits that the essence of your system are the use cases. They constitute the unique value that your application delivers. Their correctness is too important to be mixed in with presentation-level concerns. This results in a bit more code (one class per use case), but it allows the view controller to be relentlessly focused on view-related concerns.

Extracting use cases into their own class has several benefits:

* Consolidates domain and boundary interactions (read: all non-UI code) to a single conceptual unit
* Clarifies the intent of the code, both within the view controller and the use case
* Simplifies IO within the use case, allowing it feel blocking, while remaining interruptible (see below)
* Eases testing, allow you to employ either mock-based tests or acceptance tests

Implementation
--------------
Use cases are executed one at a time in a single, global `NSOperationQueue`. Each use case invocation is contained within a `NSOperation` subclass called `ElevateOperation`. `ElevateOperation` sets up an execution environment enabling compliant IO libraries to use traditional blocking control flows, rather than the traditional asynchronous style employed by iOS. Calls may be interrupted by invoking `cancel` on the `ElevateOperation`, triggering a `CancelledError` to be raised within the use case.

The `Elevate::HTTP` module wraps NSURLRequest to work with this control flow. (Unfortunately, most iOS HTTP libraries do not work well with this paradigm.)

Example
------------
Synchronizing data between a remote API and a local DB:

```ruby
class SyncArtists < Action
  def execute
    stale_artists.each do |stale_artist|
      artist = api.get_artist(stale_artist.name)
      tracked_artists.add(artist)
    end

    tracked_artists.all
  end

  private
  def stale_artists
    stale = []

    current = api.get_artists()
    current.each do |artist|
      if stale?(artist)
        stale << artist
      end
    end

    stale
  end

  def stale?(artist)
    existing = tracked_artists.find_by_name(artist.name)
    if existing.nil?
      return true
    end

    existing.updated_at < artist.updated_at
  end
end
```

Notice the use case (`SyncArtists`) describes the algorithm at a high level. It is not concerned with the UI, and it depends on abstractions. 

The view controller retains a similar focus. In fact, it is completely ignorant of how the sync algorithm operates. It only knows that it will return a list of artists to display:

```ruby
class ArtistsViewController < UITableViewController
  include Elevate

  def artists
    @artists ||= []
  end

  def artists=(artists)
    @artists = artists
    view.reloadData()
  end

  def viewWillAppear(animated)
    super

    async SyncArtists.new do
      on_completed do |operation|
        self.artists = operation.result
      end
    end
  end
end
```

Requirements
------------
* **iOS 6.x and higher** (due to `setDelegateQueue` being [horribly broken](http://openradar.appspot.com/10529053) on iOS 5.x.)

Installation
------------
Update your Gemfile:

    gem "elevate", "~> 0.3.0"

Bundle:

    $ bundle install

Usage
-----

Write a use case. Use case classes must respond to `execute`. Anything returned from `execute` is made available to the controller callbacks:
```ruby
class TrackArtist < Action
  def initialize(artist_name)
    @artist_name = artist_name
  end

  def execute
    unless registration.completed?
      user = api.register()
      registration.save(user)
    end

    artist = api.track(@artist_name)
    tracked_artists.add(artist)

    artist
  end
end
```

Include the module in your view controller:

```ruby
class ArtistsSearchViewController < UIViewController
  include Elevate
```

Execute a use case:

```ruby
async TrackArtist.new(artist_name) do
  on_started do |operation|
    SVProgressHUD.showWithStatus("Adding...", maskType:SVProgressHUDMaskTypeGradient)
  end

  # operation.result contains the return value of #execute
  # operation.exception contains the raised exception (if any)
  on_completed do |operation|
    SVProgressHUD.dismiss()
  end
end
```

Caveats
---------
* **DSL is not finalized**
* Sending CoreData entities across threads is dangerous
* The callback DSL is clunky to try to avoid retain issues
* Must use Elevate's HTTP client instead of other iOS networking libs
* No way to report progress (idea: `execute` could yield status information via optional block)

Inspiration
-----------
* [PoEAA: Transaction Script](http://martinfowler.com/eaaCatalog/transactionScript.html)
* [The Clean Architecture](http://blog.8thlight.com/uncle-bob/2012/08/13/the-clean-architecture.html)
* [Hexagonal Architecture](http://alistair.cockburn.us/Hexagonal+architecture)
* [Architecture: The Lost Years](http://www.youtube.com/watch?v=WpkDN78P884)
* [Android SDK's AsyncTask](http://developer.android.com/reference/android/os/AsyncTask.html)
* Go (asynchronous IO done correctly)

License
---------
MIT License
