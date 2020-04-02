import sys
import re

script=sys.argv[1]

f1 = open(script,'r')

lines = f1.readlines()
i = 0
for line in lines:
    i += 1
    if i % 2 != 0:
        print(re.sub('[\u3002|\uff1f|\uff01|\uff0c|\u3001|\uff1b|\uff1a|\u201c|\u201d|\u2018|\u2019|\uff08|\uff09|\u300a|\u300b|\u3008|\u3009|\u3010|\u3011|\u300e|\u300f|\u300c|\u300d|\ufe43|\ufe44|\u3014|\u3015|\u2026|\u2014|\uff5e|\ufe4f|\uffe5]+', " ", line).strip())

f1.close()
