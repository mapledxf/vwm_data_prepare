#!/usr/bin/env python
# coding: utf-8
import argparse
import os
import re
import sys

from copy import deepcopy
from array import array

__version__ = '4.0.6.1'
__all__ = ['spacing_text', 'spacing_file', 'spacing', 'cli']

#tts_remove = array('u', ['…', '（', '）', '【', '】', '『', '』', '、', '：', '‘', '’', '“', '”', '－', '　', '《', '》',"'", "(", ")", "{", "}", '"', 'π', '\\', '/', '[', ']', '～', '~', '_', ':'])
tts_remove = array('u', ['…', '（', '）', '【', '】', '『', '』', '、', '：', '‘', '’', '“', '”', '－', '　', '《', '》',"'", "(", ")", "{", "}", '"', 'π', '\\', '/', '～', '~', '_', ':'])
tts_keep = array('u', [',','.','?','!'])

asr_remove = deepcopy(tts_remove)
asr_remvoe = asr_remove.extend(tts_keep)

TTS_CLEAN = "[" + "|".join(tts_remove) + "]+"
ASR_CLEAN = "[" + "|".join(asr_remove) + "]+"
PUNCTUATION_REPLACE = ''.maketrans("！。？，；;：:", "!.?,,,,,")

CJK = r'\u2e80-\u2eff\u2f00-\u2fdf\u3040-\u309f\u30a0-\u30fa\u30fc-\u30ff\u3100-\u312f\u3200-\u32ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff'

ANY_CJK = re.compile(r'[{CJK}]'.format(CJK=CJK))

CJK_QUOTE = re.compile('([{CJK}])([`"\u05f4])'.format(CJK=CJK))  # no need to escape `
QUOTE_CJK = re.compile('([`"\u05f4])([{CJK}])'.format(CJK=CJK))  # no need to escape `
FIX_QUOTE_ANY_QUOTE = re.compile(r'([`"\u05f4]+)(\s*)(.+?)(\s*)([`"\u05f4]+)')

CJK_SINGLE_QUOTE_BUT_POSSESSIVE = re.compile("([{CJK}])('[^s])".format(CJK=CJK))
SINGLE_QUOTE_CJK = re.compile("(')([{CJK}])".format(CJK=CJK))
FIX_POSSESSIVE_SINGLE_QUOTE = re.compile("([{CJK}A-Za-z0-9])( )('s)".format(CJK=CJK))

HASH_ANS_CJK_HASH = re.compile('([{CJK}])(#)([{CJK}]+)(#)([{CJK}])'.format(CJK=CJK))
HASH_CJK = re.compile('(([^ ])#)([{CJK}])'.format(CJK=CJK))

AN_PUNCTUAION = re.compile(r'([ ]*)([,.!\?])')
PUNCTUAION_AN = re.compile(r'([,.!\?])([A-Za-z0-9])')

CJK_ANS = re.compile('([{CJK}])([A-Za-z\u0370-\u03ff0-9@\\$%\\^&\\*\\-\\+\\\\=\\|/\u00a1-\u00ff\u2150-\u218f\u2700—\u27bf])'.format(CJK=CJK))
ANS_CJK = re.compile('([A-Za-z\u0370-\u03ff0-9~\\!\\$%\\^&\\*\\-\\+\\\\=\\|;:,\\./\\?\u00a1-\u00ff\u2150-\u218f\u2700—\u27bf])([{CJK}])'.format(CJK=CJK))

S_A = re.compile(r'(%)([A-Za-z])')

MIDDLE_DOT = re.compile(r'([ ]*)([\u00b7\u2022\u2027])([ ]*)')

def clean(content, tts=False, replace=""):
    if tts:
        sub = TTS_CLEAN
    else:
        sub = ASR_CLEAN
    content = content.translate(PUNCTUATION_REPLACE)
    return re.sub(sub, replace, content) \
        .replace('[', replace) \
        .replace(']', replace) \
        .replace('FIL', replace) \
        .replace('SPK', replace) \
        .replace('  ', ' ')
def spacing(text):
    """
    Perform paranoid text spacing on text.
    """
    if len(text) <= 1 or not ANY_CJK.search(text):
        return text

    new_text = text

    new_text = CJK_QUOTE.sub(r'\1 \2', new_text)
    new_text = QUOTE_CJK.sub(r'\1 \2', new_text)
    new_text = FIX_QUOTE_ANY_QUOTE.sub(r'\1\3\5', new_text)

    new_text = CJK_SINGLE_QUOTE_BUT_POSSESSIVE.sub(r'\1 \2', new_text)
    new_text = SINGLE_QUOTE_CJK.sub(r'\1 \2', new_text)
    new_text = FIX_POSSESSIVE_SINGLE_QUOTE.sub(r"\1's", new_text)

    new_text = HASH_ANS_CJK_HASH.sub(r'\1 \2\3\4 \5', new_text)
    new_text = HASH_CJK.sub(r'\1 \3', new_text)

    new_text = AN_PUNCTUAION.sub(r'\2', new_text)
    new_text = PUNCTUAION_AN.sub(r'\1 \2', new_text)

    new_text = CJK_ANS.sub(r'\1 \2', new_text)
    new_text = ANS_CJK.sub(r'\1 \2', new_text)

    new_text = S_A.sub(r'\1 \2', new_text)

    new_text = MIDDLE_DOT.sub('・', new_text)

    return new_text.strip()


def spacing_text(text, tts=False):
    """
    Perform paranoid text spacing on text. An alias of `spacing()`.
    """
    text = clean(text.upper(),tts)
    return spacing(text)


def spacing_file(path, tts=False):
    """
    Perform paranoid text spacing from file.
    """
    # TODO: read line by line
    with open(os.path.abspath(path)) as f:
        return spacing_text(f.read(), tts)


def cli(args=None):
    if not args:
        args = sys.argv[1:]
    
    parser = argparse.ArgumentParser(
        prog='text format',
    )

    parser.add_argument('-v', '--version', action='version', version=__version__)
    parser.add_argument('-t', '--tts', action='store_true', dest='is_tts', required=False, default=False, help='is tts format')
    parser.add_argument('-f', '--file', action='store_true', dest='is_file', required=False, help='specify the input value is a file path')
    parser.add_argument('text_or_path', action='store', type=str, help='the text or file path to apply spacing')

    if not sys.stdin.isatty():
        print(spacing_text(sys.stdin.read()))  # noqa: T003
    else:
        args = parser.parse_args(args)
        if args.is_file:
            print(spacing_file(args.text_or_path, args.is_tts))  # noqa: T003
        else:
            print(spacing_text(args.text_or_path, args.is_tts))  # noqa: T003


if __name__ == '__main__':
    cli()
