import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.homeBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SOBRE O APP',
          style: TextStyle(
            color: AppTheme.homePrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              'Como o PulseBio funciona',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w300,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'O PulseBio combina ciência e tecnologia para restaurar seu equilíbrio natural através de estímulos sensoriais sincronizados.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                height: 1.7,
              ),
            ),

            const SizedBox(height: 40),

            // Seção Nervo Vago
            _InfoSection(
              icon: Icons.hub_rounded,
              color: AppTheme.destressPrimary,
              title: 'O Nervo Vago',
              content:
                  'O nervo vago é o principal nervo do sistema nervoso parassimpático — responsável pelo estado de "descanso e digestão". Ele conecta o cérebro ao coração, pulmões e intestino.\n\nQuando estimulado corretamente, ele reduz o cortisol (hormônio do estresse), diminui a frequência cardíaca e induz um estado profundo de calma.',
            ),

            const SizedBox(height: 24),

            // Seção Módulo Desestresse
            _InfoSection(
              icon: Icons.waves_rounded,
              color: AppTheme.destressPrimary,
              title: 'Módulo Desestresse',
              content:
                  'Combina 4 estímulos simultâneos para ativar o nervo vago:\n\n• Visão: animações lentas com cores frias (azul e verde) que reduzem a resposta de alerta do cérebro\n\n• Audição: sons binaurais em frequências alfa (8-12 Hz) que induzem relaxamento profundo\n\n• Respiração: técnica 4-7-8 (inspira 4s, segura 7s, expira 8s) comprovada para reduzir cortisol\n\n• Tato: vibração haptica sincronizada com a respiração para amplificar o efeito vagal',
            ),

            const SizedBox(height: 24),

            // Seção Módulo Foco
            _InfoSection(
              icon: Icons.psychology_rounded,
              color: AppTheme.focusPrimary,
              title: 'Módulo Foco e Memória',
              content:
                  'Ativa o córtex pré-frontal e o hipocampo — regiões responsáveis pela concentração e consolidação de memórias:\n\n• Visão: cores quentes (âmbar e laranja) que estimulam o estado de alerta focado\n\n• Audição: frequências binaurais beta (13-30 Hz) para foco, e gama (30-50 Hz) para recuperação de memória\n\n• Respiração: Box Breathing (4-4-4-4) usado por atletas e militares para máxima concentração\n\n• Timer Pomodoro: sessões de 25 minutos com pausas guiadas para otimizar a retenção',
            ),

            const SizedBox(height: 24),

            // Seção Respiração
            _InfoSection(
              icon: Icons.air_rounded,
              color: AppTheme.homePrimary,
              title: 'Por que a respiração é central',
              content:
                  'A respiração é o único sistema autônomo do corpo que você controla conscientemente. Ao mudar o ritmo respiratório, você muda diretamente o estado do sistema nervoso.\n\nInspiração ativa → sistema simpático (alerta)\nExpiração longa → sistema parassimpático (calma)\n\nTodas as técnicas do PulseBio são baseadas nessa mecânica fundamental.',
            ),

            const SizedBox(height: 24),

            // Seção Sons Binaurais
            _InfoSection(
              icon: Icons.hearing_rounded,
              color: AppTheme.homePrimary,
              title: 'Sons Binaurais',
              content:
                  'Sons binaurais funcionam quando frequências ligeiramente diferentes são tocadas em cada ouvido. O cérebro percebe a diferença entre elas e sincroniza suas ondas cerebrais com essa frequência.\n\nUse sempre fones de ouvido para o efeito completo.\n\nFrequências usadas no app:\n• Delta (1-4 Hz): sono profundo\n• Teta (4-8 Hz): meditação e criatividade\n• Alfa (8-12 Hz): relaxamento e calma\n• Beta (13-30 Hz): foco e concentração\n• Gama (30-50 Hz): memória e aprendizado',
            ),

            const SizedBox(height: 40),

            // Rodapé
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.homePrimary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.homePrimary.withOpacity(0.15), width: 1),
              ),
              child: const Text(
                '⚠️ O PulseBio é uma ferramenta de bem-estar e não substitui acompanhamento médico ou psicológico profissional.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String content;

  const _InfoSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.75,
            ),
          ),
        ],
      ),
    );
  }
}