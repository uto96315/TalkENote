import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TalkENote プライバシーポリシー',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '最終更新日: 2025年1月',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: '1. はじめに',
              content: 'TalkENote（以下「本サービス」）は、ユーザーのプライバシーを尊重し、個人情報の保護に努めます。本プライバシーポリシーは、本サービスがどのような個人情報を収集し、どのように利用・保護するかについて説明します。',
            ),
            _buildSection(
              title: '2. 収集する情報',
              content: '本サービスは、以下の情報を収集する場合があります：\n\n【認証情報】\n・メールアドレス（アカウント登録時）\n・匿名認証ID（匿名利用時）\n\n【録音データ】\n・音声録音ファイル\n・録音日時、録音時間\n\n【文字起こしデータ】\n・音声から変換されたテキスト\n・翻訳されたテキスト\n・抽出された単語・フレーズ\n\n【利用情報】\n・アプリの利用状況\n・エラー情報\n・デバイス情報（OS、バージョンなど）',
            ),
            _buildSection(
              title: '3. 情報の利用目的',
              content: '収集した情報は、以下の目的で利用します：\n・本サービスの提供・運営\n・音声の文字起こし・翻訳機能の提供\n・ユーザーサポート\n・サービスの改善・新機能の開発\n・不正利用の防止\n・利用規約違反の調査',
            ),
            _buildSection(
              title: '4. 情報の保存・管理',
              content: '収集した情報は、Firebase（Google Cloud Platform）のサーバーに保存されます。データは暗号化され、適切なセキュリティ対策の下で管理されます。',
            ),
            _buildSection(
              title: '5. 第三者への提供',
              content: '以下の場合を除き、個人情報を第三者に提供することはありません：\n・ユーザーの同意がある場合\n・法令に基づく場合\n・本サービスの提供に必要な外部サービス（文字起こしAPI、翻訳APIなど）への提供（必要な範囲内）',
            ),
            _buildSection(
              title: '6. 広告について',
              content: '本サービスでは、Google AdMobを使用して広告を表示しています。AdMobは、広告の配信のためにCookieやデバイスIDなどの情報を収集する場合があります。詳細は、Googleのプライバシーポリシーをご確認ください。',
            ),
            _buildSection(
              title: '7. データの削除',
              content: 'ユーザーは、アカウント削除により、保存されている個人情報や録音データを削除することができます。アカウント削除は、アプリ内の設定から行うことができます。',
            ),
            _buildSection(
              title: '8. 未成年者の利用',
              content: '本サービスは、13歳以上の方を対象としています。13歳未満の方が利用する場合は、保護者の同意が必要です。',
            ),
            _buildSection(
              title: '9. プライバシーポリシーの変更',
              content: '当社は、必要に応じて本プライバシーポリシーを変更することがあります。変更後は、本ページに最新の内容を掲載します。',
            ),
            _buildSection(
              title: '10. お問い合わせ',
              content: '個人情報の取り扱いに関するお問い合わせは、アプリ内のお問い合わせフォームからご連絡ください。',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

