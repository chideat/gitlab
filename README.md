Script for install gitlab on centos
===================================

gitlab v5
----------
i tried gitlab v5 on centos 5, this is finished yet.
the init script gitlab supplied no worked for centos, i add some rules.
the web site works find now.

how to allow sign up
--------------------
since gitab v4.1, it begin to support user sign up, but i have search out the internet, but no result. finally, i found it out
     
     # modify file config/initializers/1_settings.rb
     $ cd /path/to/gitlab
     $ vim config/initializers/1_settings.rb
     # and modify Settings.gitlab['signup_enabled'] ||= false to true


POINTS
-------
* can't clone push.etc.  see [Issue #3384](https://github.com/gitlabhq/gitlabhq/issues/3384) 
* ssh auth denied, it is beacuse the .ssh permit is wrong, 

	#change ssh file mode
	chmod 700 /home/git/.ssh

