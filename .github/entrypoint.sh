#!/bin/bash
ls -la /gh-actions
zypper -n install make perl-HTTP-Server-Simple perl-Path-Class perl-File-Type build curl gzip bzip2
make -C /gh-actions test
