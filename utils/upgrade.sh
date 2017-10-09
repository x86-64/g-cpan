#!/bin/bash

layman -a x86
emerge dev-perl/g-cpan
layman -d x86
