import dongledingler
import random
import string
import socket
import sys
import pexpect
import pexpect.fdpexpect

POSSIBILITIES = string.ascii_uppercase + string.digits + string.ascii_lowercase

def set_flag(ip, port, flag):
    banner_id = random.sample(POSSIBILITIES, 20)
    password = random.sample(POSSIBILITIES, 20)
    colors = list(flag)

    if ip:
        conn = socket.create_connection((ip,port))
        c = pexpect.fdpexpect.fdspawn(conn.fileno())
    else:
        c = pexpect.spawn("./spl")
        c.logfile = sys.stdout

    c.sendline("I am a title and I am awesome.\n")

    c.sendline("Romeo, a young man whose trowsers are nowhere to be found.")
    c.sendline("Juliet, well, she'll just cut you.\n")

    c.sendline("          Act I: Total Confusion.\n")
    c.sendline("          Scene I: Romeo has Tourette Syndrome.\n")
    c.sendline("[Enter Juliet and Romeo]\n")

    c.sendline("Romeo:")

    for speare in colors[::-1] + ['\0'] + password[::-1] + ['\0'] + banner_id[::-1]:
        d = dongledingler.shake(speare)
        print d
        c.sendline(' '+d)

    c.sendline("\nJuliet:")
    c.sendline(" Take my flag!")

    c.sendline("\n[Exeunt]")
    c.close()

    if ip: conn.close()

    return {
            'FLAG_ID': ''.join(banner_id),
            'TOKEN': ''.join(password),
            }

if __name__ == "__main__":
    print set_flag(None, None, "FLG_just_testing")
