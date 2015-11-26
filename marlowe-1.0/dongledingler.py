import math
import random

with open('include/positive_adjective.wordlist') as f:
    adj = [w.strip() for w in f.readlines()]
with open('include/positive_noun.wordlist') as f:
    noun = [w.strip() for w in f.readlines()]
with open('include/negative_noun.wordlist') as f:
    neg_noun = [w.strip() for w in f.readlines()]

def shake(char):
    char = ord(char)
    currentPow = 1
    numberOfAdjectives = 0
    powers = []
    while currentPow < 128:
            if currentPow & char:
                    powers.append(currentPow)
            currentPow <<= 1

    spl = "Remember the sum of a "

    if char == 0:
        return spl + random.choice(neg_noun) + " and a " + random.choice(noun) + "."

    for i in powers:

            if len(powers) == 1:
                    spl = "Remember a " + ' '.join([random.choice(adj) for x in range(int(math.log(i, 2)))]) + ' ' + random.choice(noun)
            elif(len(powers) - numberOfAdjectives) == 2:
                    spl = spl + ' '.join([random.choice(adj) for x in range(int(math.log(i, 2)))]) + ' ' + random.choice(noun)
                    spl = spl + " and a "
            elif(len(powers) - numberOfAdjectives) == 1:
                    spl = spl + ' '.join([random.choice(adj) for x in range(int(math.log(i, 2)))]) + ' ' + random.choice(noun)
            else :
                    spl = spl + ' '.join([random.choice(adj) for x in range(int(math.log(i, 2)))]) + ' ' + random.choice(noun)
                    spl = spl + " and the sum of a "
            numberOfAdjectives = numberOfAdjectives + 1

    spl = spl + "."
    return spl
