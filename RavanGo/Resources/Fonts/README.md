# IRANYekanXFaNum fonts

RavanGo supports four optional IRANYekanXFaNum weights:

- `IRANYekanXFaNum-Regular.ttf`
- `IRANYekanXFaNum-Medium.ttf`
- `IRANYekanXFaNum-DemiBold.ttf`
- `IRANYekanXFaNum-Bold.ttf`

These font files are proprietary Fontiran assets. The supplied vendor license identifies the licensed customer and explicitly warns against unauthorized publication or sharing. For that reason, the raw TTF files and the populated `FontLicense.txt` are intentionally excluded from this public repository.

A clean clone builds without these files and falls back to the Apple system font.

## Install a licensed local copy

If you own a valid IRANYekanX license, use the original vendor ZIP and your six-digit Fontiran license code:

~~~sh
FONTIRAN_LICENSE_CODE=123456 sh scripts/install-iranyekanx.sh "/path/to/IRANYekanX(Pro).zip"
~~~

Replace `123456` with your own license code. Do not commit the code.

The installer:

1. Extracts only Regular, Medium, DemiBold, and Bold from the Farsi-numeral family.
2. Places them in this directory.
3. Creates a local `FontLicense.txt` from the vendor file and inserts the supplied license code.
4. Leaves all proprietary files Git-ignored.

During an Xcode build, `scripts/copy-licensed-fonts.sh` copies the locally installed font files and the local `FontLicense.txt` into the application bundle. RavanGo registers the bundled fonts at runtime. If the files are not present, the build still succeeds and the app uses the Apple system font.

The Apache-2.0 source license does not apply to IRANYekanX.
