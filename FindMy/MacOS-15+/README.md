# Find My helper (macOS 15+)

This target injects into `com.apple.findmy` and supports Friends and Devices on
newer macOS releases. Friends use `FindMyLocateObjCWrapper.framework`. Devices
come from the app-owned FMIP object graph:

```text
FMDevicesListDataSource -> mediator -> devicesProvider -> fmipManager -> dataManager -> devices
```

The implementation intentionally exports an allowlisted payload. It does not
send private-framework `description` or `debugDescription` strings over the
socket.

## Friends response

`refresh-findmy-friends` returns:

- `locations`: one deterministic record per identifiable friend, seeded from
  the current cache before live refreshes begin
- `partial`: whether either the friend-list request or an individual location
  refresh exceeded its deadline
- `friendListTimedOut`: whether the helper had to use the cached friend list
- `timedOutHandles`: stable identifiers whose live refresh did not finish
- `skippedFriends`: count of records that had no stable identifier

A friend with no current location remains in `locations` with null coordinates
and address fields. This keeps slow or offline friends from disappearing.

## Devices response

`refresh-findmy-devices` returns:

- `devices`: deterministic records with stable identity, model, OS, battery,
  connection state, address, and location fields when available
- `partial`: whether an FMIP record was skipped because it had no stable
  identifier
- `skippedDevices`: number of skipped records

The helper captures only `FMDevicesListDataSource` and uses Swift reflection to
read its existing FMIP manager. It does not create another manager or depend on
visible list cells. Offline devices remain in the response without a fabricated
location.

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
fields, deterministic ordering, friend-list and per-handle timeouts, device
data-source readiness, populated/offline/empty/partial device snapshots,
duplicate and late callbacks, and response delivery across a server reconnect.
