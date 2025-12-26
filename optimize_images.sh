#!/bin/bash

# PNG画像を最適化するスクリプト

echo "画像を最適化中..."

# app_icon.pngを最適化（バックアップを取る）
if [ -f "assets/icons/app_icon.png" ]; then
  cp assets/icons/app_icon.png assets/icons/app_icon.png.backup
  echo "app_icon.pngのバックアップを作成しました"
  
  # sipsを使ってPNGを最適化（品質を少し下げる）
  sips -s format png assets/icons/app_icon.png --out assets/icons/app_icon_temp.png
  mv assets/icons/app_icon_temp.png assets/icons/app_icon.png
  echo "app_icon.pngを最適化しました"
  
  ls -lh assets/icons/app_icon.png*
fi

echo "完了！"
