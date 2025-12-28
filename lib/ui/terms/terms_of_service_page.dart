import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('利用規約'),
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
              'TalkENote 利用規約',
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
              title: '第1条（適用）',
              content: '本規約は、TalkENote（以下「本サービス」）の利用条件を定めるものです。本サービスを利用することにより、利用者は本規約に同意したものとみなされます。',
            ),
            _buildSection(
              title: '第2条（利用登録）',
              content: '本サービスの利用にあたり、利用者は正確な情報を提供するものとします。匿名での利用も可能ですが、一部機能が制限される場合があります。',
            ),
            _buildSection(
              title: '第3条（利用料金）',
              content: '本サービスは基本機能を無料で提供します。一部の機能は有料プランでのみ利用可能です。料金はアプリ内で表示される金額に準じます。',
            ),
            _buildSection(
              title: '第4条（禁止事項）',
              content: '利用者は、以下の行為を行ってはなりません：\n・法令または公序良俗に違反する行為\n・犯罪行為に関連する行為\n・本サービスの内容等の無断転載・複製等\n・本サービスに無断でアクセスする行為\n・他の利用者に関する個人情報等を収集する行為\n・不正な目的を持って本サービスを利用する行為',
            ),
            _buildSection(
              title: '第5条（本サービスの提供の停止等）',
              content: '当社は、以下のいずれかの事由があると判断した場合、利用者に事前に通知することなく本サービスの全部または一部の提供を停止または中断することができるものとします：\n・本サービスにかかるコンピュータシステムの保守点検または更新を行う場合\n・地震、落雷、火災、停電または天災などの不可抗力により、本サービスの提供が困難となった場合\n・その他、当社が本サービスの提供が困難と判断した場合',
            ),
            _buildSection(
              title: '第6条（保証の否認および免責）',
              content: '当社は、本サービスに事実上または法律上の瑕疵（安全性、信頼性、正確性、完全性、有効性、特定の目的への適合性、セキュリティなどに関する欠陥、エラーやバグ、権利侵害などを含みます）がないことを明示的にも黙示的にも保証しておりません。',
            ),
            _buildSection(
              title: '第7条（サービス内容の変更等）',
              content: '当社は、利用者に通知することなく、本サービスの内容を変更しまたは本サービスの提供を中止することができるものとし、これによって利用者に生じた損害について一切の責任を負いません。',
            ),
            _buildSection(
              title: '第8条（利用規約の変更）',
              content: '当社は、必要と判断した場合には、利用者に通知することなくいつでも本規約を変更することができるものとします。なお、本規約の変更後、本サービスの利用を開始した場合には、当該変更後の規約に同意したものとみなします。',
            ),
            _buildSection(
              title: '第9条（個人情報の取扱い）',
              content: '当社は、本サービスの利用によって取得する個人情報については、当社「プライバシーポリシー」に従い適切に取り扱うものとします。',
            ),
            _buildSection(
              title: '第10条（通知または連絡）',
              content: '利用者と当社との間の通知または連絡は、当社の定める方法によって行うものとします。',
            ),
            _buildSection(
              title: '第11条（権利義務の譲渡の禁止）',
              content: '利用者は、当社の書面による事前の承諾なく、利用契約上の地位または本規約に基づく権利もしくは義務を第三者に譲渡し、または担保に供することはできません。',
            ),
            _buildSection(
              title: '第12条（準拠法・裁判管轄）',
              content: '本規約の解釈にあたっては、日本法を準拠法とします。本サービスに関して紛争が生じた場合には、当社の本店所在地を管轄する裁判所を専属的合意管轄とします。',
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

