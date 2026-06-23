import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum LegalDocumentType { faq, terms, privacy }

extension LegalDocumentTypeX on LegalDocumentType {
  String get title => switch (this) {
        LegalDocumentType.faq => 'FAQ',
        LegalDocumentType.terms => 'Conditions d\'utilisation',
        LegalDocumentType.privacy => 'Politique de confidentialité',
      };
}

/// Écran de consultation des documents légaux et d'aide (FAQ, CGU, confidentialité).
class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentScreen({super.key, required this.type});

  static void open(BuildContext context, LegalDocumentType documentType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalDocumentScreen(type: documentType),
      ),
    );
  }

  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1E1E1E);
  static const Color _accent = Color(0xFF00E676);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          type.title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: _sectionsFor(type),
      ),
    );
  }

  List<Widget> _sectionsFor(LegalDocumentType documentType) {
    return switch (documentType) {
      LegalDocumentType.faq => _faqSections(),
      LegalDocumentType.terms => _termsSections(),
      LegalDocumentType.privacy => _privacySections(),
    };
  }

  List<Widget> _faqSections() {
    return [
      _section(
        title: 'Qu\'est-ce que RusaTravel ?',
        body:
            'RusaTravel est une application de réservation de billets de transport '
            'interurbain. Elle permet de consulter les voyages disponibles, '
            'réserver des sièges et payer votre billet en toute sécurité.',
      ),
      _section(
        title: 'Comment créer un compte ?',
        body:
            'Depuis l\'écran de connexion, appuyez sur « Créer un compte ». '
            'Renseignez votre nom, votre numéro de téléphone et votre adresse. '
            'Un mot de passe temporaire vous sera communiqué après l\'inscription.',
      ),
      _section(
        title: 'Comment réserver un billet ?',
        body:
            '1. Consultez les voyages sur l\'accueil ou l\'onglet Voyages.\n'
            '2. Sélectionnez un trajet et choisissez votre siège.\n'
            '3. Renseignez les informations du passager.\n'
            '4. Procédez au paiement (espèces, Mobile Money ou carte selon disponibilité).',
      ),
      _section(
        title: 'Puis-je annuler ou modifier une réservation ?',
        body:
            'Les conditions d\'annulation et de modification dépendent de la '
            'compagnie de transport et du délai avant le départ. Consultez votre '
            'réservation dans l\'onglet Réservations ou contactez le support.',
      ),
      _section(
        title: 'Comment contacter le support ?',
        body:
            'Pour toute question ou réclamation, écrivez à support@rusatravel.cd '
            'en indiquant votre numéro de téléphone et, si possible, votre numéro '
            'de réservation.',
      ),
    ];
  }

  List<Widget> _termsSections() {
    return [
      _section(
        title: '1. Objet',
        body:
            'Les présentes conditions régissent l\'utilisation de l\'application '
            'mobile RusaTravel et les services de réservation de billets de transport '
            'proposés par les sociétés de transport partenaires.',
      ),
      _section(
        title: '2. Compte utilisateur',
        body:
            'L\'utilisateur s\'engage à fournir des informations exactes lors de '
            'l\'inscription et à préserver la confidentialité de ses identifiants. '
            'Toute activité réalisée depuis le compte est réputée effectuée par '
            'l\'utilisateur titulaire.',
      ),
      _section(
        title: '3. Réservations et paiements',
        body:
            'Une réservation est confirmée après validation du paiement ou selon '
            'les règles applicables à la société de transport. Les tarifs affichés '
            'peuvent inclure des frais de transaction pour certains modes de paiement '
            'électronique.',
      ),
      _section(
        title: '4. Responsabilité',
        body:
            'RusaTravel facilite la mise en relation entre voyageurs et transporteurs. '
            'La prestation de transport est exécutée par la société de transport '
            'concernée, qui demeure responsable du voyage.',
      ),
      _section(
        title: '5. Modifications',
        body:
            'Ces conditions peuvent être mises à jour. La version en vigueur est '
            'accessible depuis l\'application. L\'utilisation continue du service '
            'vaut acceptation des conditions modifiées.',
      ),
      _section(
        title: '6. Contact',
        body: 'Pour toute question relative aux conditions : support@rusatravel.cd',
      ),
    ];
  }

  List<Widget> _privacySections() {
    return [
      _section(
        title: '1. Données collectées',
        body:
            'Nous collectons uniquement les données nécessaires au fonctionnement '
            'du service : identité (nom, téléphone), coordonnées, informations de '
            'réservation et, le cas échéant, photo de profil ou données de paiement '
            'traitées par nos prestataires sécurisés.',
      ),
      _section(
        title: '2. Finalités',
        body:
            'Vos données sont utilisées pour créer et gérer votre compte, traiter '
            'vos réservations, émettre vos billets, assurer le support client et '
            'respecter nos obligations légales.',
      ),
      _section(
        title: '3. Données facultatives',
        body:
            'Certaines informations, comme le genre, l\'email ou la photo de profil, '
            'sont facultatives et ne sont pas requises pour utiliser les fonctionnalités '
            'essentielles de réservation.',
      ),
      _section(
        title: '4. Conservation et sécurité',
        body:
            'Les données sont conservées pendant la durée nécessaire à la fourniture '
            'du service et conformément à la réglementation applicable. Des mesures '
            'techniques et organisationnelles sont mises en œuvre pour protéger vos '
            'informations.',
      ),
      _section(
        title: '5. Vos droits',
        body:
            'Vous pouvez accéder à vos données, les rectifier ou demander leur '
            'suppression en contactant support@rusatravel.cd, sous réserve des '
            'obligations légales de conservation.',
      ),
      _section(
        title: '6. Contact',
        body:
            'Délégué / contact confidentialité : support@rusatravel.cd',
      ),
    ];
  }

  Widget _section({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                color: _accent,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
