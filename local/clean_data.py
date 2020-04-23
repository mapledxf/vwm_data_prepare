import sys
import re
from array import array
import pangu

# python rm_punctuation.py script.txt all " "

script = sys.argv[1]

arr = array('u', ['…', '（', '）', '【', '】', '『', '』', '、', '；', '：', '‘', '’', '“', '”', '－', '　', '《', '》',
                  "'", "(", ")", "{", "}", '"', 'π', '\\', '/'])

replace = " "
if len(sys.argv) == 3:
    if sys.argv[2] == 'all':
        arr.append('，')
        arr.append('。')
        arr.append('？')
        arr.append('！')
        arr.append(',')
        arr.append('.')
        arr.append('?')
        arr.append('!')
    else:
        replace = sys.argv[2]
elif len(sys.argv) == 4:
    arr.append('，')
    arr.append('。')
    arr.append('？')
    arr.append('！')
    arr.append(',')
    arr.append('.')
    arr.append('?')
    arr.append('!')

    if sys.argv[2] == 'all':
        replace = sys.argv[3]
    else:
        replace = sys.argv[2]

sub = "[" + "|".join(arr) + "]+"
f1 = open(script, 'r')

lines = f1.readlines()
for line in lines:
    if line.strip() == '':
        continue
    data = re.split('[\t ]', line)
    trans = ' '.join(data[1:])
    new = re.sub(sub, replace, trans) \
        .replace('[', replace) \
        .replace(']', replace) \
        .replace('FIL', replace) \
        .replace('SPK', replace) \
        .replace('  ', ' ') 
    print(data[0] + '\t' + pangu.spacing_text(new).upper().strip())
f1.close()
