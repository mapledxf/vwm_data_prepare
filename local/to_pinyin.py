#!/usr/bin/env python3

# Copyright 2020 Nagoya University (Wen-Chin Huang)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

import argparse
import codecs
import nltk
import os
import re

from pypinyin import pinyin, Style
from pypinyin.style._utils import get_initials, get_finals
from pypinyin.contrib.neutral_tone import NeutralToneWith5Mixin
from pypinyin.converter import DefaultConverter
from pypinyin.core import Pinyin

class MyConverter(NeutralToneWith5Mixin, DefaultConverter):
    pass

my_pinyin = Pinyin(MyConverter())
pinyin = my_pinyin.pinyin

def get_pinyin(content):
    # Some special rules to match CSMSC pinyin
    text = pinyin(content, style=Style.TONE3)
    text = [c[0] for c in text]
    clean_content = []
    for c in text:
        c_init = get_initials(c, strict=True)
        c_final = get_finals(c, strict=True)
        for c in [c_init, c_final]:
            if len(c) == 0:
                continue
            c = c.replace("ü", "v")
            c = c.replace("ui", "uei")
            c = c.replace("un", "uen")
            c = c.replace("iu", "iou")

            # Special rule: "e5n" -> "en5"
            if "5" in c:
                c = c.replace("5", "") + "5"
            clean_content.append(c)
    return ' '.join(clean_content)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('transcription_path', type=str, help='path for the transcription text file')
    args = parser.parse_args()

    if os.path.isfile(args.transcription_path):
        with codecs.open(args.transcription_path, 'r', 'utf-8') as fid:
            for line in fid.readlines():
                segments = re.split('[\t ]', line)
                lang_char = args.transcription_path.split('/')[-1][0]
                id = segments[0] # ex. TMF1_M10001
                content = "".join(segments[1:]).replace("\r\n","\n").replace("\n", "")

                clean_content = get_pinyin(content)
                print("%s %s" % (id, clean_content))
    else:
        text = args.transcription_path
        clean_content = get_pinyin(text.replace(" ",""))
        print(clean_content)
