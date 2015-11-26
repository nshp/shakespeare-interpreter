import dongledingler
import random
import string
import socket
import sys
import pexpect
import pexpect.fdpexpect

with open('include/titles.wordlist') as f:
    titles = [t.strip() for t in f.readlines()]

with open('include/scenes.wordlist') as f:
    scenes = [s.strip() for s in f.readlines()]

with open('include/character.wordlist') as f:
    names = [n.strip() for n in f.readlines()]

with open('include/descriptions.wordlist') as f:
    descriptions = [n.strip() for n in f.readlines()]

with open('/usr/share/dict/words') as f:
    words = [w.strip() for w in f.xreadlines() if w[:-1].isalpha()]

def commafy(lst):
    if len(lst) == 1: return lst[0]
    return ", ".join(lst[:-1]) + (", and " if len(lst)>2 else " and ") + lst[-1]

def benign(ip, port):
    if ip:
        conn = socket.create_connection((ip,port))
        c = pexpect.fdpexpect.fdspawn(conn.fileno())
    else:
        c = pexpect.spawn("./spl")
        c.logfile = sys.stdout

    characters = random.sample(names, 2)

    c.sendline(random.choice(titles) + ".\n")

    for char in characters:
        c.sendline("%s, a %s." % (char, random.choice(descriptions)))

    c.sendline("")


    c.sendline("          Act I: %s.\n" % ' '.join(random.sample(words, random.randint(1,3))).title())
    c.sendline("          Scene I: %s.\n" % random.choice(scenes))


    c.sendline("[Enter %s]\n" % commafy(characters))

    # WHAT SHALL WE SAY???
    c.sendline(characters[0] + ":")
    c.sendline(" You are as smelly as a fat flirt-gill.")
    c.sendline(" Open your heart.")

    c.sendline("\n[Exeunt]")
    c.close()

    if ip: conn.close()

if __name__ == "__main__":
    benign(None, None)
