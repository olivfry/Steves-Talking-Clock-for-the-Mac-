This is the Mac version of Steve's Talking Clock by Stephen Clower, modified by Oliver Fry. Note: You MUST be using macOS 12.0 Monterey or newer.

Steve's Talking Clock - for the Mac!

Version 1.0.1

Inspired by Stephen Clower

17 January 2025



This documentation and accompanying software are copyright 2025 by Oliver Fry.





Note: The beginning of each major section in this manual is preceded by three plus signs (+++). If you are using a screen reader, these anchors will help you quickly locate the section you want to read.



+++ Table Of Contents



1 - Introduction

2 - Installation

3 - General Overview

4 - The Alarm 

5 - Audio Configuration

6 - Hotkey Configuration

7 - Quiet Mode

8 - Adding Pre-made Clock Voices

9 - Removing Voices

10 - Uninstalling the Clock

11 - Making Your Own Voices

12 - Mailing Lists

13 - Credits and Final Notes



+++ 1 - Introduction

     Welcome to Steve's Talking Clock, a small, customisable talking clock for Mac! This program can live in the Mac system tray and be configured to automatically announce the time on the quarter-hour, half-hour, three-quarters and at the top of the hour. In addition, an  alarm can be set to announce itself for any time of the day. Configurable hotkeys, support for multiple clock types, configurable audio output, and a quiet mode make this program unique. Unlike other talking clocks for Windows, this program is designed so that you can use any clock voice you wish, and a different voice can be  configured for each announcement.



+++ 2 - Installation

     To install Steve's Talking Clock onto your computer, go back to the main GtHub page, click 'Code' then 'Download ZIP'. Then move the app to your Applications folder. At the time of this writing there are more than seventy voice packs available for download. To obtain  any of these, you can go to the clock's home page at  http://clock.steve-audio.net. If you only want to use pre-made voice  files, then this will be all you need to do before running the clock.  If you want to make your own voices, see "concatenation.txt" which explains the required steps necessary to produce a voice.



+++ 3 - General Overview

     When you first run the clock, it will open a small window with the voice settings on the left side of the screen, and buttons controlling the program's operation on the right. Use the tab key to navigate to the various settings and change them. The following is a brief description of the items you will find in the main window. Detailed instructions follow:



* Main Voice List - Controls which voice is spoken by the Speak Time button. Default is none.

* Quarter Hour Voice List - If not set to none, will announce the 15-minute mark with the selected voice. Default is none.

* Half Hour Voice List - If not set to none, will announce the half hour  with the voice selected. Default is none.

* Three Quarter Hour Voice List - If not set to none, will announce 45 past  the hour with the voice selected. Default is none.

* On the Hour Voice List - If not set to none, will speak the time at  the top of the hour with the voice selected. Default is none.

* Alarm Voice List - When not set to none, will announce the time for the alarm with the selected voice. Default is none.

* Alarm Time edit field - enter the time for the alarm here. Default is  nothing.

* 24 Hour Mode Checkbox - When checked with Alt+H from anywhere within the clock's window, announces the time in 24-hour format.  Default is unchecked, 12-hour format.

* Say Time button. Pressing Alt+T from any point in the window will speak the time using the voice selected in the main voice list.

* Initialise Button - Pressing ALT+I from within the clock window will cause all of the voice lists to be reset. use this button if you install or remove a voice while the clock is running.

* Save Settings Button - Pressing ALT+S from within the clock window will force the program to save the current settings. Note: this happens automatically when the program exits.

* Audio button - Pressing spacebar on this button or ALT+U will open the audio configuration dialog.

* Hotkeys Button - Pressing ALT+K from within the clock window will open the hotkey configuration dialog box.

* Quiet Mode Button - Pressing ALT+Q from within the clock window will open the quiet mode configuration dialog box.

* Minimise to Tray Button - Press Alt+M from within the clock window to minimize the clock to the System Tray. To bring it  back, left-click the Steve's Clock icon in the system tray.

     Once you have configured the clock to your liking, you may want to minimize it to the system tray. When settings have been saved, the clock will load minimized the next time you run it to save space on your task bar.



+++ 4 - The Alarm 

     The alarm clock is useful if you need to be reminded of certain events during the day. To set the alarm, tab to the alarm edit box and enter the time at which you want the alarm to sound. Note: You *must* use the following format:

For 12-hour time: hh:mm dd

where hh is a two-digit number representing the hour, mm is a two digit number representing the minute, and dd is either am or pm. Note the colon between hh and mm, along with the space before am or pm. An example of a valid alarm time in the 12-hour format is

03:12 am

or

12:05 pm

Note: You can use either upper or lowercase when entering A or PM into the alarm edit field.



For 24-hour time: hh:mm

where hh is a two-digit number representing the hour, and mm is a two-digit number representing the minute. Note the colon between hh and mm. An example of a valid 24-hour entry would be:

00:25

or

22:47



  Note: when switching between 12 and 24 hour time, the value in the alarm edit field will automatically be adjusted. Additionally, you can press any hotkey which will produce a sound such as the "Say Time" button to interrupt the alarm.



+++ 5 - Audio Configuration

Steve's Talking Clock can be configured to use any wave-compatible sound card on your computer. You may desire to send the clock's output to a pair of headphones rather than the main speakers to minimise distraction. To select the output device, click the AirPlay button located on the right-hand edge of the Steve's Talking Clock window. A list of devices will appear, then select the device you wish to use. To exit the dialog without saving any changes, click anywhere outside the box. Note: When first run, the clock will be set to use the first audio device (typically the default Windows audio output).



+++ 6 - Hotkey Configuration

     A hotkey is a user-assignable key combination which can be pressed anywhere within macOS to cause something to happen. With Steve's Talking Clock, you can assign a hotkey to speak the time, toggle 24-hour mode, move the main voice up or down in the list, show or hide the window, and exit the clock. To configure the hotkeys, click the "Hotkeys..." button in the clock window. The hotkey configuration dialog will open. Click on the field next to the function you want to change the hotkeys for and press the combination of keys you want to use. Finally, configure any other keys you want to use. You can assign any or all of the actions to various key combinations. When you are finished and wish to save the changes, press the OK button. Otherwise, press Cancel to close the dialog.

+++ 7 - Quiet Mode

     Quiet mode has been designed for users who want to leave Steve's Talking Clock running all the time but wish it to be silent during a specified interval. To configure quiet mode, click the "Quiet Mode..." button in the clock window and the quiet mode configuration dialog will open. For this mode to work properly, you must enter times into both the first box (stop speaking after) and the second box (start speaking from) and check the "Enable Quiet Mode" checkbox. Use the alarm format described above for examples of valid times. Depending on the values you enter, quiet mode will act differently. For instance, if the time in the first box is less than that in the second box, Steve's clock will treat those times as an interval in which not to speak. Otherwise, the clock will stop speaking at the time specified in the first box and will not sound for the rest of the day. Similarly, the clock will not make any announcements until the value in the second box has been reached. For example, a value of 12:00 am in the first box and 08:00 am in the second box will cause the clock to stop speaking at midnight and resume at 08:00 in the morning. Likewise, if you enter 11:00 pm into the first box and 06:00 am into the second box, the clock will stop speaking at 11:00 at night and resume at 06:00 the next morning. Note that quiet mode will not disable the "Say Time" button or the alarm.



+++ 8 - Adding Pre-made Clock Voices

     As time goes on, there will inevitably be other voices which will be made to run with this clock. Installing them is very  straightforward. If you are installing a new voice, copy the wave files into a subdirectory underneath the "Steve's Talking Clock" folder in Application Support with a unique name. Next, click the "Initialise" button in the clock window to reset the clock lists. If the clock can be identified, it will appear in the voice lists.



+++ 9 - Removing Voices

     To remove a voice from Steve's Clock, go to Application Support, Steve's Talking Clock and delete the folder. Next, click the "Initialise" button in the clock window to update the voice lists. Note: while it is not mandatory to close the clock when you delete a voice, it is recommended that you do so.



+++ 10 - Uninstalling the Clock

     If you wish to remove Steve's Clock from your computer, simply drag Steve's Clock into the Trash. You will need to remove the voices you installed manually, but you can keep these if you like if you decide to install Steve's Clock again.



+++ 11 - Making Your Own Voices

     There are many possible ways to make a voice for this program. The process can be somewhat involved, but essentially it consists of recording a set of wave files which are then dynamically combined to speak the time. You must be comfortable with a sound editor to make a voice successfully. A file in this directory called "concatenation.txt" has details on all of the supported methods. See it for more details.



+++ 12 - Mailing Lists

     Andre Louis is kindly hosting a discussion list for Steve's Talking Clock. If you wish to subscribe, head to http://clock.steve-audio.net and click the mailing list subscription link. This is a relatively quiet list, so feel free to join the group if you would like to talk to other clock users.

  I also host a general announcements list for Steve-Audio.Net. This list is very quiet, and you will only receive announcements regarding new content available on the web site. To subscribe, point your web browser to http://www.steve-audio.net.

+++ 13 - Gap Delay

You can choose how long the gap is between the clock saying each segment. The fastest setting is immediately and the slowest setting is 0.2 seconds.

+++ 14 - Credits and Final Notes

     First of all, I would like to thank both Andre Louis and Patrick Perdue for their ideas, assistance, and time while I wrote this program. Andre has put together the clock voice installers and created the settings removal utility which is now included with this program. In addition, Patrick has taken a lot of time to create many of the voices available for the clock, and the effort really shows. My hats off to both of you, and thanks for your help! Thanks also to everyone who have contributed voices to the program. Submissions such as these are what make this program as good as it is,  so keep them coming! I would like to thank Stephen Clower for inspiring me to make this clock!

     In addition, I would like to thank Jarrod Jicha, Joseli Walter, James Bowden, shawn klein, Andre Louis, Patrick Perdue, Maria Smith, Samuel Proulx, and tiffany black of the Steve's Clock beta team who provided suggestions and comments to make sure this version is as bug free as possible. Special thanks also go to Daniel Zingaro of DanZ Games and the members of the BCX team who gave me some tips while Steve was porting the old clock source code away from Visual Basic to C. Finally, I would like to thank Karen for putting up with Steve while hw worked on this project. Thanks for hanging in there.

     Thank you, and happy ticking!
