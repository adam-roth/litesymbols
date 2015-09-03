### litesymbols
###### An alternative symbolicator for iOS crash reports
=========

### About

litesymbols is a relatively simple bash script that can be used to symbolicate the contents of an iOS crash report ('.crash' file).  

It can be used as an alternative to Apple's official 'symbolicatecrash' script, for instance in cases where the latter script is nonfunctional.


### Getting Started

Just copy the 'litesymbols.sh' script to somewhere reasonable on your Mac (I recommend '/usr/bin' if you plan on using it often; though you can place the script anywhere you like) and ensure that it is readable and executable at least by your current user (run 'chmod +x /path/to/litesymbols.sh' if needed).

That should be it.  However do note that the script assumes that your Xcode debugging symbols are installed in the standard place ('~/Library/Developer/Xcode/iOS DeviceSupport/\<OS_VERSION\>/Symbols').  If you have changed this, then you'll need to modify the script appropriately before using it.


### Usage

The litesymbols script expects two command-line arguments that tell it 1) where your iOS app resides in the filesystem, and 2) what '.crash' file it should use as input.

Specifically, you can run the script (after downloading 'litesymbols.sh' and installing to '/usr/bin'), like:

'_litesymbols.sh [APPLICATION_PATH] [CRASH_FILE]_'

...for example:

'_litesymbols.sh ~/Builds/MyAwesomeApp/v1.30/MyAwesomeApp.app/MyAwesomeApp ./MyAwesomeApp-2015-07-16-11-48.crash_'

...assuming that you want to symbolicate the crash log located at './MyAwesomeApp-2015-07-16-11-48.crash' against the build that you've archived to '~/Builds/MyAwesomeApp/v1.30/MyAwesomeApp.app/MyAwesomeApp', and have your output logged to the console.

You may prefer to write your output to file, which you can do like:

'_litesymbols.sh ~/Builds/MyAwesomeApp/v1.30/MyAwesomeApp.app/MyAwesomeApp ./MyAwesomeApp-2015-07-16-11-48.crash > ./MyAwesomeApp-2015-07-16-11-48.crash.symbolicated_'

...and you may get some occasional complaints from 'atos', in the form of "[fatal] child process status could not be determined".  These are annoying, but harmless.  You can suppress them like:

'_litesymbols.sh ~/Builds/MyAwesomeApp/v1.30/MyAwesomeApp.app/MyAwesomeApp ./MyAwesomeApp-2015-07-16-11-48.crash 2> /dev/null_'

Note that the two above examples can be combined, as in:

'_litesymbols.sh ~/Builds/MyAwesomeApp/v1.30/MyAwesomeApp.app/MyAwesomeApp ./MyAwesomeApp-2015-07-16-11-48.crash > ./MyAwesomeApp-2015-07-16-11-48.crash.symbolicated 2> /dev/null_'



### FAQ

**_Why create litesymbols?_**<br />
Because Apple's 'symbolicatecrash' script has not been working for me for some time now, and I got tired of manually poking around with 'atos' every time I wanted to investigate a crash report.

Having a working symbolicator would make my life easier, even if all it did was automate calls to 'atos' and collate the results.  So I made one.

**_Why should I use litesymbols?_**<br />
Use litesymbols if you're having trouble getting 'symbolicatecrash' to work for you, and want to try an alternative approach to symbolicating your iOS crash reports.

**_Why shouldn't I use litesymbols?_**<br />
Don't use litesymbols if 'symbolicatecrash' is working normally for you.  The litesymbols script won't do anything that 'symbolicatecrash' doesn't do, and will likely be somewhat slower than the official script in terms of runtime (speed is not the goal of litesymbols; the focus is on reliability and maintainability of the script's code).

Also don't use litesymbols if you don't need to symbolicate iOS crash reports in the first place.

**_Are there any limitations to what litesymbols can do?_**<br />
The litesymbols script makes some assumptions about where it can find the debugging symbols it needs in order to process the crash report.  If you've installed Xcode (and more to the point, Xcode's iOS system libraries) in a non-standard location you'll probably need to modify the script to point to the correct location.

The script cannot symbolicate anything that it cannot locate debugging symbols for, or anything that isn't an iOS crash report.  It has only been tested against the 'armv7' and 'arm64' architectures, and is unlikely to work with crash reports from any other device architecture. 

**_What is 'litesymbols-dir.sh'?_**<br />
That's a helper-script that will symbolicate all of the '.crash' files in a particular folder.  To use it, you just need to have 'litesymbols.sh' installed somewhere on your system PATH (for instance, '/usr/bin' will work).  Then you can use 'litesymbols-dir.sh' like:

-_litesymbols-dir.sh ~/Builds/MyAwesomeApp/v1.30/MyAwesomeApp.app/MyAwesomeApp_-

...which will symbolicate any '.crash' files in the current directory.  Useful if you've downloaded a pile of crashes, and want to process them all at once.

**_Wouldn't your script be more efficient if it did 'X'?_**<br />
Probably.  Bash is not a first language to me.  Or even a second or a third.  It's more like an option of last resort.  

Much of the litesymbols script was cobbled together using suggestions from various references, those primarily being posts on stackoverflow.com.  I don't claim that it does anything optimally, elegantly, or even efficiently.  If you'd like to refactor it so that it does, by all means please do so and submit a pull request. 


### License

I'm of the opinion that when someone takes something valuable, like source code, and knowingly and willingly puts it somewhere where literally anyone in the world can view it and grab a copy for themselves, as I have done, they are giving their implicit consent for those people to do so and to use the code however they see fit.  I think the concept of "copyleft" is, quite frankly, borderline insane.  

Information wants to be free without reservation, and good things happen when we allow it to be.  But not everyone agrees with that philosophy, and larger organizations like seeing an "official" license, so I digress.

For the sake of simplicity, you may consider all litesymbols code to be licensed under the terms of the MIT license.  Or if you prefer, the Apache license.  Or CC BY.  Or any other permissive open-source license (the operative word there being "permissive").  Take your pick.  Basically use this code if you like, otherwise don't.  Though if you use litesymbols to build something cool that changes the world, please remember to give credit where credit is due.  And also please tell me about it, so that I can see too.  



