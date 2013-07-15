Script for install gitlab on centos
===================================

gitlab v5
----------
i tried gitlab v5 on centos 5, this is finished yet.
the init script gitlab supplied no worked for centos, i add some rules.
the web site works find now.

how to allow sign up
--------------------
modify config/gitlab.yml file, and uncomment signup_enabled: true


POINTS
-------
* can't clone push.etc.  see [Issue #3384](https://github.com/gitlabhq/gitlabhq/issues/3384) 
* ssh auth denied, it is beacuse the .ssh permit is wrong, 

	#change ssh file mode
	chmod 700 /home/git/.ssh

