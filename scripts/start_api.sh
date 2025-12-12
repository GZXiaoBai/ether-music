#!/bin/bash

# Ether Music Player - API 启动脚本
# 使用多音源解锁功能

export ENABLE_GENERAL_UNBLOCK=true    # 启用全局解灰
export ENABLE_FLAC=true                # 启用无损音质
export SELECT_MAX_BR=true              # 选择最高码率
export UNBLOCK_SOURCE=pyncmd,qq,bodian,migu,kugou,kuwo  # 音源优先级
export FOLLOW_SOURCE_ORDER=true        # 按顺序匹配音源

echo "🎵 启动 Ether Music API 服务..."
echo "📍 多音源解锁已启用: $UNBLOCK_SOURCE"
echo "🎧 无损音质: $ENABLE_FLAC"
echo ""

node /tmp/netease-api/app.js
