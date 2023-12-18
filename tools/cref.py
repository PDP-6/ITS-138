#!/usr/bin/env python3

import locale
import re
import sys

line = 1
page = 1
table = {}

def define(text):
    m = re.search(r'^[^;]*?DEFINE ([A-Z0-9$%.\'"]+)', text)
    if m:
        return m.group(1)[0:6]
    return None

def equals(text):
    m = re.search(r'^[^;]*?([A-Z0-9$%.\'"]+)=', text)
    if m:
        return m.group(1)[0:6]
    return None

def label(text):
    m = re.search(r'^[^;]*?([A-Z0-9$%.\'"!]+):', text)
    if m:
        return m.group(1).replace('!','')[0:6]
    return None

def definition(text):
    x = define(text)
    if x:
        return (x, 'M')
    x = equals(text)
    if x:
        return (x, ' ')
    x = label(text)
    if x:
        return (x, ' ')
    return None

def analyze(file):
    global page, line
    f = open(file, "r")
    for text in f.readlines():
        if re.search(r'^\f', text):
            line = 1
            page += 1
        symbol = definition(text)
        if symbol and not symbol[0] in table:
            table.update({symbol[0]: (page, line, symbol[1], False)})
        line += 1

def symbol(text):
    return re.match(r'^[0-9]+.?$', text) is None

def reference(text):
    if define(text):
        return None
    t = re.search(r'^([^;]*);', text)
    if t:
        text = t.group(1)
    m = re.findall(r'[A-Z0-9$%.\'"!]+[:=)]?', text)
    x = None
    for s in m:
        if re.search(r'[:=)]$', s) is not None:
            continue
        s = s.replace('!','')[0:6]
        if s in table:
            x = table[s]
            table[s] = (x[0], x[1], x[2], True)
    return x

def listing(file):
    page = 1
    line = 1
    f = open(file, "r")
    for text in f.readlines():
        if re.search(r'^\f', text):
            print("\f", end="")
            text = text[1:]
            line = 1
            page += 1
        ref = reference(text)
        if ref is None:
            print("%03d\t\t%s" % (line, text), end="")
        else:
            print("%03d\t%03d %03d %s" % (line, ref[0], ref[1], text), end="")
        line += 1

def symtab():
    locale.setlocale(locale.LC_COLLATE, "C")
    for x in sorted(table.items()):
        sym = x[0]
        typ = x[1][2]
        pag = x[1][0]
        lin = x[1][1]
        ref = "*"
        if x[1][3]:
            ref = " "
        print("%-06s %c %03d%c%03d" % (sym, typ, pag, ref, lin))

if __name__ == "__main__":
    analyze(sys.argv[1])
    listing(sys.argv[1])
    symtab()
