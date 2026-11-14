# Messages regression checks

Run these commands from the Helper repository root with Python 3 and the macOS
Command Line Tools or Xcode installed:

```sh
python3 -m unittest discover -s 'Messages/MacOS-11+/Tests' -p 'test_*.py'
python3 Messages/MacOS-11+/Tests/run_safety_tests.py
python3 Messages/MacOS-11+/Tests/check_server_protocol.py --server-root /path/to/bluebubbles-server
```

The native test runner copies the actual edited lookup/notification methods and
the actual network parser/catch into a temporary Foundation test binary. It uses
synthetic message/history objects, a captured sender and a synthetic dispatcher.
The delayed callback tests complete after the initiating call returns. The network
tests exercise transaction propagation and JSON-safe error replies, including
missing transaction/name/reason values. Nothing is injected into Messages, and
no account, signing identity or socket connection is required.

The actual dispatcher prelude is also used for Server-shaped JSON-null account
and legacy Friends requests. They must reach the synthetic operation boundary
as empty dictionaries. The fixture does not execute those private operations.

The protocol checker reads a Server source checkout without installing or running
it. It compares declared actions with the Helper's dispatch method, ignores
comments, and fails for empty input or an unrecognized dynamic action expression.
It includes `refresh-findmy-friends`, which still routes through Messages on
macOS 11–13. `refresh-findmy-devices` belongs to the separate Find My helper.
The Python tests include negative cases so commented-out branches or missing
legacy Friends coverage cannot silently pass.

With Xcode installed, build the full target without signing or installation:

```sh
messages_build_dir="$(mktemp -d "${TMPDIR:-/tmp}/messages-build.XXXXXX")"
xcodebuild -workspace 'Messages/MacOS-11+/BlueBubblesHelper.xcworkspace' \
  -scheme 'BlueBubblesHelper DyLib' -configuration Release -arch "$(uname -m)" \
  -derivedDataPath "$messages_build_dir" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

The dylib is written to `Build/Products/Release/BlueBubblesHelper.dylib` under
that directory. The app's Copy Files phase runs only during deployment
postprocessing; an ordinary `build` does not copy into `/Applications/BlueBubbles.app`.
The build does not inject the dylib or launch Messages.

`.github/workflows/messages-regressions.yml` runs the regression checks and this
unsigned target build on native Intel and Apple Silicon macOS runners. It also
checks the built architecture and `@rpath` dylib identity. Its Server checkout is
pinned to official development
commit `e2a5bf6e624dd03d4a98334824bc30880c69407a`; update that immutable source pin
when intentionally reviewing a changed Server protocol. Both checkouts disable
persisted credentials, and the workflow needs only read access to repository contents.

The fixtures establish selected exception/notification behavior and source-level
action name coverage. The target build checks compilation and linkage. Neither
executes Apple's private frameworks or establishes that every private selector
works on every supported macOS version. Installation and live compatibility
evidence are separate.
