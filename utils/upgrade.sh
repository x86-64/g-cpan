#!/bin/bash

layman -a x86
emerge --nodeps g-cpan
layman -d x86
