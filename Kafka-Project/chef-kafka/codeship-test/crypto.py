#!/usr/bin/env python

# https://stackoverflow.com/a/42770165

import base64
from Crypto.Cipher import AES
import argparse
import sys

class AESCipher:
    def __init__(self, key_b64):
        self.key = base64.b64decode(key_b64)

    def decrypt(self, value, block_segments=True):
        key = self.key
        # The base64 library fails if value is Unicode. Luckily, base64 is ASCII-safe.
        value = str(value)
        # We add back the padding ("=") here so that the decode won't fail.
        value = base64.b64decode(value + '=' * (4 - len(value) % 4), '-_')
        iv, value = value[:AES.block_size], value[AES.block_size:]
        if block_segments:
            # Python uses 8-bit segments by default for legacy reasons. In order to support
            # languages that encrypt using 128-bit segments, without having to use data with
            # a length divisible by 16, we need to pad and truncate the values.
            remainder = len(value) % 16
            padded_value = value + '\0' * (16 - remainder) if remainder else value
            cipher = AES.new(key, AES.MODE_CFB, iv, segment_size=128)
            # Return the decrypted string with the padding removed.
            return cipher.decrypt(padded_value)[:len(value)]
        return AES.new(key, AES.MODE_CFB, iv).decrypt(value)

    def encrypt(self, value, block_segments=True):
        key = self.key
        iv = Random.new().read(AES.block_size)
        if block_segments:
            # See comment in decrypt for information.
            remainder = len(value) % 16
            padded_value = value + '\0' * (16 - remainder) if remainder else value
            cipher = AES.new(key, AES.MODE_CFB, iv, segment_size=128)
            value = cipher.encrypt(padded_value)[:len(value)]
        else:
            value = AES.new(key, AES.MODE_CFB, iv).encrypt(value)
        # The returned value has its padding stripped to avoid query string issues.
        return base64.b64encode(iv + value, '-_').rstrip('=')


parser = argparse.ArgumentParser(description='Encrypts or decrypts codeship files')

parser.add_argument('action', metavar='action',
                    help='The action, encrypt or decrypt')
parser.add_argument('source', metavar='source',
                    help='source file')
parser.add_argument('dest', metavar='dest',
                    help='destination file')
parser.add_argument('--key-path', metavar='aeskey',
                    default='codeship.aes', help='the key file')

args = parser.parse_args()

if args.action == 'encrypt':
  raise Exception('encrypt not implemented')
elif args.action == 'decrypt':
  aes_key = file(args.key_path).read()
  c = AESCipher(aes_key)
  data = file(args.source).read()
  decrypted = c.decrypt(data,block_segments=True)
  file(args.dest,'w').write(decrypted)
else:
  parser.print_help()
  sys.exit(-1)

