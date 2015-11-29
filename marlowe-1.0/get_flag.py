import dongledingler
import random
import string
import socket
import sys
import pexpect
import pexpect.fdpexpect

POSSIBILITIES = string.ascii_uppercase + string.digits + string.ascii_lowercase

def get_flag(ip, port, flag_id, token):

    if ip:
        conn = socket.create_connection((ip,port))
        c = pexpect.fdpexpect.fdspawn(conn.fileno())
    else:
        c = pexpect.spawn("./spl")
        c.logfile = sys.stdout


    c.sendline("Episode V, A Newer Hope.\n")

    c.sendline("Han Solo, a loveable space-rogue.\n")
    c.sendline("Princess Leia, a fearless space-princess.\n")

    c.sendline("          Act I: Escaping the Death-Star.\n")
    c.sendline("          Scene I: Han Solo wants money.\n")
    c.sendline("[Enter Han Solo and Princess Leia]\n")

    c.sendline("Han Solo:")

    for speare in token[::-1] + '\0' + flag_id[::-1]:
        d = dongledingler.shake(speare)
        c.sendline(' '+d)
    c.sendline("\nPrincess Leia:")
    c.sendline(" Give me your banner!")

    c.expect("FLG[a-zA-Z0-9]{13}")
    flag = c.after

    c.sendline("\n[Exeunt]")
    c.close()

    if ip: conn.close()

    return { 'FLAG' : flag }

if __name__ == "__main__":
    print get_flag(None, None, "Toy4OPiwV2xg0WCnuIbm", "X9r1CDjB2EyWxQiTMSY3")
