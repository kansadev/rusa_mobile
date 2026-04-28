class CreateReservationRequest {
  final int idUtilisateur;
  final int idClient;
  final int idVoyage;
  final String statutReservation;
  final bool statut;
  final String dateReservation;
  final int idSociete;

  CreateReservationRequest({
    required this.idUtilisateur,
    required this.idClient,
    required this.idVoyage,
    required this.statutReservation,
    required this.statut,
    required this.dateReservation,
    required this.idSociete,
  });

  Map<String, dynamic> toJson() {
    return {
      'idUtilisateur': idUtilisateur,
      'idClient': idClient,
      'idVoyage': idVoyage,
      'statutReservation': statutReservation,
      'statut': statut,
      'dateReservation': dateReservation,
      'idSociete': idSociete,
    };
  }
}
