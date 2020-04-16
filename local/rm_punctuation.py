import sys
import re

script=sys.argv[1]

f1 = open(script,'r')
#，\uff0c
#。\u3002
#？\uff1f
#！\uff01

lines = f1.readlines()
for line in lines:
    print(re.sub('[\u300c|\u3001||\uff1b|\uff1a|\u201c|\u201d|\u2018|\u2019|\uff08|\uff09|\u300a|\u300b|\u3008|\u3009|\u3010|\u3011|\u300e|\u300f|\u300d|\ufe43|\ufe44|\u3014|\u3015|\u2026|\u2014|\uff5e|\ufe4f|\uffe5]+', " ", line).strip())

f1.close()
