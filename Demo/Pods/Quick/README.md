![](http://f.cl.ly/items/0r1E192C1R0b2g2Q3h2w/QuickLogo_Color.png)

Quick is a behavior-driven development framework for Swift and Objective-C.
Inspired by [RSpec](https://github.com/rspec/rspec), [Specta](https://github.com/specta/specta), and [Ginkgo](https://github.com/onsi/ginkgo).

[![Build Status](https://travis-ci.org/Quick/Quick.svg)](https://travis-ci.org/Quick/Quick)

![](https://raw.githubusercontent.com/Quick/Assets/master/Screenshots/QuickSpec%20screenshot.png)

```swift
// Swift

import Quick
import Nimble

class TableOfContentsSpec: QuickSpec {
  override func spec() {
    describe("the table of contents below") {
      it("has everything you need to get started") {
        let sections = TableOfContents().sections
        expect(sections).to(contain("Quick: Examples and Example Groups"))
        expect(sections).to(contain("Nimble: Assertions using expect(...).to"))
        expect(sections).to(contain("How to Install Quick"))
      }

      context("if it doesn't have what you're looking for") {
        it("needs to be updated") {
          let you = You(awesome: true)
          expect{you.submittedAnIssue}.toEventually(beTruthy())
        }
      }
    }
  }
}
```

# How to Use Quick

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Quick: Examples and Example Groups](#quick-examples-and-example-groups)
  - [Examples Using `it`](#examples-using-it)
  - [Example Groups Using `describe` and `context`](#example-groups-using-describe-and-context)
    - [Describing Classes and Methods Using `describe`](#describing-classes-and-methods-using-describe)
    - [Sharing Setup/Teardown Code Using `beforeEach` and `afterEach`](#sharing-setupteardown-code-using-beforeeach-and-aftereach)
    - [Specifying Conditional Behavior Using `context`](#specifying-conditional-behavior-using-context)
  - [Temporarily Disabling Examples or Groups Using `pending`](#temporarily-disabling-examples-or-groups-using-pending)
    - [Shorthand syntax](#shorthand-syntax)
  - [Global Setup/Teardown Using `beforeSuite` and `afterSuite`](#global-setupteardown-using-beforesuite-and-aftersuite)
  - [Sharing Examples](#sharing-examples)
- [Using Quick in Objective-C: The Optional Shorthand Syntax](#using-quick-in-objective-c-the-optional-shorthand-syntax)
  - [Caveat: Your Test Target Must Include At Least One Swift File](#caveat-your-test-target-must-include-at-least-one-swift-file)
- [Nimble: Assertions Using `expect(...).to`](#nimble-assertions-using-expectto)
- [Testing UIKit with Quick](#testing-uikit-with-quick)
- [How to Install Quick](#how-to-install-quick)
  - [1. Clone the Quick and Nimble repositories](#1-clone-the-quick-and-nimble-repositories)
  - [2. Add `Quick.xcodeproj` and `Nimble.xcodeproj` to your test target](#2-add-quickxcodeproj-and-nimblexcodeproj-to-your-test-target)
  - [3. Link `Quick.framework` and `Nimble.framework`](#3-link-quickframework-and-nimbleframework)
  - [4. Start writing specs!](#4-start-writing-specs!)
- [Including Quick in a Git Repository Using Submodules](#including-quick-in-a-git-repository-using-submodules)
  - [Adding Quick as a Git Submodule](#adding-quick-as-a-git-submodule)
  - [Updating the Quick Submodule](#updating-the-quick-submodule)
  - [Cloning a Repository that Includes a Quick Submodule](#cloning-a-repository-that-includes-a-quick-submodule)
- [How to Install Quick File Templates](#how-to-install-quick-file-templates)
  - [Using Alcatraz](#using-alcatraz)
  - [Manually via the Rakefile](#manually-via-the-rakefile)
- [Who Uses Quick](#who-uses-quick)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Quick: Examples and Example Groups

Quick uses a special syntax to define **examples** and **example groups**.

### Examples Using `it`

Examples, defined with the `it` function, use assertions to demonstrate
how code should behave. These are like "tests" in XCTest.

`it` takes two parameters: the name of the example, and a closure.
The examples below specify how the `Dolphin` class should behave.
A new dolphin should be smart and friendly:

```swift
// Swift

import Quick
import Nimble

class DolphinSpec: QuickSpec {
  override func spec() {
    it("is friendly") {
      expect(Dolphin().isFriendly).to(beTruthy())
    }

    it("is smart") {
      expect(Dolphin().isSmart).to(beTruthy())
    }
  }
}
```

```objc
// Objective-C

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>

QuickSpecBegin(DolphinSpec)

it(@"is friendly", ^{
  expect(@([[Dolphin new] isFriendly])).to(beTruthy());
});

it(@"is smart", ^{
  expect(@([[Dolphin new] isSmart])).to(beTruthy());
});

QuickSpecEnd
```

> Descriptions can use any character, including characters from languages
  besides English, or even emoji! :v: :sunglasses:

### Example Groups Using `describe` and `context`

Example groups are logical groupings of examples. Example groups can share
setup and teardown code.

#### Describing Classes and Methods Using `describe`

To specify the behavior of the `Dolphin` class's `click` method--in
other words, to test the method works--several `it` examples can be
grouped together using the `describe` function. Grouping similar
examples together makes the spec easier to read:

```swift
// Swift

import Quick
import Nimble

class DolphinSpec: QuickSpec {
  override func spec() {
    describe("a dolphin") {
      describe("its click") {
        it("is loud") {
          let click = Dolphin().click()
          expect(click.isLoud).to(beTruthy())
        }

        it("has a high frequency") {
          let click = Dolphin().click()
          expect(click.hasHighFrequency).to(beTruthy())
        }
      }
    }
  }
}
```

```objc
// Objective-C

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>

QuickSpecBegin(DolphinSpec)

describe(@"a dolphin", ^{
  describe(@"its click", ^{
    it(@"is loud", ^{
      Click *click = [[Dolphin new] click];
      expect(@(click.isLoud)).to(beTruthy());
    });

    it(@"has a high frequency", ^{
      Click *click = [[Dolphin new] click];
      expect(@(click.hasHighFrequency)).to(beTruthy());
    });
  });
});

QuickSpecEnd
```

#### Sharing Setup/Teardown Code Using `beforeEach` and `afterEach`

Example groups don't just make the examples clearer, they're also useful
for sharing setup and teardown code among examples in a group.

In the example below, the `beforeEach` function is used to create a brand
new instance of a dolphin and its click before each example in the group.
This ensures that both are in a "fresh" state for every example:

```swift
// Swift

import Quick
import Nimble

class DolphinSpec: QuickSpec {
  override func spec() {
    describe("a dolphin") {
      var dolphin: Dolphin?
      beforeEach {
        dolphin = Dolphin()
      }

      describe("its click") {
        var click: Click?
        beforeEach {
          click = dolphin!.click()
        }

        it("is loud") {
          expect(click!.isLoud).to(beTruthy())
        }

        it("has a high frequency") {
          expect(click!.hasHighFrequency).to(beTruthy())
        }
      }
    }
  }
}
```

```objc
// Objective-C

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>

QuickSpecBegin(DolphinSpec)

describe(@"a dolphin", ^{
  __block Dolphin *dolphin = nil;
  beforeEach(^{
      dolphin = [Dolphin new];
  });

  describe(@"its click", ^{
    __block Click *click = nil;
    beforeEach(^{
      click = [dolphin click];
    });

    it(@"is loud", ^{
      expect(@(click.isLoud)).to(beTruthy());
    });

    it(@"has a high frequency", ^{
      expect(@(click.hasHighFrequency)).to(beTruthy());
    });
  });
});

QuickSpecEnd
```

Sharing setup like this might not seem like a big deal with the
dolphin example, but for more complicated objects, it saves a lot
of typing!

To execute code *after* each example, use `afterEach`.

#### Specifying Conditional Behavior Using `context`

Dolphins use clicks for echolocation. When they approach something
particularly interesting to them, they release a series of clicks in
order to get a better idea of what it is.

The tests need to show that the `click` method behaves differently in
different circumstances. Normally, the dolphin just clicks once. But when
the dolphin is close to something interesting, it clicks several times.

This can be expressed using `context` functions: one `context` for the
normal case, and one `context` for when the dolphin is close to
something interesting:

```swift
// Swift

import Quick
import Nimble

class DolphinSpec: QuickSpec {
  override func spec() {
    describe("a dolphin") {
      var dolphin: Dolphin?
      beforeEach { dolphin = Dolphin() }

      describe("its click") {
        context("when the dolphin is not near anything interesting") {
          it("is only emitted once") {
            expect(dolphin!.click().count).to(equal(1))
          }
        }

        context("when the dolphin is near something interesting") {
          beforeEach {
            let ship = SunkenShip()
            Jamaica.dolphinCove.add(ship)
            Jamaica.dolphinCove.add(dolphin)
          }

          it("is emitted three times") {
            expect(dolphin!.click().count).to(equal(3))
          }
        }
      }
    }
  }
}
```

```objc
// Objective-C

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>

QuickSpecBegin(DolphinSpec)

describe(@"a dolphin", ^{
  __block Dolphin *dolphin = nil;
  beforeEach(^{ dolphin = [Dolphin new]; });

  describe(@"its click", ^{
    context(@"when the dolphin is not near anything interesting", ^{
      it(@"is only emitted once", ^{
        expect(@([[dolphin click] count])).to(equal(@1));
      });
    });

    context(@"when the dolphin is near something interesting", ^{
      beforeEach(^{
        [[Jamaica dolphinCove] add:[SunkenShip new]];
        [[Jamaica dolphinCove] add:dolphin];
      });

      it(@"is emitted three times", ^{
        expect(@([[dolphin click] count])).to(equal(@3));
      });
    });
  });
});

QuickSpecEnd
```

### Temporarily Disabling Examples or Groups Using `pending`

For examples that don't pass yet, use `pending`. Pending examples
are not run, but are printed out along with the test results.

The example below marks the cases in which the dolphin is close to
something interesting as "pending"--perhaps that functionality hasn't
been implemented yet, but these tests have been written as reminders
that it should be soon:

```swift
// Swift

pending("when the dolphin is near something interesting") {
  // ...none of the code in this closure will be run.
}
```

```objc
// Objective-C

pending(@"when the dolphin is near something interesting", ^{
  // ...none of the code in this closure will be run.
});
```

#### Shorthand syntax

Examples and groups can also be marked as pending by using
`xdescribe`, `xcontext`, and `xit`:

```swift
// Swift

xdescribe("its click") {
  // ...none of the code in this closure will be run.
}

xcontext("when the dolphin is not near anything interesting") {
  // ...none of the code in this closure will be run.
}

xit("is only emitted once") {
  // ...none of the code in this closure will be run.
}
```

```objc
// Objective-C

xdescribe(@"its click", ^{
  // ...none of the code in this closure will be run.
});

xcontext(@"when the dolphin is not near anything interesting", ^{
  // ...none of the code in this closure will be run.
});

xit(@"is only emitted once", ^{
  // ...none of the code in this closure will be run.
});
```

### Global Setup/Teardown Using `beforeSuite` and `afterSuite`

Some test setup needs to be performed before *any* examples are
run. For these cases, use `beforeSuite` and `afterSuite`.

In the example below, a database of all the creatures in the ocean is
created before any examples are run. That database is torn down once all
the examples have finished:

```swift
// Swift

import Quick

class DolphinSpec: QuickSpec {
  override func spec() {
    beforeSuite {
      OceanDatabase.createDatabase(name: "test.db")
      OceanDatabase.connectToDatabase(name: "test.db")
    }

    afterSuite {
      OceanDatabase.teardownDatabase(name: "test.db")
    }

    describe("a dolphin") {
      // ...
    }
  }
}
```

```objc
// Objective-C

#import <Quick/Quick.h>

QuickSpecBegin(DolphinSpec)

beforeSuite(^{
  [OceanDatabase createDatabase:@"test.db"];
  [OceanDatabase connectToDatabase:@"test.db"];
});

afterSuite(^{
  [OceanDatabase teardownDatabase:@"test.db"];
});

describe(@"a dolphin", ^{
  // ...
});

QuickSpecEnd
```

> You can specify as many `beforeSuite` and `afterSuite` as you like. All
  `beforeSuite` closures will be executed before any tests run, and all
  `afterSuite` closures will be executed after all the tests are finished.
  There is no guarantee as to what order these closures will be executed in.

### Sharing Examples

In some cases, the same set of specifications apply to multiple objects.

For example, consider a protocol called `Edible`. When a dolphin
eats something `Edible`, the dolphin becomes happy. `Mackerel` and
`Cod` are both edible. Quick allows you to easily test that a dolphin is
happy to eat either one.

The example below defines a set of  "shared examples" for "something edible",
and specifies that both mackerel and cod behave like "something edible":

```swift
// Swift

import Quick
import Nimble

class EdibleSharedExamplesConfiguration: QuickConfiguration {
  override class func configure(configuration: Configuration) {
    sharedExamples("something edible") { (sharedExampleContext: SharedExampleContext) in
      it("makes dolphins happy") {
        let dolphin = Dolphin(happy: false)
        let edible = sharedExampleContext()["edible"]
        dolphin.eat(edible)
        expect(dolphin.isHappy).to(beTruthy())
      }
    }
  }
}

class MackerelSpec: QuickSpec {
  override func spec() {
    var mackerel: Mackerel! = nil
    beforeEach {
      mackerel = Mackerel()
    }

    itBehavesLike("something edible") { ["edible": mackerel] }
  }
}

class CodSpec: QuickSpec {
  override func spec() {
    var cod: Cod! = nil
    beforeEach {
      cod = Cod()
    }

    itBehavesLike("something edible") { ["edible": cod] }
  }
}
```

```objc
// Objective-C

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>

QuickConfigurationBegin(EdibleSharedExamplesConfiguration)

+ (void)configure:(Configuration *configuration) {
  sharedExamples(@"something edible", ^(QCKDSLSharedExampleContext exampleContext) {
    it(@"makes dolphins happy") {
      Dolphin *dolphin = [[Dolphin alloc] init];
      dolphin.happy = NO;
      id<Edible> edible = exampleContext()[@"edible"];
      [dolphin eat:edible];
      expect(dolphin.isHappy).to(beTruthy())
    }
  });
}

QuickConfigurationEnd

QuickSpecBegin(MackerelSpec)

__block Mackerel *mackerel = nil;
beforeEach(^{
  mackerel = [[Mackerel alloc] init];
});

itBehavesLike(@"someting edible", ^{ return @{ @"edible": mackerel }; });

QuickSpecEnd

QuickSpecBegin(CodSpec)

__block Mackerel *cod = nil;
beforeEach(^{
  cod = [[Cod alloc] init];
});

itBehavesLike(@"someting edible", ^{ return @{ @"edible": cod }; });

QuickSpecEnd
```

Shared examples can include any number of `it`, `context`, and
`describe` blocks. They save a *lot* of typing when running
the same tests against several different kinds of objects.

In some cases, you won't need any additional context. In Swift, you can
simply use `sharedExampleFor` closures that take no parameters. This
might be useful when testing some sort of global state:

```swift
// Swift

import Quick

sharedExamplesFor("everything under the sea") {
  // ...
}

itBehavesLike("everything under the sea")
```

> In Objective-C, you'll have to pass a block that takes a
  `QCKDSLSharedExampleContext`, even if you don't plan on using that
  argument. Sorry, but that's the way the cookie crumbles!
  :cookie: :bomb:

## Using Quick in Objective-C: The Optional Shorthand Syntax

Quick works equally well in both Swift and Objective-C.

Importing Quick in an Objective-C file defines macros named `it` and
`itShouldBehaveLike`, as well as functions like `context()`, `describe()`, etc.
If the project you are testing also defines symbols with these names, you may
encounter confusing build failures. In that case, you can avoid namespace
collision by turning off Quick's optional "shorthand" syntax:

```objc
#define QUICK_DISABLE_SHORT_SYNTAX 1

#import <Quick/Quick.h>

QuickSpecBegin(DolphinSpec)
// ...
QuickSpecEnd
```

You must define the `QUICK_DISABLE_SHORT_SYNTAX` macro *before*
importing the Quick header.

### Caveat: Your Test Target Must Include At Least One Swift File

The Swift stdlib will not be linked into your test target, and thus
Quick will fail to execute properly, if you test target does not contain
*at least one* Swift file. If it does not, your tests will exit
prematurely with the following error:

```
*** Test session exited(82) without checking in. Executable cannot be
loaded for some other reason, such as a problem with a library it
depends on or a code signature/entitlements mismatch.
```

To fix the problem, add a blank file called `SwiftSpec.swift` to your test target:

```swift
// SwiftSpec.swift

import Quick
```

> For more details on this issue, see https://github.com/Quick/Quick/issues/164.

## Nimble: Assertions Using `expect(...).to`

Quick provides an easy language to define examples and example groups. Within those
examples, [Nimble](https://github.com/Quick/Nimble) provides a simple
language to define expectations--that is, to assert that code behaves a
certain way, and to display a test failure if it doesn't.

Nimble expectations use the `expect(...).to` syntax:

```swift
// Swift

import Nimble

expect(person.greeting).to(equal("Oh, hi."))
expect(person.greeting).notTo(equal("Hello!"))
expect(person.isHappy).toEventually(beTruthy())
```

```objc
// Objective-C

#import <Nimble/Nimble.h>

expect(person.greeting).to(equal(@"Oh, hi."));
expect(person.greeting).notTo(equal(@"Hello!"));
expect(@(person.isHappy)).toEventually(beTruthy());
```

You can find much more detailed documentation on
[Nimble](https://github.com/Quick/Nimble), including a
full set of available matchers and details on how to perform asynchronous tests,
in [the project's README](https://github.com/Quick/Nimble).

## Testing UIKit with Quick

Quick can be used for testing UIKit interaction as well. Say, for example, we have a `DolphinTableViewController` that displays one cell with label `Bottlenose`. We want to test that the cell gets displayed when the view is loaded. Additionally, we would like to delete the row upon selecting it. An approach might be:

```swift
// Swift

import UIKit
import Quick
import Nimble

class DolphinTableViewControllerSpecs: QuickSpec {
  override func spec() {
    var viewController: DolphinTableViewController!

    beforeEach {
      viewController = DolphinTableViewController()
    }

    describe("viewDidLoad") {
      beforeEach {
        // Accessing the view property causes the UIKit framework to trigger the necessary methods to render the view.
        viewController.view
      }


      it("loads the table view with one cell") {
        let tableView = viewController.tableView

        var indexPath = NSIndexPath(forRow: 0, inSection: 0)
        var cell = viewController.tableView(tableView, cellForRowAtIndexPath: indexPath)

        expect(cell.textLabel?.text).to(equal("Bottlenose"))
      }
    }

    describe("didSelectRowAtIndexPath") {
      beforeEach {
        // Causes the UIKit framework to trigger the necessary methods to render the view and perform viewWillAppear: and viewDidAppear: callbacks
        viewController.beginAppearanceTransition(true, animated: false)
        viewController.endAppearanceTransition()
      }

      it("deletes the selected row and reloads the tableView's data") {
        let tableView = viewController.tableView
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)

        viewController.tableView(tableView, didSelectRowAtIndexPath: indexPath)

        var cell = viewController.tableView(tableView, cellForRowAtIndexPath: indexPath)
        expect(cell.textLabel?.text).to(beNil())
      }
    }
  }
}
```

```objc
// Objective-C

#import <UIKit/UIKit.h>
#import <Quick/Quick.h>
#import <Nimble/Nimble.h>

QuickSpecBegin(DolphinTableViewControllerSpec)

describe(@"viewDidLoad") {
  __block DolphinTableViewController *viewController = nil;

  beforeEach(^{
    viewController = [[DolphinTableViewController alloc] init];
  });

  it(@"loads the table view with three types of dolphin", ^{
    beforeEach(^{
      // Accessing the view property causes the UIKit framework to trigger the necessary methods to render the view.
      [viewController view];
    });

    UITableView *tableView = [viewController tableView];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewCell *cell = [viewController tableView:tableView cellForRowAtIndexPath:indexPath];

    expect(@([[cell textLabel] text])).to(equal(@"Bottlenose"));
  });
}

describe(@"didSelectRowAtIndexPath") {
  __block DolphinTableViewController *viewController = nil;

  beforeEach(^{
    // Causes the UIKit framework to trigger the necessary methods to render the view and perform viewWillAppear: and 
    viewController = [[DolphinTableViewController alloc] init];
    [viewController beginAppearanceTransition:YES animated:NO];
    [viewController endAppearanceTransition];
   });

  it(@"deletes the selected row and reloads the tableView's data", ^{
    UITableView *tableView = [viewController tableView];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];

    [viewController tableView:tableView didSelectRowAtIndexPath:indexPath];

    UITableViewCell *cell = [viewController tableView:tableView cellForRowAtIndexPath:indexPath];

    expect(@([[cell textLabel] text])).to(beNil());
  });
}

QuickSpecEnd
```

## How to Install Quick

> This module is beta software, it currently supports Xcode 6 Beta 4.

Quick provides the syntax to define examples and example groups. Nimble
provides the `expect(...).to` assertion syntax. You may use either one,
or both, in your tests.

To use Quick and Nimble to test your iOS or OS X applications, follow these 4 easy steps:

1. [Clone the Quick and Nimble repositories](#1-clone-the-quick-and-nimble-repositories)
2. [Add `Quick.xcodeproj` and `Nimble.xcodeproj` to your test target](#2-add-quickxcodeproj-and-nimblexcodeproj-to-your-test-target)
3. [Link `Quick.framework` and `Nimble.framework`](#3-link-quickframework-and-nimbleframework)
4. Start writing specs!

Example projects with this complete setup is available in the
[`Examples`](https://github.com/modocache/Quick/tree/master/Examples) directory.

### 1. Clone the Quick and Nimble repositories

```sh
git clone git@github.com:Quick/Quick.git Vendor/Quick
git clone git@github.com:Quick/Nimble.git Vendor/Nimble
```

### 2. Add `Quick.xcodeproj` and `Nimble.xcodeproj` to your test target

Right-click on the group containing your application's tests and
select `Add Files To YourApp...`.

![](http://cl.ly/image/3m110l2s0a18/Screen%20Shot%202014-06-08%20at%204.25.59%20AM.png)

Next, select `Quick.xcodeproj`, which you downloaded in step 1.

![](http://cl.ly/image/431F041z3g1P/Screen%20Shot%202014-06-08%20at%204.26.49%20AM.png)

Once you've added the Quick project, you should see it in Xcode's project
navigator, grouped with your tests.

![](http://cl.ly/image/0p0k2F2u2O3I/Screen%20Shot%202014-06-08%20at%204.27.29%20AM%20copy.png)

Follow the same steps for `Nimble.xcodeproj`.

### 3. Link `Quick.framework` and `Nimble.framework`

 Link the `Quick.framework` during your test target's
`Link Binary with Libraries` build phase. You should see two
`Quick.frameworks`; one is for OS X, and the other is for iOS.

![](http://cl.ly/image/2L0G0H1a173C/Screen%20Shot%202014-06-08%20at%204.27.48%20AM.png)

Do the same for the `Nimble.framework`.

### 4. Start writing specs!

If you run into any problems, please file an issue.

## Including Quick in a Git Repository Using Submodules

The best way to include Quick in a Git repository is by using Git
submodules. Git submodules are great because:

1. They track exactly which version of Quick is being used
2. It's easy to update Quick to the latest--or any other--version

### Adding Quick as a Git Submodule

To use Git submodules, follow the same steps as above, except instead of
cloning the Quick and Nimble repositories, add them to your project as
submodules:

```sh
mkdir Vendor # you can keep your submodules in their own directory
git submodule add git@github.com:Quick/Quick.git Vendor/Quick
git submodule add git@github.com:Quick/Nimble.git Vendor/Nimble
git submodule update --init --recursive
```

### Updating the Quick Submodule

If you ever want to update the Quick submodule to latest version, enter
the Quick directory and pull from the master repository:

```sh
cd Vendor/Quick
git pull --rebase origin master
```

Your Git repository will track changes to submodules. You'll want to
commit the fact that you've updated the Quick submodule:

```sh
git commit -m "Updated Quick submodule"
```

### Cloning a Repository that Includes a Quick Submodule

After other people clone your repository, they'll have to pull down the
submodules as well. They can do so by running the `git submodule update`
command:

```sh
git submodule update --init --recursive
```

You can read more about Git submodules
[here](http://git-scm.com/book/en/Git-Tools-Submodules). To see examples
of Git submodules in action, check out any of the repositories linked to
in the ["Who Uses Quick"](#who-uses-quick) section of this guide.

## How to Install Quick File Templates

The Quick repository includes file templates for both Swift and
Objective-C specs.

### Using Alcatraz

Quick templates can be installed via [Alcatraz](https://github.com/supermarin/Alcatraz),
a package manager for Xcode. Just search for the templates from the
Package Manager window.

![](http://f.cl.ly/items/3T3q0G1j0b2t1V0M0T04/Screen%20Shot%202014-06-27%20at%202.01.10%20PM.png)

### Manually via the Rakefile

To manually install the templates, just clone the repository and
run the `templates:install` rake task:

```sh
$ git clone git@github.com:Quick/Quick.git
$ rake templates:install
```

Uninstalling is easy, too:

```sh
$ rake templates:uninstall
```

## Who Uses Quick

Quick is used by many companies, open-source projects, and individuals,
including [GitHub](https://github.com/github) and
[ReactiveCocoa](https://github.com/ReactiveCocoa). See examples below:

- https://github.com/ReactiveCocoa/ReactiveCocoa
- https://github.com/github/Archimedes
- https://github.com/libgit2/objective-git
- https://github.com/jspahrsummers/RXSwift
- https://github.com/artsy/eidolon
- https://github.com/AshFurrow/Moya
- https://github.com/nerdyc/Squeal
- https://github.com/pepibumur/SugarRecord

> Add an issue or [tweet](https://twitter.com/modocache) if you'd like to be added to this list.

## License

Apache 2.0 license. See the `LICENSE` file for details.

