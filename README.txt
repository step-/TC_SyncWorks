Description
-----------

TC_SyncWorks extracts the compared list of files and folders from Total
Commander's Directory Synchronization tool, computes MD5 hashes of all files,
and starts a user-supplied program which can perform additional functions on
the set of files to be synchronized.

TC_SyncWorks is available as a compiled .exe file and as Autohotkey_L 
source code on github.

download program: http://ghisler.ch/board/viewtopic.php?p=241083#241083

download source: http://github.com/step-/TC_SyncWorks

forum links: http://ghisler.ch/board/viewtopic.php?p=241083#241083

Requirements
------------

Total Commander version 7.51a or higher.

TC_SyncWorks was developed and tested on Windows 7 SP1 32-bit and Windows
Server 2003 32-bit with Total Commander 7.56a and 8.0 beta 15. It should
also work with Windows XP 32-bit.

Installation
------------

The .exe file is self-installing and portable (no registry settings). Put it
in an empty folder and start it. It will create some files in the current
folder: README.txt, sample-post-process.cmd, sample-config.ini, regex.dat.
Please read README.txt.  Warning: Note that the .exe file always overwrites
the files listed above.

By default post-processing is disabled, unless PostProcessScriptTemplate is
set in TC_SyncWorks.ini and the template file exists. If you want to see how
post-processing works rename sample-post-process.cmd to post-process.cmd
before pressing the "extract" key, default [^R].

Operation
---------

When TC_SyncWorks starts it displays a brief greeting then minimizes itself
to the icon tray and waits for a user to press one of its hotkeys. Hotkeys
are enabled in Total Commander's Directory Synchronization window only.
Furthermore, the data extraction action stops itself unless the synchronization
file _list_ is activated, that is, a row has the focus.

Typically you will open TC's Directory Synchronization window, press
the Compare button, then press TC_SyncTool's "extract" window to begin
extracting (and saving) the contents of the right and left file lists.
By default, after extraction you will be prompted to perform md5 sums,
then TC_SyncTool will minimize back to the icon tray and wait for your
next "extract" key press.

TC_SyncWorks extracts all and only the items that are marked for copy in
the Directory Synchronization list, and creates up to six files, by default
in the program folder:

- new directories - all new directories that would be created on either side
- left sources - all files in the left list which would be copied to the right
- right sources - all files in the right list which would be copied to the left
- right destination - the full path of the right synchronization directory
- left destination - the full path of the left synchronization directory
- sequence - all necessary copy and directory synchronization steps

All files are plain text files, the first five can be loaded as saved TC
selection lists. The sequence file is formatted as a comma-separated list
of values with the following implicit column headers:

- sequence number, 1,2,...
- operation type, 1(make new dir), 2(copy file to right), 3(copy to left)
- directory relative pathname
- source file relative pathname
- destination file relative pathname

In addition to the above files, TC_SyncWorks can create two additional
files, by default in the left and right directories, formatted as
TC-compatible MD5 checksum files.

Finally you may add a custom processing step by means of a post-processing
script of your liking. Rename the included file sample-post-processing.cmd as
post-process.cmd to automatically start a simple example of this capability.

Hotkeys
~~~~~~~

"extract" key - default [Ctrl+E]
"unlock" key  - default [Ctrl+Esc]
"pause" key   - default [Pause] or tray icon menu
"reload" key  - default [Ctrl+R] or tray icon menu

Configuration
~~~~~~~~~~~~~

TC_SyncWorks optionally reads settings and user's preferences from file
TC_SyncWorks.ini, which need not exist for correct default operation.  If
you want to change some aspect of the program rename file sample-config.ini
to TC_SyncWorks.ini and change preferences there.  This file includes
comments to explain what each setting does.

To change default hotkeys edit TC_SyncWorks.ini and reload the program.

To disable all prompts that occur _before_ the extraction, checksum and
post-processing actions set ShowCancelBefore=1. Note that this will also
disable the initial program greeting.

To disable all statistics prompts that occur _after_ each program action
set ShowOKAfter=0. Note that in this case you may still view statistics in
the logfile by setting Logging=1.

Performance
-----------
Three samples:

Windows 7 on a 1.8 GHz Pentium M laptop:
Extraction time 00.00.08, 2117 items extracted
Internal hashing time 00.01.50, 2116 files hashed, 10 MB total data size
External Hashing time 00:00:19 (post-processed with md5deep)

Server 2003 on a 2.8 GHz Pentium 4:
@ Extraction time 00.00.01, 308 items extracted
Internal hashing time 00.23.32, 264 files hashed, 3 GB total data size
External Hashing time hashing time 00:04:29 (md5deep)

Windows 7 on a 1.8 GHz Pentium M laptop:
@ Extraction time 00.03.23 ~ 64837 total items

Conclusion: While it's handy to have a built-in hashing function, it can't
perform as fast as a specialized hashing tool, like md5deep. So if you need
to hash a lot of files, you should consider integrating an external hashing
tool by means of a post-processing batch file.

Known Bugs and Limitations
--------------------------

This being my first Autohotkey script, it is likely to have some glitches,
hopefully nothing major, but I can't be assured. I make no guarantees of
anything about this program, backup your data before running it - although
the program does not perform destructive user's file operations.

I didn't test TC_SyncWorks niether with 64-bit versions of Windows, nor
with UAC enabled, therefore I don't know if it works in those settings.

Keyboard and Mouse Input Lock
~~~~~~~~ ~~~ ~~~~~ ~~~~~ ~~~~

While it extracts data TC_SyncWorks locks keyboard and mouse input to keep
the user from interfering with the Sync list control.  Such interference
_may_ lead to TC_SyncWorks abruptly halting extraction with a frozen progress
bar (more on this below). This issue doesn't happen every time, and I noticed
it happening more often with the uncompiled script.

With my beginner's knowledge of Autohotkey I wasn't able to implement a good
keyboard and mouse input lock. The current implementation is bad because
it extends to all windows. In other words, While input is locked you can't
immediately use other applications (you still can, after pressing the
"unlock" key). I will be very grateful when someone will show me how to
implement a proper input lock with Autohotkey.

Once data extraction is complete the input lock is released and you can
resume using all windows. The lock does keep two keys fully functional,
[Alt+Tab] and the "unlock" key, as a way to resume input at any time.  When
unlocking avoid clicking the Sync list (any row of it) while extraction is
taking place otherwise TC_SyncWorks's progress bar may freeze.  Unfreeze
TC_SyncWorks by pressing the "pause" key then the "reload" key.  You might
end up with the "wait" mouse pointer stuck in place of the regular mouse
pointer. If so, start extraction again with the "extract" key and cancel at
the first prompt, just before the actual extraction starts.

Acknowledgments
---------------

At Autohotkey forums:
Andreone for BlockKeyboardInputs() and BlockMouseClicks(); SKAN for FileMD5();
sumon for mouse cursor functions, which in turn draw from many others;
PhiLho for CommaAdd()

Contact
-------

Author: sgp at Ghisler's Total Commander forum.
Please post your feedback on the forum thread: http://ghisler.ch/board/viewtopic.php?p=241083#241083

To Do
-----

Block input just to the Sync tool window.

Maybe - Extract just the selected rows.

Changelog
---------
20120206 version 0.10
First public release.
