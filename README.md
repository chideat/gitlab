Script for install gitlab v4 on centos
========================================

just as officat instraction
https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md

but here i use apache replaced nginx, because nginx failed to work.

Notes
=====
* 1. in unicorn.rb, must add
  listen "127.0.0.1:3000"
 and the original listen never works

* 2. inital database script fails few times.
    doto  gitlab:app:setup   or gitlab:setup
    according to the offical instraction, differnet version has different method!!!
* 3. the version must be right to gitlab. an for gitlab v5, gitolite will never be used.
