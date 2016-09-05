+++
date = "2014-11-09T23:09:58+08:00"
title = "Sublime Text on Ubuntu - Keeps attempting to remove it"

+++

Few days ago, I reinstalled my notebook with Ubuntu 14.04 desktop version. On Mac OS X， I used TextMate2 as my editor. but it wasn’t supported by Ubuntu, Sublime Text 2 had became the substitute.

However, when I opened the Sublime via terminal, keep getting this message:

    (sublime: 6476): GLib-CRITICAL **; Source ID 1982 was not found when attempting to remove it.

I tried to find the reason， there was nothing useful information in Chinese. Finally， stackoverflow gave me the answer.

Link:

[http://stackoverflow.com/questions/23165426/sublime-text-on-ubuntu-14-04-keeps-attempting-to-remove-it](http://stackoverflow.com/questions/23165426/sublime-text-on-ubuntu-14-04-keeps-attempting-to-remove-it)

* * *

> A quick Google search using keywords from the error message would have quickly brought you to this page in Ubuntu’s bug tracker. Apparently this is a known bug with 14.04, possibly because of a regression with GLib, or a mismatch between GLib and GTK (so says one of the commenters). No fixes are available yet.

> Nothing is trying to remove Sublime, it’s just an error in a programming library. If nothing is crashing on you, or becoming unusable, just ignore it…

* * *

Ignore it… Yah, my terminal has been filled with this message, how can I ignore it!

Fortunately， A solution is here!

* * *

> This ended up being way too annoying to ignore so I have a pretty sloppy solution. Here is a function which runs sublime inside nohup. At first I tried just creating an alias for running sublime with nohup, but it would produce a log file .output and leave it in whatever directory I’m working in. To get around this the function sblmruns sublime in nohup which hides the errors from the terminal, and then it sends the output log to /dev/null

> Now that I have a function sblm I simply use the alias sublime to override the normal sublime function.

> Paste all of this into your .bash_aliases file.

    #Function to deal with the annoying sublime errors
    #Send annoying .output logs to /dev/null
    function sblm
    {
        nohup sublime $1 >/dev/null 2>&1 &
    } 

    #Call my sublime function
    alias sublime="sblm"

And a shorter write

`alias sblm='sublime_text . &>/dev/null'.`

Good Luck, guys
