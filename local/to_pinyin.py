#!/usr/bin/env python3

# Copyright 2020 Nagoya University (Wen-Chin Huang)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

import argparse
import codecs
import nltk
import os
import re
import nltk
from text_format import spacing_text

from english_cleaner import custom_english_cleaners
from pypinyin import pinyin, Style
from pypinyin.style._utils import get_initials, get_finals
from pypinyin.contrib.neutral_tone import NeutralToneWith5Mixin
from pypinyin.converter import DefaultConverter
from pypinyin.core import Pinyin

try:
    # For phoneme conversion, use https://github.com/Kyubyong/g2p.
    from g2p_en import G2p

    f_g2p = G2p()
    f_g2p("")
except ImportError:
    raise ImportError(
        "g2p_en is not installed. please run `. ./path.sh && pip install g2p_en`."
    )
except LookupError:
    # NOTE: we need to download dict in initial running
    nltk.download("punkt")

def g2p(text):
    """Convert grapheme to phoneme."""
    tokens = filter(lambda s: s != " ", f_g2p(text))
    return " ".join(tokens)

class MyConverter(NeutralToneWith5Mixin, DefaultConverter):
    pass

my_pinyin = Pinyin(MyConverter())
pinyin = my_pinyin.pinyin

def get_g2p(content):
    clean_content = custom_english_cleaners(content.rstrip())
    text = clean_content.lower()
    clean_content = g2p(text)
    return clean_content

def get_pinyin(content):
    # Some special rules to match CSMSC pinyin
    text = pinyin(content, style=Style.TONE3)
    text = [c[0] for c in text]
    clean_content = []
    for c in text:
        c_init = get_initials(c, strict=True)
        c_final = get_finals(c, strict=True).replace("ü","v")
        if c_init == 'w':
            c_init = ''
            if c_final != 'u':
                c_final = 'u' + c_final

        if c_init == 'y':
            c_init = ''
            if c_final.startswith("u"):
                c_final = c_final.replace('u', 'v')
            elif not c_final.startswith('i'):
                c_final = 'i' + c_final

        if re.match("iu\d", c_final):
            c_final = c_final.replace("iu", "iou")
        if re.match("ui\d", c_final):
            c_final = c_final.replace("ui", "uei")
        if re.match("ue\d", c_final):
            c_final = c_final.replace("ue", "ve")

        if re.match("i\d", c_final):
            if c_init in ['z', 'c', 's']:
                c_final = c_final.replace("i", "ii")
            elif c_init in ['zh', 'ch', 'sh', 'r']:
                c_final = c_final.replace("i", "iii")

        if re.match("(u|un|uan)\d", c_final):
            if c_init in ['j', 'q', 'x', 'y']:
                c_final = c_final.replace("u", "v")
            else:
                if re.match("un\d", c_final):
                    c_final = c_final.replace("un", "uen")
        if c_init:
            clean_content.append(c_init)
        clean_content.append(c_final)
    return ' '.join(clean_content)

def is_chinese(strs):
    strs.decode('utf-8')
    return u'\u4e00' <= strs[0] <= u'\u9fff'

def get_phn(content):
    text = spacing_text(content, True).strip().split(' ')
    clean_content = []
    for word in text:
        if not word.strip():
            continue
        if ord(word[0]) <= 255:
            clean_content.append(get_g2p(word))
        else:
            clean_content.append(get_pinyin(word))
    return ' '.join(clean_content)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('transcription_path', type=str, help='path for the transcription text file')
    args = parser.parse_args()

    if os.path.isfile(args.transcription_path):
        with codecs.open(args.transcription_path, 'r', 'utf-8') as fid:
            for line in fid.readlines():
                segments = re.split('[\t ]', line)
                id = segments[0]  # ex. TMF1_M10001
                content = " ".join(segments[1:]).replace("\r\n", "\n").replace("\n", "")

                clean_content = get_phn(content)
                print("%s\t%s" % (id, clean_content))
    else:
        text = args.transcription_path
        clean_content = get_phn(text)
        print(clean_content)
