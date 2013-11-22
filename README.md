This is to fix an annoying issue when using iOS Enterprise Developer Program accounts. If you have both an Enterprise and a standard Company account for the same company, the private keys will likely be issued under the same name. However, the `codesign` utility does not support signing when when the keys have identical names, and will simply show as an error in Xcode.

To fix this, you can separate the keys and certificates for each account into separate .keychain files. However, maintaining those files and ensuring that only the correct file is loaded into Keychain can cause issues. To make that easier, this simple menu bar app adds a quick toggle to switch between which of the keychains is active.

To use it, you will need to modify `KSAppDelegate.m` to return the paths to your actual keychains. An actual configuraiton window would be nice, but would require more effort than this project deserves.

Further reading:

 - http://stackoverflow.com/questions/7174893/conflict-between-inhouse-appstore-distribution-profiles
 - http://stackoverflow.com/questions/5158942/codesign-collisions-between-developer-and-enterprise-distribution
 - http://www.nefkens-ict.nl/ios-tips-tricks/code-sign-hell-when-having-multiple-distribution-certificates-with-the-same-name/
 - http://dockthirteen.wordpress.com/2011/08/29/codesign-ios-applications-with-a-certificate-from-a-non-default-keychain-in-xcode/

Also, the Keychain API isn't the best.

