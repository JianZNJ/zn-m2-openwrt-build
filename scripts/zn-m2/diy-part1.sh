#!/bin/bash
echo "==> append third-party feeds"
grep -q 'openclash' feeds.conf.default || echo 'src-git openclash https://github.com/vernesong/OpenClash.git;master' >> feeds.conf.default
echo "==> feeds:"
cat feeds.conf.default