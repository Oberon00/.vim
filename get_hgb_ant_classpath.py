#!/usr/bin/env python3
# encoding: utf-8

from os.path import abspath, exists, join, dirname, isdir

def find_dir_with(fname, dname):
    if exists(join(dname, fname)):
        return dname
    pdir = dirname(dname)
    if pdir == dname:
        return
    return find_dir_with(fname, pdir)

if __name__ == '__main__':
    root = find_dir_with('build.xml', abspath('.'))
    bindir = join(root, 'bin')
    if isdir(bindir):
        print(bindir)
