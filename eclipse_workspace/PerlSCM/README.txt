Sep 5, 2009, Sean Blanton

The main file of interest here is Harvest7.pm which is Perl package SCM::Tool::VersionControl::Harvest7

Yes, too abstracted - we'll refactor it down at some point. It was part of a way too grandiose plan.

It started when I had to do a change control system for Lawson ERP with Harvest. Lawson had some strange check-in and build rules and I wanted to keep those separate from the harvest- and openmake- specific code.

Then, I put it on Source Forge using Subversion and Subversion stinks so I had to write a SCM::Tool::VersionControl::Subversion to do basic tasks. That was last updated about 3 years ago and almost certainly will not work.

SCM::Tool::Build::Openmake is out of date. I've since done some more sophisticated work and that code will go under the Openmake:: package.

Significant Dependencies:

Log::Log4perl
Config::Properties

Log::Log4perl is an incredible package to mimic log4j, which unfortunately has a bit of a learning curve. This is SCM work,so everything needs to be logged and this saves you from writing your own logging routines and provides amazingly advanced functionality. You need a log4perl/j configuration file, an example of which is in:  PerlSCM/etc/scm-log4perl.conf. 

One note with Harvest/SCM is that by default, log4perl prints everything to standard error, so it comes up red on the Harvest 7 workbench - there is a way to change that. Let me know if you are interested.

Note: To get modules with ppm for ActivePerl, you may need to set the http_proxy variable to your server.

To Do's:

* Updates may be needed for R12/SCM
* User proper getters-setters. Don't access object hash values directly. Assigned to me, SAB.
* Moving the source code repository from sourceforge to github.
* Perl modules are pretty hard to get except for Windows/Linux - may need to abstract out the logging if you can't get Log::Log4perl for your system. 
* Better documentation, like putting most of this in the perldoc.

Examples:

Under PerlSCM/eg/harvest, there are example command-line tools that I wrote mostly for myself to do all sorts of harvest functions. Many are similar to Harvest: mcp runs hcp, mpp runs hpp, mcbl - hcbl, etc. I had more sophisticated programs to completely automate creating a new branch project from a template. I'll see if I can dig that up. These are good, single purpose programs.

These command-line programs all depend on the user setting up two context files. One contains an individual user's project and package name, and a 'global' one stays in the directory with the code and has viewpath information. There is also a user's password file (mpasswd) and a users log4perl conf file and also in some cases a user's perltidy file.

I recommend looking at mpasswd, then mcp, mco and mpp. mci runs a bunch of perl validation tests (unit tests, perldoc validation, perltidy) if you are checking in perl code and fails the check in if those tests fail and it is ugly.

At one point, I would be switching development between two different files in two different Harvest branch projects, with different packages, of course. I got fancy and had programs like 'msp' to switch my Harvest context between two project/package pairs.