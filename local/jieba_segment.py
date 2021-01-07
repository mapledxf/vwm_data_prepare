#!/usr/bin/env python
# -*- coding: UTF-8 -*-
# encoding=utf-8
# Copyright 2018 AIShell-Foundation(Authors:Jiayu DU, Xingyu NA, Bengu WU, Hao ZHENG)
#           2018 Beijing Shell Shell Tech. Co. Ltd. (Author: Hui BU)
# Apache 2.0

from __future__ import print_function
import codecs
import sys
import os
import re
import jieba
from text_format import spacing_text

trans_file=sys.argv[1]

path=os.path.split(os.path.realpath(__file__))[0]

for word in open(os.path.join(path,'jieba_words.txt')):
    jieba.suggest_freq(word.strip("\n"), tune=True)

with codecs.open(trans_file, 'r', 'utf-8') as fid:
    for line in fid.readlines():
        segments = re.split('[\t ]', line)
        id = segments[0]  # ex. TMF1_M10001
        content = " ".join(segments[1:]).replace("\r\n", "\n").replace("\n", "")
        content = spacing_text(content, False).strip()
        words = jieba.cut(content, HMM=False)
        new_line = id + '\t' + " ".join(" ".join(words).split()).upper()
        print(new_line)
