# Find My Friends helper (macOS 15+)

This target injects into `com.apple.findmy` and reads the People data exposed by
`FindMyLocateObjCWrapper.framework`. It is the helper half of the newer-macOS
Find My Friends integration in BlueBubbles Server.

The implementation intentionally exports an allowlisted payload. It does not
send private-framework `description` or `debugDescription` strings over the
socket.

## Response contract

`refresh-findmy-friends` returns:

- `locations`: one deterministic record per identifiable friend, seeded from
  the current cache before requested refreshes begin
- `partial`: whether either the friend-list request or an individual location
  refresh exceeded its deadline, or a friend record could not be identified
- `friendListTimedOut`: whether the helper had to use the cached friend list
- `timedOutHandles`: stable identifiers whose live refresh did not finish
- `skippedFriends`: count of records that had no stable identifier

A friend with no current location remains in `locations` with null coordinates
and address fields. This keeps slow or offline friends from disappearing.

A nil or malformed friend-list callback is not a complete empty list. It leaves
the request pending until the existing deadline returns a partial cached-list
fallback. A valid empty array remains a complete empty result.

The helper requests location refreshes, then reads the session's location cache
when each completion callback arrives. Completion does not guarantee that macOS
obtained a newer fix: valid cached or shallow locations retain their original
timestamp and status. The helper does not replace timestamps with the request
time or promote cached records to `live`. A new location fix is demonstrated by
new native location data, separately from a completed RPC or callback.

## Build

The committed server artifact must contain both `x86_64` and `arm64` slices:

```sh
./scripts/build-universal.sh
```

The output is `dist/BlueBubblesFindMyHelper.dylib`. The script builds each
architecture separately, combines them with `lipo`, verifies both slices, and
checks that the install name is `@rpath/BlueBubblesFindMyHelper.dylib`.

Building does not copy into `/Applications` or terminate Find My. Installation
and injection are owned by BlueBubbles Server.

The helper ignores unrelated Private API actions that are broadcast for legacy
helpers. Unknown Find My actions still return an explicit transaction error.

## Tests

The tests require Xcode but do not load private frameworks or inject into Find
My:

```sh
./Tests/run-tests.sh
```

They cover stable-handle selection, missing and live locations, allowlisted
fields, deterministic ordering, friend-list and per-handle timeouts, duplicate
and late callbacks, and response delivery across a server reconnect.

A separate executable compiles the production helper entry point and refresh
coordinators with fake transport and private-framework providers. It checks
wrong-host startup, command routing, transaction errors, refresh deadlines, and
cleanup of active refreshes. GitHub Actions runs these tests on Intel and Apple
silicon macOS runners without signing, injection, or an Apple account.
The Intel job also builds the unsigned universal dylib through the Xcode
workspace, verifies both architectures and the install name, and records its
checksum. It does not install or publish the product.
